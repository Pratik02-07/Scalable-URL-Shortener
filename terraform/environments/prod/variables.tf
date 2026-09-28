variable "project" {
  type    = string
  default = "url-shortener"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "db_password" {
  type      = string
  sensitive = true
}
