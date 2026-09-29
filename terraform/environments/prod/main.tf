###############################################################################
# Prod Environment — main.tf
# Same modules as dev but with production-grade sizing and HA settings.
###############################################################################

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "url-shortener-tf-state" # create this bucket first
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "url-shortener-tf-locks"
    encrypt        = true
  }
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

data "aws_caller_identity" "current" {}

module "vpc" {
  source   = "../../modules/vpc"
  name     = local.name
  vpc_cidr = var.vpc_cidr
  tags     = local.tags
}

module "ecr" {
  source          = "../../modules/ecr"
  name            = var.project
  max_image_count = 20
  tags            = local.tags
}

module "alb" {
  source                     = "../../modules/alb"
  name                       = local.name
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  enable_deletion_protection = true
  tags                       = local.tags
}

module "rds" {
  source                = "../../modules/rds"
  name                  = local.name
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_sg_id             = module.ecs.ecs_tasks_sg_id
  db_password           = var.db_password
  instance_class        = "db.t3.small"
  allocated_storage     = 50
  multi_az              = true # HA: standby in a second AZ
  deletion_protection   = true
  backup_retention_days = 14
  tags                  = local.tags
}

module "redis" {
  source             = "../../modules/redis"
  name               = local.name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  ecs_sg_id          = module.ecs.ecs_tasks_sg_id
  node_type          = "cache.t3.small"
  num_cache_clusters = 2 # 1 primary + 1 replica, automatic failover
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

  backend_image  = "${module.ecr.backend_repository_url}:latest"
  frontend_image = "${module.ecr.frontend_repository_url}:latest"

  db_secret_arn    = module.rds.db_secret_arn
  redis_secret_arn = module.redis.redis_secret_arn
  secret_arns      = [module.rds.db_secret_arn, module.redis.redis_secret_arn]

  backend_cpu           = 512
  backend_memory        = 1024
  backend_desired_count = 2
  backend_min_count     = 2
  backend_max_count     = 10

  frontend_cpu           = 256
  frontend_memory        = 512
  frontend_desired_count = 2

  log_retention_days = 90
  tags               = local.tags
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
