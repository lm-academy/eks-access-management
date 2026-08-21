# EKS Access Management

The code for the EKS Access Management sections of the Amazon EKS with Terraform course. This one repository holds both the starting point and the finished version of every section.

## Start here

Cloning drops you on `main`, which is every section already written. Check out the tag the first section begins from:

```bash
git clone https://github.com/lm-academy/eks-access-management.git
cd eks-access-management
git checkout starter/access-entries
```

Every section marks two points in the history. Its `starter/` tag is the code as the section begins, and its `solution/` tag is the code as it ends. Finishing one section leaves you where the next begins, so working straight through you check out nothing else. The tags are there for skipping ahead, and for reading my version when you want to compare.

## What you get

- `infra/`, a Terraform root creating a VPC and an EKS cluster. This is the cluster every section runs against, handed over ready to apply.
- `k8s/`, the manifests the sections use as subject matter: two namespaces and a small nginx workload.
- `.devcontainer/` and `.tool-versions`, pinning terraform, the AWS CLI, kubectl, and helm.
- `_labs/`, the brief for each lab, describing what to build rather than handing you the code.

## Layout

`infra/` is the only Terraform root. The cluster sits in a local module underneath it, so the files you write stay separate from the plumbing that creates it:

```
infra/
  backend.tf                 remote state, pointed at your own bucket
  cluster.tf                 a single call to modules/cluster
  locals.tf                  tags
  outputs.tf                 cluster name, endpoint, OIDC provider, node role
  providers.tf
  variables.tf               cluster_name, authentication_mode, tags
  versions.tf
  terraform.tfvars.example   copy to terraform.tfvars
  modules/cluster/           VPC, control plane, node group, addons
k8s/
  namespaces.yaml            team-web and team-api
  nginx.yaml                 Deployment and ClusterIP Service
```

Treat `modules/cluster/` as settled infrastructure. Add the resources each section asks for next to `cluster.tf`, and read what you need about the cluster from `module.cluster`, such as `module.cluster.cluster_name` or `module.cluster.oidc_provider_arn`.

## Prerequisites

- An AWS account, credentials configured for the AWS CLI, and an existing S3 bucket for Terraform state.
- Docker plus VS Code with the Dev Containers extension. To work without Docker, install the versions listed in `.tool-versions`.
- The AWS region comes from the `AWS_REGION` value in `.devcontainer/devcontainer.json`. Change it there to work in a different region.

## Run it

Open the folder in the devcontainer, then:

**1. The backend.** The `backend "s3"` block in `infra/backend.tf` ships without a bucket and key. Either add both attributes to the block in code:

```hcl
backend "s3" {
  bucket       = "your-state-bucket"
  key          = "eks-access-management/terraform.tfstate"
  encrypt      = true
  use_lockfile = true
}
```

or leave the file untouched and pass them at init time, shown in step 3.

**2. The variables.** Copy the example file and keep the values it ships with:

```bash
cp infra/terraform.tfvars.example infra/terraform.tfvars
```

The cluster uses `API` mode, so access to it is managed entirely through access entries. The value is set explicitly rather than left to the provider default, so that it is visible in a file you can read.

**3. Init, apply, connect.**

```bash
cd infra
terraform init \
  -backend-config="bucket=your-state-bucket" \
  -backend-config="key=eks-access-management/terraform.tfstate"
terraform apply

$(terraform output -raw update_kubeconfig_command)
kubectl get nodes
```

If you added the bucket and key in code, plain `terraform init` does it. The apply takes roughly 15 to 20 minutes, most of it the control plane. Both nodes reporting `Ready` means the cluster is good to go.

## Cost

The running cluster costs money, a couple of cents per hour, with the exact rate varying by region and by the instance types the Spot node group lands on. The access objects the sections create are free, as are the IAM roles and the SSM parameter.

Pausing between sections is cheap: run `terraform destroy` from `infra/`, keep your code, and re-apply when you come back. It takes about 15 minutes to get the cluster back.
