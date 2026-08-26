resource "aws_iam_role" "ci_deployer" {
  name               = "${var.cluster_name}-ci-deployer"
  assume_role_policy = data.aws_iam_policy_document.team_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "ci_deployer_describe_cluster" {
  role       = aws_iam_role.ci_deployer.name
  policy_arn = aws_iam_policy.describe_cluster.arn
}