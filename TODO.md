# TicketFlow DevOps Implementation Checklist

## Deliverable 1: Dockerfiles
- [ ] Create a multi-stage `Dockerfile` for the `auth` service.
- [ ] Create a multi-stage `Dockerfile` for the `tickets` service.
- [ ] Create a multi-stage `Dockerfile` for the `orders` service.
- [ ] Create a multi-stage `Dockerfile` for the `payments` service.
- [ ] Create a multi-stage `Dockerfile` for the `expiration` service.
- [ ] Create a multi-stage `Dockerfile` for the `client` (Next.js) service.
- [ ] Ensure all images are based on `node:18-alpine` or smaller.
- [ ] Configure all containers to run as a non-root user.
- [ ] Expose correct ports in each configuration.
- [ ] Optimize layer caching by segregating dependency installations from the source copy.

## Deliverable 2: Docker Compose (Local Validation)
- [ ] Create the `docker-compose.yml` file.
- [ ] Add all 6 main microservices.
- [ ] Define four MongoDB instances (for `auth`, `tickets`, `orders`, and `payments`).
- [ ] Define a Redis instance for the `expiration` queue.
- [ ] Define the NATS Streaming Server instance.
- [ ] Properly wire configuration environments (MONGO_URI, NATS_URL, JWT_KEY, etc.) between services.
- [ ] Publish the client service on port `3000` locally.
- [ ] Validate `docker compose up --build` works correctly.

## Deliverable 3: Kubernetes Manifests
- [ ] Setup `infra/k8s/` directory.
- [ ] Create `Deployment` & `ClusterIP Service` manifests for all six microservices.
- [ ] Create `Deployment` & `ClusterIP Service` + `PersistentVolumeClaim` manifests for all 4 MongoDB databases.
- [ ] Create `nats-depl.yaml` for the NATS Streaming Server.
- [ ] Create `expiration-redis-depl.yaml` for Redis.
- [ ] Create `ingress-srv.yaml` using nginx Ingress for traffic routing.
- [ ] Declare `requests` and `limits` for CPU and memory across all Deployments.
- [ ] Use `fieldRef` for `NATS_CLIENT_ID` in event-driven pods.
- [ ] Prepare Secrets for `JWT_KEY` and `STRIPE_KEY` (Do NOT commit secret strings to repository).

## Deliverable 4: Jenkins CI/CD Pipeline
- [ ] Create a `Jenkinsfile` using a declarative pipeline block.
- [ ] Define parallel linting and test stages.
- [ ] Define image build stage.
- [ ] Push images using the short Git commit SHA tag.
- [ ] Update running K8s cluster deployments.
- [ ] Set deploy stage logic to only run for the `main` branch.
- [ ] Setup cleanup step to avoid broken images in registry.

## Deliverable 5: Terraform Infrastructure
- [ ] Setup `infra/terraform/` directory.
- [ ] Create variables infrastructure via `variables.tf`.
- [ ] Configure `main.tf` using S3 with DynamoDB state locking.
- [ ] Create VPC infrastructure config (`vpc.tf`): 2 public + 2 private subnets across 2 AZs, NAT Gateways.
- [ ] Create EKS infra config (`eks.tf`): Kubernetes 1.28 cluster, `t3.medium` managed node group (min 2, max 5).
- [ ] Create ECR repositories config (`ecr.tf`): Repositories with image scanning enabled and retention policy (last 10).
- [ ] Create AWS Secrets Manager entries config (`secrets.tf`) for `JWT_KEY` and `STRIPE_KEY`.
- [ ] Add Node IAM roles allowing ECR read permissions.
- [ ] Ensure all TF resources are tagged with `Project`, `Environment`, and `ManagedBy = Terraform`.

## Deliverable 6: Version Control
- [ ] Check / establish standard `.gitignore`.
- [ ] Initiate proper branching (GitFlow).
- [ ] Ensure all further modifications use Conventional Commits.

## Deliverable 7: README Updates
- [ ] Document architecture structure (incorporate services, databases, ingress, NATS).
- [ ] Outline prerequisites and local startup via Docker Compose.
- [ ] Add AWS & Terraform first-time production deployment commands.
- [ ] Explain Jenkins deployment CI/CD workflow.
- [ ] Outline all environment variables reference.
- [ ] Present at least 5 troubleshooting / failure resolution scenarios.
