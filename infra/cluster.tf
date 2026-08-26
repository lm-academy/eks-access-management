# The cluster this section runs against. Everything it creates lives in
# modules/cluster: the VPC, the EKS control plane, the Spot node group, and the
# core addons. Treat it as settled infrastructure and add the files this
# section's topic needs alongside this one.
#
# Cluster shaping inputs such as kubernetes_version, node_instance_types, and
# vpc_cidr keep their defaults inside the module. Set one here when a topic
# needs it.

module "cluster" {
  source = "./modules/cluster"

  cluster_name        = var.cluster_name
  authentication_mode = var.authentication_mode

  access_entries = {
    "ci-deployer" = {
      principal_arn = aws_iam_role.ci_deployer.arn
      tags          = local.tags
      policy_associations = {
        deploy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["team-web"]
          }
        }
      }
    }
  }
  tags = local.tags
}
