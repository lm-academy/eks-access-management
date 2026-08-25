resource "aws_eks_access_entry" "team" {
  for_each = aws_iam_role.team

  cluster_name  = module.cluster.cluster_name
  principal_arn = each.value.arn
  type          = "STANDARD"

  tags = local.tags
}

moved {
  from = aws_eks_access_policy_association.team["platform-admin"]
  to   = aws_eks_access_policy_association.team["platform-admin_admin"]
}

moved {
  from = aws_eks_access_policy_association.team["developer"]
  to   = aws_eks_access_policy_association.team["developer_view"]
}

resource "aws_eks_access_policy_association" "team" {
  for_each = local.team_policy_associations

  cluster_name = module.cluster.cluster_name

  policy_arn    = each.value.policy_arn
  principal_arn = aws_eks_access_entry.team[each.value.team].principal_arn

  access_scope {
    type       = each.value.access_scope.type
    namespaces = each.value.access_scope.namespaces
  }
}