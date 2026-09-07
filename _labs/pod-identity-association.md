# Lab: Associate the Role and Rerun the Workload

## Goal

Bind the Pod Identity role to a service account and run the same workload against it. You write the association, a service account with nothing on it, and change one line of the probe. By the end an unchanged container reads the same parameter as a different IAM role, and the service account that got it there carries no annotation.

## Starting point

You continue from the applied project, with both halves of Pod Identity in place and not yet connected: the agent DaemonSet running on every node, the `reader-podid` role holding the read permission through its service-principal trust policy, and no associations on the cluster. The probe Pod currently runs in `team-web` under the annotated `reader` service account and reads the parameter as the federated role.

You add one Terraform resource, one manifest, and one changed line in a manifest you already have.

## Configuration to target

- **The association:** one Pod Identity association naming the cluster, the namespace `team-web`, the service account `reader-podid`, and the new role's ARN. Reference the role resource rather than pasting its ARN.
- **New file `k8s/reader-podid-serviceaccount.yaml`:** a ServiceAccount named `reader-podid` in `team-web`, carrying no annotations and no labels. The name and the namespace have to match the association character for character.
- **The probe:** `serviceAccountName` points at the new service account. Nothing else in that file changes.
- **Applied as:** the platform administrator, with `kubectl create` rather than `apply`, so no client-side bookkeeping annotation lands on the object.
- **The IRSA path:** unchanged. The `reader` service account and its annotation stay where they are.

## Tasks

1. **Write the association.** Four values in one resource: the cluster, the namespace, the service account, and the role ARN.
2. **Apply and confirm it exists.** List the cluster's Pod Identity associations and read back what the new one holds. The association is an EKS object rather than a Kubernetes one, so it does not appear anywhere inside the cluster.
3. **Write the service account and create it.** Then read the stored object back and confirm there is nothing on it beyond a name and a namespace.
4. **Repoint the probe and rerun it.** Delete the existing pod, change the one line, and apply. Give the association a few seconds to propagate before reading the logs.
5. **Read both logs.** The first container reports the `-reader-podid` role. The second returns the same parameter value as before, through a permission attached to a different role than the one that returned it last time.

## Done when

- `terraform apply` adds one resource and `terraform validate` reports the configuration is valid.
- The cluster reports one association, naming `team-web`, `reader-podid`, and the `-reader-podid` role.
- `kubectl get sa reader-podid -n team-web -o yaml` shows no `annotations` key at all.
- The probe reaches **Completed**, reports an ARN containing the `-reader-podid` role name, and returns the parameter value.
- The `reader` service account and its annotation are still in place, untouched.

## Note

The tradeoff is where the binding lives. With IRSA the role ARN sits on the service account, so reading that object tells you what the pod can do in AWS. With Pod Identity it sits in the association, so answering the same question takes a call to the EKS API.

Nothing validates the two names against each other. EKS accepts a namespace and a service account that do not exist, and Kubernetes has no idea the association was created. Misspell either side and everything applies cleanly, the pod starts, and the AWS call fails as an identity nobody intended.

Give the association a few seconds before running the probe. A pod that starts too early falls back to the node role, so the read is refused, and that looks the same as a wrong association.

Both mechanisms now run on one cluster against different service accounts, and neither knows about the other. That is what makes moving a real workload from one to the other gradual rather than a cutover.

The association is free.
