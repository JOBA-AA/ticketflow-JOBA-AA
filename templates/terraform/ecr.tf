# TODO: Create ECR repositories for your microservices
# HINT: ECR (Elastic Container Registry) stores your Docker images

resource "aws_ecr_repository" "services" {
  # TODO: Create one repository for each microservice
  # HINT: for_each allows you to create multiple resources from a list
  for_each = toset(var.ecr_repository_names)

  name                 = each.key
  image_tag_mutability = var.ecr_image_tag_mutability

  # TODO: Enable image scanning for security vulnerabilities (optional)
  # image_scanning_configuration {
  #   scan_on_push = true
  # }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${each.key}"
      Service = each.key
    }
  )
}

# ========================================
# ECR Lifecycle Policies (Optional)
# ========================================

# TODO: Define lifecycle policies to automatically clean up old images
# HINT: Lifecycle policies help manage storage costs and keep registries clean
resource "aws_ecr_lifecycle_policy" "services" {
  for_each = aws_ecr_repository.services

  repository = each.value.name

  # TODO: Configure the lifecycle policy rule
  # HINT: Example policy keeps only the latest 10 images
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only latest 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ========================================
# ECR Repository Outputs
# ========================================

# TODO: Output the repository URLs for use in deployments
output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    for name, repo in aws_ecr_repository.services :
    name => repo.repository_url
  }
}

# TODO: Output the repository registry IDs
output "ecr_registry_id" {
  description = "ECR registry ID (AWS account ID)"
  value       = data.aws_caller_identity.current.account_id
}

# ========================================
# Data Source for Current AWS Account
# ========================================

# TODO: Get the current AWS account ID for use in outputs and policies
data "aws_caller_identity" "current" {}
