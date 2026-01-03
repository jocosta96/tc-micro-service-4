locals {
  cfm_name = "cfm-database-${var.service}"
  sec_name            = "sec-app-${var.service}"
  api_user_base64     = base64encode("ordering")
  api_password_base64 = base64encode(random_password.basic_auth_password.result)
  load_balancer_scheme = "internal"
  load_balancer_name   = "svc-app-lb-${var.service}"
  service_name         = "${var.service}"
  dpm_name             = "dpm-${var.service}"
  target_group_arn     = var.nlb_target_group_arn
  tgb_name             = "tgb-${var.service}"
  hpa_name = "hpa-app-${var.service}"
  dpm_image    = data.aws_ecr_image.service_image_by_digest.image_uri
  app_sec_name = "sec-app-${var.service}"
  region  = var.DEFAULT_REGION
}

# manifests deployment tags now managed in centralized locals.tf

# =============================================================================
# PHASE 1: CONFIGMAPS (Deploy configuration first)
# =============================================================================

# Database ConfigMap - Using templatefile() to substitute variables from shared configuration
resource "kubectl_manifest" "database_config" {

  yaml_body = templatefile("${path.module}/manifests/cfm_database.yaml", {
    cfm_name = local.cfm_name
  })

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


# Application Secret
resource "kubectl_manifest" "app_secret" {
  yaml_body = templatefile(
    "${path.module}/manifests/sec_app.yaml", {
      sec_name            = local.sec_name,
      api_user_base64     = local.api_user_base64,
      api_password_base64 = local.api_password_base64
    }
  )

  depends_on = [
    kubectl_manifest.database_config
  ]

}

# =============================================================================
# PHASE 3: SYSTEM COMPONENTS (Deploy cluster-wide services)
# =============================================================================

# Metrics Server Configuration

# Fetch metrics-server components directly from the release URL instead of
# bundling a copy of the YAML in the module.
data "http" "metrics_components" {
  url = "https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.2/components.yaml"
}

resource "kubectl_manifest" "metrics_config" {

  yaml_body = data.http.metrics_components.response_body

}


# Application Service
resource "kubectl_manifest" "app_service" {

  yaml_body = templatefile("${path.module}/manifests/svc_app.yaml", {
    load_balancer_name   = local.load_balancer_name,
    dpm_name             = local.dpm_name
  })
}


# =============================================================================
# PHASE 6: AUTOSCALING (Deploy HPA last)
# =============================================================================

# Horizontal Pod Autoscaler
resource "kubectl_manifest" "app_hpa" {

  yaml_body = templatefile(
    "${path.module}/manifests/hpa_app.yaml", {
      hpa_name = local.hpa_name,
      dpm_name = local.dpm_name
    }
  )

  depends_on = [
    kubectl_manifest.metrics_config,
  ]

}

resource "kubectl_manifest" "app_deployment" {

  yaml_body = templatefile(
    "${path.module}/manifests/dpm_app.yaml", {
      dpm_name     = local.dpm_name,
      dpm_image    = local.dpm_image,
      app_sec_name = local.app_sec_name,
      cfm_name     = local.cfm_name
      target_group_arn     = local.target_group_arn
      region  = local.region
    }
  )

  depends_on = [
    kubectl_manifest.app_service,
    kubectl_manifest.app_secret,
    kubectl_manifest.database_config,
    kubectl_manifest.app_hpa,
    data.aws_ecr_image.service_image
  ]

}


# Application Service
resource "kubectl_manifest" "nlb_target_group_bind" {

  yaml_body = templatefile("${path.module}/manifests/nlb_tgb.yaml", {
    load_balancer_name   = local.load_balancer_name,
    target_group_arn     = local.target_group_arn
    tgb_name             = local.tgb_name
  })

  depends_on = [
    kubectl_manifest.app_deployment,
    helm_release.aws_lb_controller
  ]
}
