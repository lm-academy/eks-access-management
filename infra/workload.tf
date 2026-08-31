# This contains some mock AWS resources for Kubernetes workloads to read.
# Used when demonstrating IRSA.

resource "aws_ssm_parameter" "greeting" {
  name  = "/${var.cluster_name}/greeting"
  type  = "String"
  value = "hello from parameter store"
  tags  = local.tags
}

data "aws_iam_policy_document" "read_greeting" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.greeting.arn]
  }
}

resource "aws_iam_policy" "read_greeting" {
  name        = "${var.cluster_name}-read-greeting"
  policy      = data.aws_iam_policy_document.read_greeting.json
  description = "Read the single parameter the demo workload reads."
  tags        = local.tags
}