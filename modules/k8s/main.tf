# manifests deployment tags now managed in centralized locals.tf

# =============================================================================
# PHASE 1: CONFIGMAPS (Deploy configuration first)
# =============================================================================

# Database ConfigMap - Using templatefile() to substitute variables from shared configuration
resource "kubectl_manifest" "database_config" {

  yaml_body = templatefile("${path.module}/manifests/cfm_database.yaml", {
    cfm_name = "cfm-database-${var.service}"
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
      sec_name        = "sec-app-${var.service}",
      api_user_base64 = base64encode("ordering"),
      api_password_base64 = base64encode(random_password.basic_auth_password.result)
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
resource "kubectl_manifest" "metrics_config" {

  yaml_body = file("${path.module}/manifests/metrics.yaml")

  depends_on = [
    kubectl_manifest.app_secret,
  ]
}


# Application Service
resource "kubectl_manifest" "app_service" {

  yaml_body = templatefile("${path.module}/manifests/svc_app.yaml", {
    load_balancer_scheme = "internal",
    load_balancer_name   = "svc-app-lb-${var.service}"
  })

}


# =============================================================================
# PHASE 6: AUTOSCALING (Deploy HPA last)
# =============================================================================

# Horizontal Pod Autoscaler
resource "kubectl_manifest" "app_hpa" {

  yaml_body = templatefile(
    "${path.module}/manifests/hpa_app.yaml", {
      hpa_name       = "hpa-app-${var.service}",
      dpm_name       = "dpm-${var.service}"
    } 
  )

  depends_on = [
    kubectl_manifest.metrics_config,
  ]
}

