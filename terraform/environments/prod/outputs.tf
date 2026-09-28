output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "ecr_backend_url" {
  value = module.ecr.backend_repository_url
}

output "ecr_frontend_url" {
  value = module.ecr.frontend_repository_url
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "rds_endpoint" {
  value     = module.rds.db_endpoint
  sensitive = true
}

output "redis_endpoint" {
  value     = module.redis.redis_endpoint
  sensitive = true
}

output "db_secret_arn" {
  value = module.rds.db_secret_arn
}

output "cloudwatch_dashboard_name" {
  value = module.cloudwatch.dashboard_name
}

output "cloudwatch_sns_topic_arn" {
  value = module.cloudwatch.sns_topic_arn
}
