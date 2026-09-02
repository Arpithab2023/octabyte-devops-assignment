terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state — S3 backend with DynamoDB locking.
  # Create the bucket + table once, manually or via a bootstrap script,
  # BEFORE running `terraform init` (backend config can't be templated with variables).
  backend "s3" {
    bucket         = "octabyte-tfstate-<UNIQUE_SUFFIX>"
    key            = "app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "octabyte-tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
