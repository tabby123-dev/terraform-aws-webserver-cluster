output "alb_dns_name" {
  value       = aws_lb.web_lb.dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value       = aws_autoscaling_group.web_asg.name
  description = "The name of the Auto Scaling Group"
}