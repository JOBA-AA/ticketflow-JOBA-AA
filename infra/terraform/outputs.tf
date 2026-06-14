output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.ticketflow.name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.ticketflow.endpoint
}

output "cluster_certificate" {
  description = "Base64 encoded certificate for cluster authentication"
  value       = aws_eks_cluster.ticketflow.certificate_authority[0].data
  sensitive   = true
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.ticketflow.id
}

output "ecr_repository_urls" {
  description = "ECR repository URLs for all services"
  value       = { for k, v in aws_ecr_repository.ticketflow : k => v.repository_url }
}