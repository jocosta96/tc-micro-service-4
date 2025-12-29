locals {
  iam_tags = {
    origin = "tc-micro-service-4/modules/bastion/iam.tf"
  }
}

# IAM role for bastion host
resource "aws_iam_role" "bastion_role" {
  name = "${var.service}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.iam_tags, {
    Name = "${var.service}-bastion-role"
  })
}

# IAM policy for SSM Parameter Store read access
resource "aws_iam_role_policy" "bastion_ssm_read" {
  name = "${var.service}-bastion-ssm-read"
  role = aws_iam_role.bastion_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "${var.ssm_path_prefix}/*"
        ]
      }
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.service}-bastion-profile"
  role = aws_iam_role.bastion_role.name

  tags = merge(local.iam_tags, {
    Name = "${var.service}-bastion-profile"
  })
}

