# Lab: Add the Pod Identity Agent and the Reusable Role

## Goal

Build a second AWS identity for the same workload, by a route that never touches the cluster's OIDC provider. You add the agent that serves credentials on every node, then write an IAM role carrying the same single permission the federated role holds, reached through a trust policy that names a service instead of a cluster. By the end the agent runs on both nodes, one permission policy is attached to two roles, and nothing on the cluster is bound to the new one.

## Starting point

The applied project with pod-level AWS access already working one way: the SSM parameter, the `read-greeting` managed policy, the federated reader role, the annotated `reader` service account in `team-web`, and the probe Pod that reads the parameter as that role. The managed policy is attached to exactly one role.

You add `infra/pod_identity.tf` and no Kubernetes manifests.

## Configuration to target

- **The `eks-pod-identity-agent` addon**, declared as its own resource rather than added to the cluster module's addon map.
- **No version pinned on the addon.** EKS installs the default for the cluster's Kubernetes version, matching how the module declares the addons it already owns.
- **A second IAM role**, the cluster name followed by `-reader-podid`.
- **A trust policy naming a service rather than a provider.** The principal is the service `pods.eks.amazonaws.com`, and the actions are `sts:AssumeRole` and `sts:TagSession`. Both are required, and there is no condition block anywhere in the document.
- **The existing read policy attached to the new role**, as its own attachment resource. You write no new permissions policy.
- **Nothing about the federated role changes.**
- **An output holding the new role's ARN**, because the binding written next needs it.

## Tasks

1. **Add the agent and apply it on its own.** One resource, naming the cluster and the addon. Applying it before the IAM work lets you watch the DaemonSet arrive and confirms the addon is the only cluster-side thing this mechanism installs.
2. **Write the trust policy document.** Put it next to the federated role's document and write it by subtraction. Every line that ties the federated role to one cluster and one service account has no counterpart here.
3. **Write the role and attach the existing policy.** Reference the policy resource you already have rather than pasting its ARN, and output the new role's ARN.
4. **Apply, then confirm the agent is serving on every node.** One agent pod per node, all of them ready.
5. **Read the trust policy back from AWS.** Confirm the principal is a service, both actions are present, and the document contains no condition at all.
6. **Confirm one policy now sits on two roles, and that nothing uses the new one.** Ask IAM which roles the read policy is attached to, then ask the cluster for its Pod Identity associations. The second answer is empty, and that is the lab finishing correctly.

## Done when

- Two applies add three resources between them, and `terraform validate` reports the configuration is valid.
- The `eks-pod-identity-agent` addon reports status **ACTIVE** with no health issues.
- The `eks-pod-identity-agent` DaemonSet in `kube-system` reports one ready pod per node.
- The new role's trust policy shows a `Service` principal of `pods.eks.amazonaws.com`, both `sts:AssumeRole` and `sts:TagSession`, and no `Condition` key.
- The `read-greeting` policy lists two attached roles, the federated one and the new one.
- The cluster reports zero Pod Identity associations.

## Note

Write the two trust policies side by side and the lesson is on screen without anyone narrating it. The federated document names a provider that points at one cluster and pins two conditions to one namespace and one service account name. This one names a service that is the same string in every account on earth, and pins nothing. The federated role works only from the cluster it was written for; this one works from any cluster where somebody creates an association for it.

`sts:TagSession` is not optional and the failure is not obvious. EKS attaches session tags on every assume it performs for a pod, so a trust policy allowing only `sts:AssumeRole` refuses the assume and the workload never gets credentials. The pod reports `Unauthorized Exception! EKS does not have permissions to assume the associated role`, which names neither tags nor the missing action.

The role is finished and inert. What decides whether it is ever used is who may create an association naming it, an IAM permission held outside the cluster. You also pinned no addon version, so read back which one EKS chose.

Everything in this lab is free.
