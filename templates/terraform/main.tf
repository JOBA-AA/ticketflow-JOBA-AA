# TODO: Configure Terraform required version and required providers
terraform {
  required_version = ">= TODO_MIN_VERSION"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> TODO_VERSION"
    }
  }

  # TODO: Configure the Terraform backend for state management
  # HINT: Use AWS S3 + DynamoDB for remote state (recommended for teams)
  # HINT: Uncomment and fill in the backend configuration below
  # backend "s3" {
  #   bucket         = "TODO_BUCKET_NAME"
  #   key            = "terraform/ticketing-app/terraform.tfstate"
  #   region         = "TODO_REGION"
  #   dynamodb_table = "TODO_TABLE_NAME"  # For state locking
  #   encrypt        = true
  # }
}

# TODO: Configure the AWS provider
# HINT: This tells Terraform which AWS account and region to use
provider "aws" {
  region = var.aws_region

  # TODO: Optional - Add default tags to all resources
  # HINT: This is useful for cost tracking and organization
  # default_tags {
  #   tags = {
  #     Environment = var.environment
  #     Project     = "ticketing-app"
  #     ManagedBy   = "Terraform"
  #   }
  # }
}

# TODO: Consider using a separate provider for Kubernetes operations
# HINT: This is useful if you need to manage Kubernetes resources from Terraform
# provider "kubernetes" {
#   host                   = TODO
#   cluster_ca_certificate = TODO
#   token                  = TODO
# }
