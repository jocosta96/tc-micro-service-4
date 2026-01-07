resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name             = var.cluster_name
  addon_name               = "amazon-cloudwatch-observability"
  service_account_role_arn = data.aws_iam_role.lab_role.arn
  #  resolve_conflicts_on_create = "OVERWRITE"
  depends_on = [kubectl_manifest.app_deployment]
}