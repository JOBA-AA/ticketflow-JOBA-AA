# TODO: Define outputs that display important infrastructure information
# HINT: Outputs are displayed at the end of terraform apply and can be used by other scripts

# ========================================
# VPC Outputs
# ========================================

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "nat_gateway_ips" {
  description = "Elastic IPs of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# ========================================
# EKS Cluster Outputs
# ========================================

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster"
  value       = aws_eks_cluster.main.endpoint
  # TODO: This endpoint is used to configure kubectl
}

output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.main.version
}

output "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "eks_node_group_id" {
  description = "ID of the EKS node group"
  value       = aws_eks_node_group.main.id
}

output "eks_node_group_status" {
  description = "Status of the EKS node group"
  value       = aws_eks_node_group.main.status
}

# ========================================
# ECR Registry Outputs
# ========================================

output "ecr_registry_id" {
  description = "ECR registry ID (AWS account ID)"
  value       = data.aws_caller_identity.current.account_id
  # TODO: Use this for pushing images: aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <registry_id>.dkr.ecr.<region>.amazonaws.com
}

output "ecr_repository_urls" {
  description = "URLs of all ECR repositories"
  value = {
    for name, repo in aws_ecr_repository.services :
    name => repo.repository_url
  }
  # TODO: Use these URLs to tag and push your Docker images
}

# ========================================
# Security Group Outputs
# ========================================

output "eks_nodes_security_group_id" {
  description = "Security group ID for EKS nodes"
  value       = aws_security_group.eks_nodes.id
}

output "alb_security_group_id" {
  description = "Security group ID for Application Load Balancer"
  value       = aws_security_group.alb.id
}

# ========================================
# IAM Role Outputs
# ========================================

output "eks_cluster_iam_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "eks_node_iam_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = aws_iam_role.eks_node_role.arn
}

# ========================================
# Configuration Helper Output
# ========================================

output "configure_kubectl" {
  description = "Command to configure kubectl to use this cluster"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.aws_region}"
  # TODO: Run this command to update your kubectl config
}

# ========================================
# Summary Output
# ========================================

output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    cluster_name    = aws_eks_cluster.main.name
    region          = var.aws_region
    vpc_cidr        = aws_vpc.main.cidr_block
    node_count      = var.node_group_desired_size
    kubernetes_version = aws_eks_cluster.main.version
  }
}
