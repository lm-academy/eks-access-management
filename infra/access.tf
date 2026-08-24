resource "aws_eks_access_entry" "team" {
  for_each = aws_iam_role.team

  cluster_name  = module.cluster.cluster_name
  principal_arn = each.value.arn
  type          = "STANDARD"

  tags = local.tags
}

resource "aws_eks_access_policy_association" "team" {
  for_each = aws_eks_access_entry.team

  cluster_name  = module.cluster.cluster_name
  policy_arn    = local.team_access_policies[each.key]
  principal_arn = each.value.principal_arn

  access_scope {
    type       = "cluster"
  }
}