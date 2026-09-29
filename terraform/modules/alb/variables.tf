variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "enable_deletion_protection" {
  type    = bool
  default = false
}

variable "access_log_bucket" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "certificate_arn" {
  type        = string
  description = "ACM Certificate ARN for HTTPS listener. If provided, port 80 redirects to port 443."
  default     = ""
}

