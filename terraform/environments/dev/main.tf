###############################################################################
# Dev Environment — main.tf
# Wires together all Terraform modules for the development environment.
###############################################################################

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local state: state is managed locally on disk (terraform.tfstate)
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

locals {
  name = "${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ── Data sources ──────────────────────────────────────────────────────────────
data "aws_caller_identity" "current" {}

# ── Modules ───────────────────────────────────────────────────────────────────

module "vpc" {
  source   = "../../modules/vpc"
  name     = local.name
  vpc_cidr = var.vpc_cidr
  tags     = local.tags
}

module "ecr" {
  source          = "../../modules/ecr"
  name            = var.project # ECR repos are shared across environments
  max_image_count = 10
  tags            = local.tags
}

module "alb" {
  source            = "../../modules/alb"
  name              = local.name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  tags              = local.tags
}

module "rds" {
  source              = "../../modules/rds"
  name                = local.name
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  ecs_sg_id           = module.ecs.ecs_tasks_sg_id
  db_password         = var.db_password
  instance_class      = "db.t3.micro"
  multi_az            = false # dev: single-AZ to save cost
  deletion_protection = false
  tags                = local.tags
}

module "redis" {
  source             = "../../modules/redis"
  name               = local.name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  ecs_sg_id          = module.ecs.ecs_tasks_sg_id
  node_type          = "cache.t3.micro"
  num_cache_clusters = 1 # dev: no replica
  tags               = local.tags
}

module "ecs" {
  source             = "../../modules/ecs"
  name               = local.name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_sg_id          = module.alb.alb_sg_id
  alb_dns_name       = module.alb.alb_dns_name
  backend_tg_arn     = module.alb.backend_tg_arn
  frontend_tg_arn    = module.alb.frontend_tg_arn
  aws_region         = var.aws_region
  app_env            = var.environment

  # Images — override via CI/CD; defaults here allow terraform plan without a real image
  backend_image  = "${module.ecr.backend_repository_url}:latest"
  frontend_image = "${module.ecr.frontend_repository_url}:latest"

  db_secret_arn    = module.rds.db_secret_arn
  redis_secret_arn = module.redis.redis_secret_arn
  secret_arns      = [module.rds.db_secret_arn, module.redis.redis_secret_arn]

  backend_desired_count = 2
  backend_min_count     = 2
  backend_max_count     = 6

  frontend_desired_count = 1
  log_retention_days     = 14
  tags                   = local.tags
}

module "cloudwatch" {
  source                  = "../../modules/cloudwatch"
  name                    = local.name
  ecs_cluster_name        = module.ecs.cluster_name
  backend_service_name    = module.ecs.backend_service_name
  frontend_service_name   = module.ecs.frontend_service_name
  backend_log_group_name  = module.ecs.backend_log_group_name
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.backend_tg_arn_suffix
  rds_instance_identifier = module.rds.db_instance_identifier
  redis_cluster_id        = module.redis.replication_group_id
  tags                    = local.tags
}
