# Note: In AWS Learner Labs, IAM role creation is often restricted.
# We'll try to use data sources to reference existing roles or use a different approach.

# IAM tags now managed in centralized locals.tf

# Try to find existing LabRole which is commonly available in AWS Learner Labs
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Get current AWS caller identity
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# Get current AWS partition
data "aws_partition" "current" {}

# For AWS Learner Labs compatibility, we'll use the existing LabRole
# This role typically has broad permissions needed for educational purposes
# Role ARNs now managed in centralized locals.tf


# IAM role ARNs for EKS cluster and node groups
locals {

  cluster_role_arn    = data.aws_iam_role.lab_role.arn
  node_group_role_arn = data.aws_iam_role.lab_role.arn

}

