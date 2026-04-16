# TODO: Define all input variables for the Terraform configuration
# HINT: Variables make your infrastructure reusable and configurable

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"
  # TODO: Consider using a required value (remove default) or change to your preferred region
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  # TODO: Set a default value or mark as required
  # default = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ticketing-app"
}

# ========================================
# VPC Variables
# ========================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  # TODO: Define a CIDR block (e.g., "10.0.0.0/16")
  default = "TODO_VPC_CIDR"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  # TODO: Specify which AZs to use (e.g., ["us-east-1a", "us-east-1b"])
  default = ["TODO_AZ1", "TODO_AZ2"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  # TODO: Define private subnet ranges (e.g., ["10.0.1.0/24", "10.0.2.0/24"])
  default = ["TODO_PRIVATE_SUBNET_1", "TODO_PRIVATE_SUBNET_2"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  # TODO: Define public subnet ranges
  default = ["TODO_PUBLIC_SUBNET_1", "TODO_PUBLIC_SUBNET_2"]
}

# ========================================
# EKS Cluster Variables
# ========================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "ticketing-app-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  # TODO: Specify a Kubernetes version (e.g., "1.27", "1.28")
  default = "TODO_K8S_VERSION"
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 2
  # TODO: Adjust based on your expected workload
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 5
  # TODO: Adjust auto-scaling limits as needed
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
  # TODO: Choose appropriate instance types (e.g., t3.medium, t3.large, m5.large)
}

# ========================================
# ECR Variables
# ========================================

variable "ecr_repository_names" {
  description = "List of ECR repository names for microservices"
  type        = list(string)
  default     = ["auth", "tickets", "orders", "payments", "expiration", "client"]
  # TODO: Ensure all service names are listed
}

variable "ecr_image_tag_mutability" {
  description = "Enable tag immutability for ECR images"
  type        = string
  default     = "IMMUTABLE"
  # TODO: Consider IMMUTABLE for production, MUTABLE for development
}

# ========================================
# Optional Variables
# ========================================

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet outbound traffic"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "ticketing-app"
    # TODO: Add custom tags as needed
  }
}
