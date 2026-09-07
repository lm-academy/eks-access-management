# Lab: Add the Pod Identity Agent and the Reusable Role

## Goal

Give the same workload a second AWS identity, through Pod Identity rather than OIDC federation. You install the agent that serves credentials on every node, then write an IAM role carrying the same read permission but trusting a service instead of a cluster. By the end the agent runs on both nodes, one permission policy is attached to two roles, and nothing on the cluster is bound to the new role.

## Starting point

You continue from the applied project, with pod-level AWS access already working through IRSA: the SSM parameter, the read policy, the federated reader role, the annotated `reader` service account in `team-web`, and the probe Pod that reads the parameter as that role. The policy is attached to exactly one role.

You add one Terraform file and no Kubernetes manifests.

## Configuration to target

- **New file `infra/pod_identity.tf`:** the addon and the second role.
- **The addon:** `eks-pod-identity-agent`, declared as its own resource rather than added to the cluster module's addon map.
- **Addon version:** none. EKS installs the default for the cluster's Kubernetes version, which is how the module declares the addons it already owns.
- **Role name:** the cluster name followed by `-reader-podid`.
- **Who may assume it (trust):** the service principal `pods.eks.amazonaws.com`, allowed to perform `sts:AssumeRole` and `sts:TagSession`. Both actions are required. This document has no condition block.
- **What it may do (permissions):** the read policy you already wrote, attached as its own attachment resource. You write no new permissions policy.
- **The federated role:** unchanged. Nothing in this lab touches it.
- **Output:** the new role's ARN, since the association that binds it to a service account needs the value.

## Tasks

1. **Add the agent and apply it on its own.** One resource naming the cluster and the addon. Applying it before the IAM work lets you watch the DaemonSet arrive, and shows that the addon is the only thing this mechanism installs on the cluster.
2. **Write the trust policy document.** Put it next to the federated role's document and compare the two. Everything that ties the federated role to one cluster and one service account has no counterpart here: no provider, no `sub`, no `aud`.
3. **Write the role and attach the existing policy.** Reference the policy resource rather than pasting its ARN, and output the new role's ARN.
4. **Apply.** Two more resources, and the role ARN prints as an output.
5. **Read the trust policy back and list the cluster's associations.** The principal is a service, both actions are present, and there is no condition. The association list is empty, because nothing has been bound to the role yet.

## Done when

- Two applies add three resources between them, and `terraform validate` reports the configuration is valid.
- The `eks-pod-identity-agent` DaemonSet in `kube-system` runs one ready pod per node.
- The new role's trust policy shows a `Service` principal of `pods.eks.amazonaws.com`, both `sts:AssumeRole` and `sts:TagSession`, and no `Condition` key.
- The cluster reports zero Pod Identity associations.

## Note

The two trust policies differ in what they pin down. The federated document names a provider belonging to one cluster, and pins two conditions to one namespace and one service account name. This one names a service principal that is the same string in every AWS account, and pins nothing. So the federated role works only from the cluster it was written for, while this one works from any cluster where somebody creates an association naming it. What limits its use is who holds the IAM permission to create associations.

`sts:TagSession` is required, and leaving it out is hard to diagnose. EKS attaches session tags on every assume it performs for a pod, so a trust policy allowing only `sts:AssumeRole` refuses the assume and the pod never receives credentials. The pod reports `Unauthorized Exception! EKS does not have permissions to assume the associated role`, which mentions neither tags nor the missing action.

Everything in this lab is free.
