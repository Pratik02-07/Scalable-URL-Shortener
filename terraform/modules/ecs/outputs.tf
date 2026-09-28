output "cluster_name" {
  value = aws_ecs_cluster.main.name
}
output "cluster_id" {
  value = aws_ecs_cluster.main.id
}
output "backend_service_name" {
  value = aws_ecs_service.backend.name
}
output "frontend_service_name" {
  value = aws_ecs_service.frontend.name
}
output "ecs_tasks_sg_id" {
  value = aws_security_group.ecs_tasks.id
}
output "task_execution_role_arn" {
  value = aws_iam_role.task_execution.arn
}
output "task_role_arn" {
  value = aws_iam_role.task.arn
}
output "backend_log_group_name" {
  value = aws_cloudwatch_log_group.backend.name
}
