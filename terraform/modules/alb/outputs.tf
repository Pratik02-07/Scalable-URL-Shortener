output "alb_dns_name" {
  value = aws_lb.main.dns_name
}
output "alb_arn" {
  value = aws_lb.main.arn
}
output "alb_arn_suffix" {
  value = aws_lb.main.arn_suffix
}
output "alb_sg_id" {
  value = aws_security_group.alb.id
}
output "backend_tg_arn" {
  value = aws_lb_target_group.backend.arn
}
output "backend_tg_arn_suffix" {
  value = aws_lb_target_group.backend.arn_suffix
}
output "frontend_tg_arn" {
  value = aws_lb_target_group.frontend.arn
}
output "http_listener_arn" {
  value = aws_lb_listener.http.arn
}
