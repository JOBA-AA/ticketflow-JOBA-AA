locals {
  services = ["auth", "tickets", "orders", "payments", "expiration", "client"]
}

resource "aws_ecr_repository" "ticketflow" {
  for_each             = toset(local.services)
  name                 = "ticketflow-${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "ticketflow-${each.key}"
  }
}

resource "aws_ecr_lifecycle_policy" "ticketflow" {
  for_each   = toset(local.services)
  repository = aws_ecr_repository.ticketflow[each.key].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}