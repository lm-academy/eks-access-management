# Lab: Annotate the Service Account and Run the Workload

## Goal

Make the role assumable, then prove that one line of the pod spec is what does it. You write the annotated ServiceAccount and a two-container probe that asks AWS who it is and tries the read. Then you run the same manifest twice, once with that line and once without, and watch the pod's AWS identity change from the role you built to the node's.

## Starting point

The applied project with the parameter, the read policy, and the federated role in place. The role's trust policy names a service account called `reader` in `team-web`, which does not exist. Nothing has been able to assume the role.

You write two Kubernetes manifests here and no Terraform. The role ARN comes from an output you already have.

## Configuration to target

- **A ServiceAccount named `reader` in `team-web`**, carrying the annotation `eks.amazonaws.com/role-arn` with your role's ARN. The name and the namespace have to match the trust policy's `sub` condition character for character.
- **A Pod with two containers**, both on the same pinned AWS CLI image. One asks who the pod is, the other reads the parameter by name.
- **`restartPolicy: Never`**, because both containers run once and exit and the answers need to stay readable in the logs.
- **`serviceAccountName: reader`, and nothing else connecting the pod to AWS.** No environment variables, no volumes, no credentials, no region.
- **Pin the image tag.** `latest` would make a future run prove something different from what you saw.
- **Applied as the platform administrator.**

## Tasks

1. **Write the ServiceAccount.** Read the role ARN out of your Terraform outputs rather than retyping it.
2. **Write the probe Pod.** Two containers, one command each, and no AWS configuration of any kind beyond the service account name.
3. **Apply both and read the two logs.** One container reports an identity you did not configure anywhere in the manifest. The other returns the parameter value.
4. **Delete the pod, remove the `serviceAccountName` line, and re-apply.** Read both logs again. The pod still has an AWS identity and it is not the one you built. Read the second container's error too, because it names the identity the pod fell back to. Then put the line back and confirm the working state before committing.

## Done when

- `k8s/reader-serviceaccount.yaml` and `k8s/aws-identity-probe.yaml` both exist and apply cleanly.
- With the service account, the pod reaches **Completed**, the first container reports an ARN containing `assumed-role/` and your reader role's name, and the second returns the parameter value.
- Without the service account, the pod reaches **Error**, the first container reports the node's role with the instance ID as the session name, and the second is refused with **AccessDeniedException** naming that same node role.
- After restoring the line, a fresh run reports the reader role again.

## Note

The annotation is not a grant. It tells the cluster which role ARN to put in front of the pod, and the role's trust policy decides whether the assumption is allowed. Mistype the namespace or the name in either place and everything applies cleanly, then the pod fails at runtime with a message about the assumption rather than about the annotation.

Task 4 is the reason this section exists. Deleting one line did not leave the pod without an AWS identity, it left the pod with the node's, and nothing in the logs announces the substitution. A workload deployed with a typo behaves exactly this way, and it keeps running.

That refusal is a good refusal: the node role is reachable by anything on the node and holds no permission to read this parameter. Broad reach, no permissions, against one permission obtainable by one service account in one namespace.

The probe costs seconds of compute, and the image is pulled through the NAT gateway you are already paying for.
