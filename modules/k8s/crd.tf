resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.16.0"

  set = [{
    name  = "clusterName"
    value = var.cluster_name
  }, {
    name  = "region"
    value = var.DEFAULT_REGION
  },{
    name  = "vpcId"
    value = var.vpc_id
  },{
    name  = "serviceAccount.create"
    value = "true"   # still create a SA, but controller will use node IAM
  }]
}
