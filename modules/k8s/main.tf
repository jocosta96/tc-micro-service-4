# manifests deployment tags now managed in centralized locals.tf

# Wait for EKS cluster to be fully ready including EBS CSI driver
resource "null_resource" "eks_cluster_ready" {

  provisioner "local-exec" {
    command = "aws eks wait cluster-active --region ${var.DEFAULT_REGION} --name ${var.cluster_name}"
  }

  provisioner "local-exec" {
    command = "aws eks wait nodegroup-active --region ${var.DEFAULT_REGION} --cluster-name ${var.cluster_name} --nodegroup-name ${var.node_group_name}"
  }
}

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

# Application Secret
resource "kubectl_manifest" "app_secret" {
  yaml_body = templatefile(
    "${path.module}/manifests/sec_app.yaml", {
      sec_name        = "sec-app-${var.service}",
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

