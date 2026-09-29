variable "name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "ecs_sg_id" {
  type        = string
  description = "SG of ECS tasks allowed to connect"
}
variable "db_name" {
  type    = string
  default = "urlshortener"
}
variable "db_username" {
  type    = string
  default = "postgres"
}
variable "db_password" {
  type      = string
  sensitive = true
}
variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "allocated_storage" {
  type    = number
  default = 20
}
variable "multi_az" {
  type    = bool
  default = false
}
variable "deletion_protection" {
  type    = bool
  default = false
}
variable "backup_retention_days" {
  type    = number
  default = 1
}
variable "performance_insights_enabled" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
