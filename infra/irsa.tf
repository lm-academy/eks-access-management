data "aws_iam_policy_document" "reader_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.cluster.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.cluster.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:team-web:reader"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.cluster.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "reader" {
  name               = "${var.cluster_name}-reader"
  assume_role_policy = data.aws_iam_policy_document.reader_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "reader_read_greeting" {
  role       = aws_iam_role.reader.name
  policy_arn = aws_iam_policy.read_greeting.arn
}