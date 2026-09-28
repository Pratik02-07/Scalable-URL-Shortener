variable "name" {
  description = "Resource name prefix"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  type        = string
}

variable "backend_service_name" {
  description = "Name of the ECS backend service"
  type        = string
}

variable "frontend_service_name" {
  description = "Name of the ECS frontend service"
  type        = string
}

variable "backend_log_group_name" {
  description = "CloudWatch log group name for the backend container"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics (e.g. app/url-shortener-dev-alb/123456789)"
  type        = string
  default     = ""
}

variable "target_group_arn_suffix" {
  description = "Target Group ARN suffix for CloudWatch metrics"
  type        = string
  default     = ""
}

variable "rds_instance_identifier" {
  description = "RDS DB instance identifier for CloudWatch metrics"
  type        = string
  default     = ""
}

variable "redis_cluster_id" {
  description = "ElastiCache replication group / cluster ID for CloudWatch metrics"
  type        = string
  default     = ""
}

variable "alarm_email" {
  description = "Email address for SNS CloudWatch alarm notifications (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to assign to resources"
  type        = map(string)
  default     = {}
}
