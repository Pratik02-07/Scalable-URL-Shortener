###############################################################################
# ALB Module — main.tf
# Creates: Application Load Balancer (public), target groups for backend
#          and frontend, HTTP listener (with optional HTTPS redirect),
#          and security group for the ALB.
###############################################################################

# ── Security Group: ALB ───────────────────────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Allow HTTP/HTTPS inbound to the ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = merge(var.tags, { Name = "${var.name}-alb-sg" })
}

# ── Application Load Balancer ─────────────────────────────────────────────────
resource "aws_lb" "main" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  access_logs {
    bucket  = var.access_log_bucket
    prefix  = "${var.name}-alb"
    enabled = var.access_log_bucket != ""
  }

  tags = merge(var.tags, { Name = "${var.name}-alb" })
}

# ── Target Group: Backend (FastAPI :8000) ─────────────────────────────────────
resource "aws_lb_target_group" "backend" {
  name        = "${var.name}-backend-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # Fargate uses IP targets

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(var.tags, { Name = "${var.name}-backend-tg" })
}

# ── Target Group: Frontend (Next.js :3000) ────────────────────────────────────
resource "aws_lb_target_group" "frontend" {
  name        = "${var.name}-frontend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(var.tags, { Name = "${var.name}-frontend-tg" })
}

locals {
  use_https = var.certificate_arn != ""
}

# ── HTTP Listener (Port 80) ───────────────────────────────────────────────────
# If certificate_arn is supplied, redirects port 80 -> 443 with HTTP 301.
# Otherwise forwards directly to frontend.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = local.use_https ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = local.use_https ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.frontend.arn
    }
  }
}

# ── HTTPS Listener (Port 443) ──────────────────────────────────────────────────
resource "aws_lb_listener" "https" {
  count             = local.use_https ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Route /api/* and short-redirect paths to backend
resource "aws_lb_listener_rule" "api" {
  listener_arn = local.use_https ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern { values = ["/api/*", "/health", "/ready", "/{proxy+}"] }
  }
}
