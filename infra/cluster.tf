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

  tags = local.tags
}
