# DevOps Capstone Project Templates

This directory contains skeleton templates for the Ticketing App microservices capstone project. Each template includes TODO comments to guide you through the implementation without giving away the full solution.

## Template Files

### Docker & Containerization

- **Dockerfile.backend-template** - Multi-stage Dockerfile for TypeScript/Node.js backend services (auth, tickets, orders, payments, expiration)
  - Stage 1: Build stage (install deps, compile TypeScript)
  - Stage 2: Production stage (minimal image with compiled JS)
  - TODOs for base images, non-root user, layer caching

- **Dockerfile.client-template** - Next.js client Dockerfile
  - Build stage for compiling Next.js
  - Production stage with optimized image
  - TODOs for build script setup and standalone output

- **docker-compose.template.yml** - Local development environment
  - All microservices (auth, tickets, orders, payments, expiration, client)
  - Infrastructure services (MongoDB instances, Redis, NATS)
  - TODOs for build contexts, port mappings, environment variables

### Kubernetes Orchestration

- **k8s-deployment.template.yaml** - Generic Deployment + Service pattern
  - Deployment with container configuration
  - ClusterIP Service for internal communication
  - TODOs for image URIs, env vars, resource limits, health checks

- **k8s-ingress.template.yaml** - Ingress routing configuration
  - Routes for all microservices (/api/users, /api/tickets, /api/orders, /api/payments)
  - Default route to Next.js client
  - TODOs for domain setup and TLS

### CI/CD Pipeline

- **Jenkinsfile.template** - Declarative Jenkins pipeline
  - Stages: Checkout → Lint → Test → Build Images → Push to Registry → Deploy
  - Parallel execution for lint and test stages
  - TODOs for build contexts, registry credentials, deployment commands

### Infrastructure as Code (Terraform)

Located in `terraform/` subdirectory:

- **main.tf** - Terraform provider configuration
  - AWS provider setup
  - Backend configuration for state management (S3 + DynamoDB)

- **variables.tf** - Input variables
  - AWS region, environment name
  - VPC CIDR blocks and subnets
  - EKS cluster configuration
  - ECR repository names
  - Deployment options (NAT gateways, instance types, etc.)

- **vpc.tf** - VPC and networking
  - VPC with public and private subnets
  - Internet Gateway and NAT Gateways
  - Route tables and security groups
  - TODOs for CIDR blocks and security rules

- **eks.tf** - Kubernetes cluster
  - EKS cluster definition
  - Node group configuration
  - IAM roles and policies for cluster and nodes
  - Outputs for cluster endpoint and security groups

- **ecr.tf** - Container registry
  - ECR repositories for each microservice
  - Lifecycle policies for image cleanup
  - Outputs for repository URLs

- **outputs.tf** - Infrastructure outputs
  - VPC information (IDs, CIDR blocks, subnet IDs)
  - EKS cluster details (endpoint, version, security groups)
  - ECR registry information
  - kubectl configuration command

## How to Use These Templates

1. **Copy templates to your project** - Don't modify the original templates; copy them to your service directories
2. **Read the TODO comments carefully** - Each TODO explains what needs to be filled in
3. **Check the HINT comments** - Hints provide guidance without revealing the full solution
4. **Work incrementally** - Start with Docker setup, then move to Docker Compose, then Kubernetes, then Terraform

## Service Architecture

Your project includes:

**Backend Services** (all TypeScript/Node.js, port 3000):
- auth-service
- tickets-service
- orders-service
- payments-service
- expiration-service (no HTTP server)

**Frontend Service** (Next.js):
- client (web UI)

**Infrastructure**:
- MongoDB (separate instance per backend service)
- Redis
- NATS Streaming (message broker)

## Development Workflow

1. Use `docker-compose.template.yml` to run everything locally during development
2. Create individual Dockerfiles for each service using the backend/client templates
3. Deploy to Kubernetes using the deployment and ingress templates
4. Manage cloud infrastructure with Terraform templates

## Key Learning Points

- **Multi-stage Docker builds**: Reduce image size by separating build and runtime stages
- **Environment configuration**: Use env vars and Kubernetes Secrets for configuration management
- **Kubernetes patterns**: Deployments, Services, Ingress for orchestration
- **CI/CD**: Automated testing, building, and deployment with Jenkins
- **Infrastructure as Code**: Terraform manages cloud resources declaratively

## Getting Started Checklist

- [ ] Understand the microservices architecture
- [ ] Create Dockerfiles for each service using templates
- [ ] Set up local development with docker-compose
- [ ] Create Kubernetes manifests for each service
- [ ] Configure Ingress for traffic routing
- [ ] Set up Jenkins pipeline for CI/CD
- [ ] Create Terraform configuration for AWS infrastructure
- [ ] Test deployment in Kubernetes cluster

Good luck with your capstone project!
