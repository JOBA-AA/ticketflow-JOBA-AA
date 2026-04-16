# TODO: Create a Virtual Private Cloud (VPC) for your infrastructure
# HINT: The VPC is the foundation of your AWS networking

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  # TODO: Enable DNS hostnames for EKS
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-vpc"
    }
  )
}

# ========================================
# Public Subnets (for NAT Gateway, Ingress)
# ========================================

# TODO: Create public subnets in each availability zone
# HINT: Public subnets contain resources accessible from the internet
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  # TODO: Enable auto-assign public IPv4 addresses
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-subnet-${count.index + 1}"
      Type = "Public"
    }
  )
}

# ========================================
# Private Subnets (for EKS nodes)
# ========================================

# TODO: Create private subnets in each availability zone
# HINT: Private subnets host your EKS nodes and databases
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-subnet-${count.index + 1}"
      Type = "Private"
    }
  )
}

# ========================================
# Internet Gateway
# ========================================

# TODO: Create an Internet Gateway for public subnet traffic
# HINT: IGW allows traffic between the VPC and the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

# ========================================
# Elastic IPs for NAT Gateways
# ========================================

# TODO: Create Elastic IPs for NAT Gateways
# HINT: NAT Gateways allow private subnets to access the internet
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? length(var.availability_zones) : 0
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-eip-${count.index + 1}"
    }
  )
}

# ========================================
# NAT Gateways
# ========================================

# TODO: Create NAT Gateways in public subnets
# HINT: NAT Gateways enable private subnets to reach the internet for outbound traffic
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? length(var.availability_zones) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.main]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nat-${count.index + 1}"
    }
  )
}

# ========================================
# Route Tables
# ========================================

# TODO: Create route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # TODO: Add route to Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-rt"
    }
  )
}

# TODO: Associate public route table with public subnets
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# TODO: Create route tables for private subnets
# HINT: Each private subnet should have its own route table pointing to a NAT Gateway
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? length(var.availability_zones) : 0
  vpc_id = aws_vpc.main.id

  # TODO: Add route to NAT Gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-rt-${count.index + 1}"
    }
  )
}

# TODO: Associate private route tables with private subnets
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index % length(aws_route_table.private)].id
}

# ========================================
# Security Groups
# ========================================

# TODO: Create a security group for EKS nodes
# HINT: Security groups control inbound and outbound traffic
resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-eks-nodes"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  # TODO: Define ingress rules (inbound traffic)
  # TODO: Define egress rules (outbound traffic)

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-eks-nodes-sg"
    }
  )
}

# TODO: Create a security group for the ALB (Application Load Balancer)
# HINT: The ALB routes traffic to your microservices
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # TODO: Allow HTTP and HTTPS inbound
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # TODO: Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-alb-sg"
    }
  )
}
