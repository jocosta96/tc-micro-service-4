output "public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "security_group_id" {
  description = "Security group ID of the bastion host"
  value       = aws_security_group.bastion_sg.id
}

output "ssh_tunnel_command" {
  description = "SSH tunnel command for database access"
  value       = "ssh -L 5432:${var.database_endpoint}:${var.database_port} -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${aws_instance.bastion.public_ip} -N"
}

output "dbeaver_config" {
  description = "DBeaver SSH tunnel configuration details"
  value = {
    ssh_host     = aws_instance.bastion.public_ip
    ssh_port     = 22
    ssh_user     = "ec2-user"
    ssh_key      = "~/.ssh/${var.key_pair_name}.pem"
    remote_host  = var.database_endpoint
    remote_port   = var.database_port
    ssm_path     = var.ssm_path_prefix
  }
}

