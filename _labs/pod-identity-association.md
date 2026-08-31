# Lab: Associate the Role and Rerun the Workload

## Goal

Bind the role to a service account and watch the same workload prove a different identity. You write the association, a service account with nothing on it, and change one line of the probe. By the end an unchanged container reads the same parameter as a different IAM role, reached through a different mechanism, and the only Kubernetes object involved carries no annotation at all.

## Starting point

The applied project with both halves of Pod Identity in place and unconnected: the agent DaemonSet running on every node, the `reader-podid` role holding the read permission through a service-principal trust policy, and no associations on the cluster. The probe Pod currently runs in `team-web` under the annotated `reader` service account and reads the parameter as the federated role.

You add one Terraform resource, one manifest, and one word of an existing manifest.

## Configuration to target

- **One Pod Identity association**, naming the cluster, the namespace `team-web`, the service account `reader-podid`, and the new role's ARN. Reference the role resource rather than pasting its ARN.
- **A ServiceAccount named `reader-podid` in `team-web`**, carrying no annotations, no labels, and nothing else. The name and the namespace have to match the association character for character.
- **One line changed in the probe.** `serviceAccountName` points at the new service account. Nothing else in that file changes.
- **Written by the platform administrator, with `kubectl create` rather than `apply`**, so no client-side bookkeeping annotation lands on the object.
- **Nothing about the federated path is removed.**

## Tasks

1. **Write the association.** Four values in one resource. Before applying, say out loud where in the cluster this object is going to appear, then check whether you were right after it applies.
2. **Apply, and confirm the association exists in EKS.** List the cluster's associations and read back what the new one holds.
3. **Write the service account and create it.** Then look at the object the cluster stored and confirm there is nothing on it beyond a name and a namespace.
4. **Repoint the probe and rerun it.** Delete the existing pod, change the one line, and apply. Give the association a moment to propagate before reading the logs.
5. **Read both logs.** The first container reports an identity, and it is neither the node nor the federated role. The second returns the parameter value, through a permission attached to a different role than the one that returned it last time.

## Done when

- `terraform apply` adds one resource and `terraform validate` reports the configuration is valid.
- The cluster reports one association, naming `team-web`, `reader-podid`, and the `-reader-podid` role.
- `kubectl get sa reader-podid -n team-web -o yaml` shows no `annotations` key at all.
- The probe reaches **Completed**, reporting an ARN containing the `-reader-podid` role name and returning the parameter value.
- The `reader` service account and its annotation are still there, untouched.

## Note

A service account carrying nothing is a real tradeoff rather than a clear win: reading one no longer tells you what a pod can do in AWS, and finding out means querying the EKS API.

Nothing validates the two names against each other. EKS accepts a namespace and a service account that do not exist, and Kubernetes has no idea the association exists. Misspell either side and everything applies cleanly, the pod starts, and the AWS call fails on an identity nobody intended.

Give the association a few seconds before running the probe. A pod that starts too early falls through to the node, so what you see is the node role and a refusal on the read, which looks exactly like a wrong association rather than an early one.

Both mechanisms now run on one cluster against different service accounts, and neither knows about the other, which is what makes moving a real workload between them gradual rather than a cutover. The association is free.
