#mirror and cache Docker Hub images in ECR for faster pulls and reduced external dependencies

locals {
  ecr_url = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.region}.amazonaws.com"
  prefix = "dockerhub/${var.service}"
}

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
  # Store the image name so it's preserved for the destroy phase
  input = {"image" = var.image_name, "prefix" = local.prefix}

  provisioner "local-exec" {
    when    = destroy
    # Reference the stored value via self.input
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

