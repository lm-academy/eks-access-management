locals {
  # Applied by the provider to every resource in this root, and passed into the
  # cluster module for the resources it creates.
  tags = merge(
    {
      Project   = var.cluster_name
      ManagedBy = "terraform"
    },
    var.tags
  )
}
