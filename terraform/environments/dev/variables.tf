variable "project" {
  type    = string
  default = "url-shortener"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "RDS PostgreSQL main password — set via TF_VAR_db_password or terraform.tfvars"
}
