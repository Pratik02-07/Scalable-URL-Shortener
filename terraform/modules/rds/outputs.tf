output "db_endpoint" { value = aws_db_instance.main.address }
output "db_port" { value = aws_db_instance.main.port }
output "db_name" { value = aws_db_instance.main.db_name }
output "db_instance_identifier" { value = aws_db_instance.main.identifier }
output "db_secret_arn" { value = aws_secretsmanager_secret.db.arn }
output "rds_sg_id" { value = aws_security_group.rds.id }
