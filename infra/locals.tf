locals {
  # Applied by the provider to every resource in this root, and passed into the
  # cluster module for the resources it creates.
  team_roles = ["developer", "platform-admin"]
  team_kubernetes_groups = {
    developer = ["debuggers"]
  }

  team_policy_associations = {
    "developer_view" = {
      team         = "developer"
      policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
      access_scope = { type = "cluster", namespaces = null }
    }
    "developer_edit-team-web" = {
      team         = "developer"
      policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
      access_scope = { type = "namespace", namespaces = ["team-web"] }
    }
    "platform-admin_admin" = {
      team         = "platform-admin"
      policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope = { type = "cluster", namespaces = null }
    }
  }

  tags = merge(
    {
      Project   = var.cluster_name
      ManagedBy = "terraform"
    },
    var.tags
  )
}
