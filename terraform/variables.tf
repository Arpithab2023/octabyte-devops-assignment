variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix/tag resources"
  type        = string
  default     = "octabyte"
}

variable "environment" {
  description = "Environment name (staging/production)"
  type        = string
  default     = "staging"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across"
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private (app) subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "db_subnet_cidrs" {
  description = "CIDRs for private DB subnets"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "container_image" {
  description = "Docker image (ECR URI:tag) to run"
  type        = string
  default     = "public.ecr.aws/docker/library/nginx:latest" # placeholder until first CI build
}

variable "container_port" {
  description = "Port the app listens on inside the container"
  type        = number
  default     = 8080
}

variable "app_desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 2
}

variable "app_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "app_memory" {
  description = "Fargate task memory (MB)"
  type        = number
  default     = 512
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.3"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "appadmin"
  sensitive   = true
}

variable "db_allocated_storage" {
  description = "Allocated storage (GB) for RDS"
  type        = number
  default     = 20
}

variable "db_multi_az" {
  description = "Whether to enable Multi-AZ for RDS (set true for production)"
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  description = "Automated backup retention period"
  type        = number
  default     = 7
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = "devops-alerts@example.com"
}
