# Separate resource to add bastion security group to database after both are created
# This avoids circular dependency between database and bastion modules
resource "aws_security_group_rule" "database_from_bastion" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.catalog_bastion.security_group_id
  security_group_id        = module.catalog_database.database_security_group_id

  depends_on = [
    module.catalog_database,
    module.catalog_bastion
  ]
}

