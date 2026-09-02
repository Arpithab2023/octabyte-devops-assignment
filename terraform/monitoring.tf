resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ---------- Infra metrics: ECS CPU/Memory ----------
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_mem_high" {
  alarm_name          = "${var.project_name}-ecs-mem-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# ---------- App metrics: ALB error rate / latency ----------
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "${var.project_name}-alb-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1 # seconds
  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# ---------- Database metrics ----------
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.identifier
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${var.project_name}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2000000000 # 2 GB in bytes
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.identifier
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# ---------- Dashboard 1: Infrastructure overview ----------
resource "aws_cloudwatch_dashboard" "infra" {
  dashboard_name = "${var.project_name}-infrastructure"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6,
        properties = {
          title   = "ECS CPU & Memory Utilization"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.app.name],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.app.name]
          ]
          period = 60, stat = "Average", region = var.aws_region
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6,
        properties = {
          title   = "RDS CPU, Storage, Connections"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.postgres.identifier],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.postgres.identifier],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.postgres.identifier]
          ]
          period = 60, stat = "Average", region = var.aws_region
        }
      }
    ]
  })
}

# ---------- Dashboard 2: Application health ----------
resource "aws_cloudwatch_dashboard" "app_health" {
  dashboard_name = "${var.project_name}-application-health"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6,
        properties = {
          title   = "Request Rate & Error Rate (ALB)"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.app.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", aws_lb.app.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.app.arn_suffix]
          ]
          period = 60, stat = "Sum", region = var.aws_region
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6,
        properties = {
          title   = "Target Response Time (p50/p99)"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.app.arn_suffix, { stat = "p50" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.app.arn_suffix, { stat = "p99" }]
          ]
          period = 60, region = var.aws_region
        }
      },
      {
        type = "log", x = 0, y = 6, width = 24, height = 6,
        properties = {
          title  = "Recent Application Errors"
          query  = "SOURCE '${aws_cloudwatch_log_group.app.name}' | fields @timestamp, @message | filter @message like /(?i)(error|exception)/ | sort @timestamp desc | limit 50"
          region = var.aws_region
          view   = "table"
        }
      }
    ]
  })
}
