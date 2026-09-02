output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "alb_dns_name" {
  description = "Public URL of the application (put behind Route53 in production)"
  value       = aws_lb.app.dns_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "rds_endpoint" {
  value     = aws_db_instance.postgres.address
  sensitive = false
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "alb_access_logs_bucket" {
  description = "S3 bucket receiving centralized ALB access logs"
  value       = aws_s3_bucket.alb_logs.id
}

output "cloudwatch_dashboards" {
  value = [
    aws_cloudwatch_dashboard.infra.dashboard_name,
    aws_cloudwatch_dashboard.app_health.dashboard_name
  ]
}
