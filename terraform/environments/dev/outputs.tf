output "alb_dns_name" {
  description = "ALB DNS name — visit this URL to reach the app"
  value       = module.alb.alb_dns_name
}

output "ecr_backend_url" {
  description = "ECR backend repository URL"
  value       = module.ecr.backend_repository_url
}

output "ecr_frontend_url" {
  description = "ECR frontend repository URL"
  value       = module.ecr.frontend_repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = module.redis.redis_endpoint
  sensitive   = true
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  value       = module.rds.db_secret_arn
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = module.cloudwatch.dashboard_name
}

output "cloudwatch_sns_topic_arn" {
  description = "ARN of the SNS alarm topic"
  value       = module.cloudwatch.sns_topic_arn
}
