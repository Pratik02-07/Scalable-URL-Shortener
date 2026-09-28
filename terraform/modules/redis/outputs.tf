output "redis_endpoint" { value = aws_elasticache_replication_group.main.primary_endpoint_address }
output "redis_port" { value = 6379 }
output "replication_group_id" { value = aws_elasticache_replication_group.main.id }
output "redis_secret_arn" { value = aws_secretsmanager_secret.redis.arn }
output "redis_sg_id" { value = aws_security_group.redis.id }
