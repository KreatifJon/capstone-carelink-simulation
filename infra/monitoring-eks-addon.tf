# =============================================================================
# monitoring-eks-addon.tf  (SRE proposal, touches Jack's cluster resources: Jack to review)
#
# Without this, no pod/node metrics and no container logs reach CloudWatch, so the
# redundancy-lost alarm, node alarms, error filters and log dashboard have no data.
# It only REFERENCES eks.tf resources; it does not change them.
#
# Simplest authentication model for the capstone: the node role gets the AWS-managed
# CloudWatchAgentServerPolicy. (A tighter alternative is EKS Pod Identity / IRSA for the
# add-on's service account; mention it as a hardening step if asked.)
# =============================================================================

resource "aws_iam_role_policy_attachment" "eks_nodes_cloudwatch" {
  count = var.monitor_eks ? 1 : 0

  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_eks_addon" "cloudwatch_observability" {
  count = var.monitor_eks ? 1 : 0

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "amazon-cloudwatch-observability"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.common_tags

  # Our log groups must exist first so retention and the CMK apply.
  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.eks_nodes_cloudwatch,
    aws_cloudwatch_log_group.ci_application,
    aws_cloudwatch_log_group.ci_performance,
  ]
}
