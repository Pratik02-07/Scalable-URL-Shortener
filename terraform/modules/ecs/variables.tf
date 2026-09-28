variable "name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "alb_dns_name" { type = string }
variable "backend_tg_arn" { type = string }
variable "frontend_tg_arn" { type = string }
variable "aws_region" {
  type    = string
  default = "ap-south-1"
}
variable "app_env" {
  type    = string
  default = "production"
}

variable "backend_image" { type = string }
variable "frontend_image" { type = string }

variable "db_secret_arn" { type = string }
variable "redis_secret_arn" { type = string }
variable "secret_arns" { type = list(string) }

variable "backend_cpu" {
  type    = number
  default = 256
}
variable "backend_memory" {
  type    = number
  default = 512
}
variable "backend_desired_count" {
  type    = number
  default = 2
}
variable "backend_min_count" {
  type    = number
  default = 2
}
variable "backend_max_count" {
  type    = number
  default = 10
}

variable "frontend_cpu" {
  type    = number
  default = 256
}
variable "frontend_memory" {
  type    = number
  default = 512
}
variable "frontend_desired_count" {
  type    = number
  default = 2
}

variable "log_retention_days" {
  type    = number
  default = 30
}
variable "tags" {
  type    = map(string)
  default = {}
}
