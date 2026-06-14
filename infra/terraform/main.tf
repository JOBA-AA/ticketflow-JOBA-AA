terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "ticketflow-tfstate-919006483855"
    key            = "ticketflow/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ticketflow-tflock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ticketflow"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}