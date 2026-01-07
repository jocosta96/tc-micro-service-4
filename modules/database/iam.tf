# Note: In AWS Learner Labs, IAM role creation is often restricted.
# We'll try to use data sources to reference existing roles or use a different approach.

# IAM tags now managed in centralized locals.tf

# Try to find existing LabRole which is commonly available in AWS Learner Labs
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}
