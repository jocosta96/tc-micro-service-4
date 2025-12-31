# manifests deployment tags now managed in centralized locals.tf

# =============================================================================
# PHASE 1: CONFIGMAPS (Deploy configuration first)
# =============================================================================

# Database ConfigMap - Using templatefile() to substitute variables from shared configuration
resource "kubernetes_manifest" "database_config" {
  

  manifest = yamldecode(templatefile("${path.module}/manifests/cfm_database.yaml", {cfm_name = "cfm-database-${var.service}"}))

}


# =============================================================================
# PHASE 2: SECRETS (Deploy sensitive configuration)
# =============================================================================

resource "random_password" "basic_auth_password" {
  length  = 16
  special = true
}

resource "aws_ssm_parameter" "valid_token_ssm" {
  name        = "/ordering-system/${var.service}/basic_auth/token"
  description = "Valid token for integration"
  type        = "SecureString"
  value       = random_password.basic_auth_password.result
}


# =============================================================================
# PHASE 3: SYSTEM COMPONENTS (Deploy cluster-wide services)
# =============================================================================

# Metrics Server Configuration

# Fetch metrics-server components directly from the release URL instead of
# bundling a copy of the YAML in the module.
#data "http" "metrics_components" {
#  url = "https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.2/components.yaml"
#}
#
#resource "kubernetes_manifest" "metrics_config" {
#  
#
#  manifest = data.http.metrics_components.response_body
#
#}


# Application Service
resource "kubernetes_manifest" "app_service" {
  

  manifest = yamldecode(templatefile("${path.module}/manifests/svc_app.yaml", {
    load_balancer_name   = "svc-app-lb-${var.service}",
    dpm_name             = "dpm-${var.service}"
  }))

}


# Application Service
resource "kubernetes_manifest" "load_balancer_bind" {
  

  manifest = yamldecode(templatefile("${path.module}/manifests/tgb_nlb.yaml", {
    load_balancer_name   = "svc-app-lb-${var.service}",
    target_group_arn     = var.eks_target_group_arn
    tgb_name             = "tgb-${var.service}"
  }))

}


# =============================================================================
# PHASE 6: AUTOSCALING (Deploy HPA last)
# =============================================================================

# Horizontal Pod Autoscaler
resource "kubernetes_manifest" "app_hpa" {
  

  manifest = templatefile(
    "${path.module}/manifests/hpa_app.yaml", {
      hpa_name = "hpa-app-${var.service}",
      dpm_name = "dpm-${var.service}"
    }
  )

  depends_on = [
#    kubernetes_manifest.metrics_config,
  ]

}

resource "kubernetes_manifest" "app_deployment" {
  

  manifest = templatefile(
    "${path.module}/manifests/dpm_app.yaml", {
      dpm_name     = "dpm-${var.service}",
      dpm_image    = data.aws_ecr_image.service_image_by_digest.image_uri,
      app_sec_name = "sec-app-${var.service}",
      cfm_name     = "cfm-database-${var.service}"
    }
  )

  depends_on = [
    kubernetes_manifest.app_service,
#    kubernetes_manifest.app_secret,
    kubernetes_manifest.database_config,
    kubernetes_manifest.app_hpa,
    data.aws_ecr_image.service_image
  ]

}
