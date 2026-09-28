variable "name" {
  description = "Name prefix"
  type        = string
}

variable "max_image_count" {
  description = "Maximum number of tagged images to retain per repository"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
