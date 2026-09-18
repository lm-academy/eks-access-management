resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = module.cluster.cluster_name
  addon_name   = "eks-pod-identity-agent"

  tags = local.tags
}

data "aws_iam_policy_document" "pod_identity_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "reader_podid" {
  name               = "${var.cluster_name}-reader-podid"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "reader_podid_read_greeting" {
  role       = aws_iam_role.reader_podid.name
  policy_arn = aws_iam_policy.read_greeting.arn
}

resource "aws_eks_pod_identity_association" "reader_podid" {
  cluster_name    = module.cluster.cluster_name
  namespace       = "team-web"
  service_account = "reader-podid"
  role_arn        = aws_iam_role.reader_podid.arn

  tags = local.tags
}