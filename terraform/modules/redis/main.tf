###############################################################################
# Redis Module — main.tf
# Creates: ElastiCache Redis cluster (cluster mode disabled, 1 primary +
#          optional replica), subnet group, security group (ECS only),
#          and Secrets Manager secret for the connection URL.
###############################################################################

# ── Security Group: Redis ─────────────────────────────────────────────────────
resource "aws_security_group" "redis" {
  name        = "${var.name}-redis-sg"
  description = "Redis - allow ingress from ECS tasks only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.ecs_sg_id]
    description     = "Redis from ECS tasks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-redis-sg" })
}

# ── ElastiCache Subnet Group ──────────────────────────────────────────────────
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.name}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}

# ── ElastiCache Parameter Group ───────────────────────────────────────────────
resource "aws_elasticache_parameter_group" "main" {
  name   = "${var.name}-redis7"
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru" # evict LRU when memory full
  }

  tags = var.tags
}

# ── ElastiCache Replication Group ────────────────────────────────────────────
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.name}-redis"
  description          = "Redis cache for ${var.name}"

  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_clusters # 1 = no replica, 2 = 1 replica
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.main.name
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false # set true if you add TLS auth token

  automatic_failover_enabled = var.num_cache_clusters > 1
  multi_az_enabled           = var.num_cache_clusters > 1

  snapshot_retention_limit = 1
  snapshot_window          = "05:00-06:00"
  maintenance_window       = "sun:06:00-sun:07:00"

  apply_immediately = true

  tags = merge(var.tags, { Name = "${var.name}-redis" })
}

# ── Secrets Manager: Redis URL ────────────────────────────────────────────────
resource "aws_secretsmanager_secret" "redis" {
  name                    = "${var.name}/redis-url"
  description             = "Redis connection URL for ${var.name}"
  recovery_window_in_days = 7
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id     = aws_secretsmanager_secret.redis.id
  secret_string = "redis://${aws_elasticache_replication_group.main.primary_endpoint_address}:6379/0"
}
