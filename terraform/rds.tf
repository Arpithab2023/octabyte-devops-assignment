resource "random_password" "db" {
  length  = 20
  special = false # avoid chars that need escaping in connection strings
}

# Secret management: DB credentials stored in Secrets Manager, never in code/state output
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_name}/${var.environment}/db-credentials"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    host     = aws_db_instance.postgres.address
    port     = 5432
    dbname   = var.db_name
  })
}

resource "aws_db_instance" "postgres" {
  identifier     = "${var.project_name}-${var.environment}-pg"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  storage_type           = "gp3"
  storage_encrypted      = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  multi_az = var.db_multi_az

  # Backup strategy
  backup_retention_period = var.db_backup_retention_days
  backup_window            = "17:00-18:00" # UTC, low-traffic window
  maintenance_window        = "sun:19:00-sun:20:00"
  copy_tags_to_snapshot     = true
  deletion_protection       = false # set true for real production
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-${var.environment}-final-snapshot"

  performance_insights_enabled = true

  tags = { Name = "${var.project_name}-${var.environment}-pg" }
}
