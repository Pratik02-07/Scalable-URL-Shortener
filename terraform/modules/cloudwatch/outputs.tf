output "sns_topic_arn" {
  description = "ARN of the SNS alarm topic"
  value       = aws_sns_topic.alarms.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "backend_cpu_alarm_arn" {
  description = "ARN of the Backend CPU alarm"
  value       = aws_cloudwatch_metric_alarm.backend_cpu_high.arn
}
