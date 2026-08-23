data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "team_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "team" {
  for_each = toset(local.team_roles)

  name               = "${var.cluster_name}-${each.value}"
  assume_role_policy = data.aws_iam_policy_document.team_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "describe_cluster" {
  statement {
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = [module.cluster.cluster_arn]
  }
}

resource "aws_iam_policy" "describe_cluster" {
  name        = "${var.cluster_name}-describe-cluster"
  description = "Describe this cluster, which is all kubectl needs to find it."
  policy      = data.aws_iam_policy_document.describe_cluster.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "team_describe_cluster" {
  for_each = aws_iam_role.team

  role       = each.value.name
  policy_arn = aws_iam_policy.describe_cluster.arn
}