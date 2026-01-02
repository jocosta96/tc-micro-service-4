#mirror and cache Docker Hub images in ECR for faster pulls and reduced external dependencies

locals {
  ecr_url = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.region}.amazonaws.com"
  prefix = "dockerhub/${var.service}"
}

# manually created using the docker PAT 
# {"username":"jocosta96","accessToken":"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"}
data "aws_secretsmanager_secret" "dockerhub_creds" {
  name = "ecr-pullthroughcache/dockerhub-creds"
}

data "aws_secretsmanager_secret_version" "dockerhub_creds_version" {
  secret_id = data.aws_secretsmanager_secret.dockerhub_creds.id
}

resource "aws_ecr_pull_through_cache_rule" "dockerhub" {
  ecr_repository_prefix = local.prefix
  upstream_registry_url = "registry-1.docker.io"
  credential_arn        = data.aws_secretsmanager_secret_version.dockerhub_creds_version.arn
  depends_on = [ aws_ecr_repository_creation_template.dockerhub_template ]
}

resource "terraform_data" "ecr_cleanup" {
  input = {"image" = var.image_name, "prefix" = local.prefix}

  provisioner "local-exec" {
    when    = destroy
    command = "aws ecr delete-repository --repository-name ${self.input.prefix}/${self.input.image} --force"
  }

  depends_on = [ aws_ecr_pull_through_cache_rule.dockerhub ]
}

resource "aws_ecr_repository_creation_template" "dockerhub_template" {
  prefix      = local.prefix
  description = "Settings for ${var.service} microservice"
  image_tag_mutability = "MUTABLE"
  applied_for = ["PULL_THROUGH_CACHE"]
}

resource "terraform_data" "ecr_warmup" {
  triggers_replace = [var.image_tag]

  provisioner "local-exec" {
    command = <<EOT
      # 1. Get the ECR auth token
      TOKEN=$(aws ecr get-login-password --region ${var.DEFAULT_REGION})
      
      # 2. Build the URL (Ensure it has .amazonaws.com)
      REGISTRY="${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.DEFAULT_REGION}.amazonaws.com"
      REPO_PATH="${local.prefix}/${var.image_name}"
      
      # 3. Request the manifest. 
      # A HEAD request (-I) is sufficient to trigger the PTC sync
      curl -I -X GET \
        -H "Authorization: Basic $(echo -n AWS:$TOKEN | base64 | tr -d '\n')" \
        "https://$REGISTRY/v2/$REPO_PATH/manifests/${var.image_tag}"

      sleep 10
    EOT
  }

  depends_on = [ aws_ecr_pull_through_cache_rule.dockerhub, aws_ecr_repository_creation_template.dockerhub_template ]
}



# validate if image exists
data "aws_ecr_image" "service_image" {
  repository_name = "${aws_ecr_pull_through_cache_rule.dockerhub.ecr_repository_prefix}/${var.image_name}"
  image_tag       = var.image_tag
  depends_on = [ aws_ecr_pull_through_cache_rule.dockerhub, terraform_data.ecr_warmup ]
  
}

# forcing digest uri
data "aws_ecr_image" "service_image_by_digest" {
  repository_name = data.aws_ecr_image.service_image.repository_name
  image_digest       = data.aws_ecr_image.service_image.id
}