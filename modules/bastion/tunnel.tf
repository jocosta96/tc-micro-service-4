locals {
  tunnel_tags = {
    origin = "tc-micro-service-4/modules/bastion/tunnel.tf"
  }
}

# Null resource to output SSH tunnel and DBeaver configuration
resource "null_resource" "ssh_tunnel_info" {
  # Output connection details after bastion is created
  triggers = {
    bastion_ip     = aws_instance.bastion.public_ip
    db_endpoint    = var.database_endpoint
    db_port        = var.database_port
    key_pair_name  = var.key_pair_name
    ssm_path       = var.ssm_path_prefix
  }

  # Output the SSH tunnel command and DBeaver config via local-exec
  provisioner "local-exec" {
    command = <<-EOT
      cat <<EOF
      ========================================
      SSH Tunnel & DBeaver Configuration
      ========================================
      
      SSH Tunnel Command (run in separate terminal):
      ssh -L 5432:${var.database_endpoint}:${var.database_port} -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${aws_instance.bastion.public_ip} -N
      
      Then connect DBeaver to: localhost:5432
      
      DBeaver Built-in SSH Tunnel Configuration:
        Connection Type: PostgreSQL
        Host: localhost (if using manual tunnel) OR ${var.database_endpoint} (if using DBeaver tunnel)
        Port: 5432
        Database: (retrieve from SSM: ${var.ssm_path_prefix}/name)
        Username: (retrieve from SSM: ${var.ssm_path_prefix}/username)
        Password: (retrieve from SSM: ${var.ssm_path_prefix}/password)
        
        SSH Settings:
          Enable SSH tunnel: ✓
          SSH Host: ${aws_instance.bastion.public_ip}
          SSH Port: 22
          SSH User: ec2-user
          SSH Key: ~/.ssh/${var.key_pair_name}.pem
          Remote Host: ${var.database_endpoint}
          Remote Port: ${var.database_port}
      
      Database Credentials (from SSM Parameter Store):
        aws ssm get-parameter --name "${var.ssm_path_prefix}/host" --query Parameter.Value --output text
        aws ssm get-parameter --name "${var.ssm_path_prefix}/port" --query Parameter.Value --output text
        aws ssm get-parameter --name "${var.ssm_path_prefix}/name" --query Parameter.Value --output text
        aws ssm get-parameter --name "${var.ssm_path_prefix}/username" --query Parameter.Value --output text
        aws ssm get-parameter --name "${var.ssm_path_prefix}/password" --with-decryption --query Parameter.Value --output text
      
      ========================================
      EOF
    EOT
  }

  depends_on = [aws_instance.bastion]
}

