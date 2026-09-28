###############################################################################
# CloudWatch Module — main.tf
# Creates: Metric filters, SNS topic for alarms, CloudWatch alarms for ECS/ALB/RDS,
#          and a unified operational CloudWatch Dashboard.
###############################################################################

# ── SNS Topic for Alarms ──────────────────────────────────────────────────────
resource "aws_sns_topic" "alarms" {
  name = "${var.name}-cw-alarms-topic"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ── CloudWatch Metric Filters (Backend Logs) ──────────────────────────────────
# 1. Request Latency Metric Filter (extracts duration_ms from JSON log events)
resource "aws_cloudwatch_log_metric_filter" "request_latency" {
  name           = "${var.name}-request-latency-filter"
  pattern        = "{ $.duration_ms = * }"
  log_group_name = var.backend_log_group_name

  metric_transformation {
    name      = "RequestLatencyMs"
    namespace = "URLShortener/Backend"
    value     = "$.duration_ms"
    unit      = "Milliseconds"
  }
}

# 2. HTTP 5xx Error Count Metric Filter
resource "aws_cloudwatch_log_metric_filter" "http_5xx_errors" {
  name           = "${var.name}-http-5xx-filter"
  pattern        = "{ $.status_code >= 500 }"
  log_group_name = var.backend_log_group_name

  metric_transformation {
    name      = "Http5xxCount"
    namespace = "URLShortener/Backend"
    value     = "1"
    unit      = "Count"
  }
}

# 3. Cache Hit Count Metric Filter
resource "aws_cloudwatch_log_metric_filter" "cache_hits" {
  name           = "${var.name}-cache-hits-filter"
  pattern        = "{ $.event = \"cache_hit\" }"
  log_group_name = var.backend_log_group_name

  metric_transformation {
    name      = "CacheHitCount"
    namespace = "URLShortener/Backend"
    value     = "1"
    unit      = "Count"
  }
}

# 4. Cache Miss Count Metric Filter
resource "aws_cloudwatch_log_metric_filter" "cache_misses" {
  name           = "${var.name}-cache-misses-filter"
  pattern        = "{ $.event = \"cache_miss\" }"
  log_group_name = var.backend_log_group_name

  metric_transformation {
    name      = "CacheMissCount"
    namespace = "URLShortener/Backend"
    value     = "1"
    unit      = "Count"
  }
}

# ── CloudWatch Alarms ─────────────────────────────────────────────────────────

# 1. ECS Backend High CPU Alarm (> 80% for 2 consecutive 60s periods)
resource "aws_cloudwatch_metric_alarm" "backend_cpu_high" {
  alarm_name          = "${var.name}-backend-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when ECS backend service CPU utilization exceeds 80%"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.backend_service_name
  }

  tags = var.tags
}

# 2. ECS Backend High Memory Alarm (> 80% for 2 consecutive 60s periods)
resource "aws_cloudwatch_metric_alarm" "backend_memory_high" {
  alarm_name          = "${var.name}-backend-high-memory"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when ECS backend service memory utilization exceeds 80%"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.backend_service_name
  }

  tags = var.tags
}

# 3. ALB High 5xx Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  count               = var.alb_arn_suffix != "" ? 1 : 0
  alarm_name          = "${var.name}-alb-high-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alarm when ALB target 5xx error count exceeds 5 in 5 minutes"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = var.tags
}

# 4. High Request Latency Alarm (p99 > 500ms)
resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "${var.name}-high-request-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RequestLatencyMs"
  namespace           = "URLShortener/Backend"
  period              = 60
  extended_statistic  = "p99"
  threshold           = 500
  alarm_description   = "Alarm when backend request latency (p99) exceeds 500ms"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  tags = var.tags
}

# 5. RDS High CPU Alarm (> 80%)
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count               = var.rds_instance_identifier != "" ? 1 : 0
  alarm_name          = "${var.name}-rds-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when RDS CPU utilization exceeds 80%"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }

  tags = var.tags
}

# ── Operational CloudWatch Dashboard ──────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.backend_service_name, "ClusterName", var.ecs_cluster_name, { "label" = "Backend CPU" }],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", var.backend_service_name, "ClusterName", var.ecs_cluster_name, { "label" = "Backend Memory" }],
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.frontend_service_name, "ClusterName", var.ecs_cluster_name, { "label" = "Frontend CPU" }],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", var.frontend_service_name, "ClusterName", var.ecs_cluster_name, { "label" = "Frontend Memory" }]
          ]
          period = 60
          stat   = "Average"
          region = "ap-south-1"
          title  = "ECS Cluster Resource Utilization (%)"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["URLShortener/Backend", "RequestLatencyMs", { "stat" = "p50", "label" = "p50 Latency (ms)" }],
            ["URLShortener/Backend", "RequestLatencyMs", { "stat" = "p95", "label" = "p95 Latency (ms)" }],
            ["URLShortener/Backend", "RequestLatencyMs", { "stat" = "p99", "label" = "p99 Latency (ms)" }]
          ]
          period = 60
          region = "ap-south-1"
          title  = "Backend Request Latency (ms)"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["URLShortener/Backend", "CacheHitCount", { "stat" = "Sum", "label" = "Cache Hits" }],
            ["URLShortener/Backend", "CacheMissCount", { "stat" = "Sum", "label" = "Cache Misses" }]
          ]
          period = 60
          region = "ap-south-1"
          title  = "Redis Cache Hit vs Miss Count"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["URLShortener/Backend", "Http5xxCount", { "stat" = "Sum", "label" = "HTTP 5xx Errors", "color" = "#d62728" }]
          ]
          period = 60
          region = "ap-south-1"
          title  = "Application HTTP 5xx Errors"
        }
      }
    ]
  })
}
