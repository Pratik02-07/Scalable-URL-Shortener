variable "name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "ecs_sg_id" { type = string }
variable "node_type" {
  type    = string
  default = "cache.t3.micro"
}
variable "num_cache_clusters" {
  type    = number
  default = 1
}
variable "tags" {
  type    = map(string)
  default = {}
}
