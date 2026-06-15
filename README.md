# TicketFlow

A microservices ticket marketplace built with Node.js/TypeScript and Next.js, deployed via a full DevOps pipeline on Kubernetes and AWS.

## Services

| Service | Language | Role |
|---|---|---|
| auth | Node/TypeScript | User signup, signin, JWT issuance |
| tickets | Node/TypeScript | Create and update ticket listings |
| orders | Node/TypeScript | Reserve tickets, manage order lifecycle |
| payments | Node/TypeScript | Stripe payment processing |
| expiration | Node/TypeScript | Order expiry via Redis/Bull queue |
| client | Next.js | Server-side rendered frontend |

Services communicate asynchronously via **NATS Streaming**. Each backend service has its own **MongoDB** instance.



## Prerequisites

- Docker Desktop (Kubernetes enabled)
- Node.js 18+
- kubectl
- Terraform 1.0+
- AWS CLI
- Jenkins



## Deliverables

| # | Deliverable | Status |
|---|---|---|
| 1 | Dockerfiles — multi-stage builds for all 6 services | ✅ |
| 2 | Docker Compose — full stack with nginx router | ✅ |
| 3 | Kubernetes manifests — deployments, services, ingress | ✅ |
| 4 | Jenkins CI/CD pipeline — build, push, deploy on main | ✅ |
| 5 | Terraform — VPC, EKS, ECR, Secrets Manager on AWS | ✅ |



## Deliverable 1 — Dockerfiles

All backend services use a two-stage build — TypeScript compiled in the builder stage, only production output copied to the runner stage. A non-root user is created for security.

```bash
# Build individual service
docker build -t ticketflow-auth ./auth
docker build -t ticketflow-tickets ./tickets
docker build -t ticketflow-orders ./orders
docker build -t ticketflow-payments ./payments
docker build -t ticketflow-expiration ./expiration
docker build -t ticketflow-client ./client
```



## Deliverable 2 — Docker Compose

Runs the full stack locally. An nginx router replicates the Kubernetes ingress — routing `/api/users`, `/api/tickets`, `/api/orders`, and `/api/payments` to the correct services.

```bash
docker compose up
# App at http://localhost:3000
```



## Deliverable 3 — Kubernetes Manifests

All manifests are in `infra/k8s/`. Secrets must be created imperatively and are never stored in manifest files.

```bash
# Create secrets
kubectl create secret generic jwt-secret --from-literal=JWT_KEY=your-secret
kubectl create secret generic stripe-secret --from-literal=STRIPE_KEY=sk_test_key

# Install ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Deploy everything
kubectl apply -f infra/k8s/

# Add hosts entry (run CMD as Administrator)
echo 127.0.0.1 ticketflow.local >> C:\Windows\System32\drivers\etc\hosts

# App at http://ticketflow.local
```



## Deliverable 4 — Jenkins CI/CD Pipeline

Declarative pipeline defined in `Jenkinsfile`. Stages run in order: checkout → lint/test (parallel) → build images → push to Docker Hub → deploy to Kubernetes (main branch only). Images are tagged with the first 7 characters of the Git commit SHA.

**Required Jenkins credentials:**
- `github-credentials` — GitHub username + personal access token
- `docker-hub-credentials` — Docker Hub username + password



## Deliverable 5 — Terraform

Provisions the full AWS infrastructure. Remote state is stored in S3 with DynamoDB locking to prevent concurrent applies.

**Resources provisioned:**
- VPC with 2 public + 2 private subnets across 2 AZs
- Internet gateway + 2 NAT gateways
- EKS cluster (Kubernetes 1.32) with managed node group (2× t3.medium)
- 6 ECR repositories with image scanning and lifecycle policy (keep last 10 images)
- AWS Secrets Manager entries for JWT and Stripe keys

```bash
cd infra/terraform
terraform init
terraform plan
terraform apply
```



## Project Structure

ticketflow-JOBA-AA/

├── auth/

├── tickets/

├── orders/

├── payments/

├── expiration/

├── client/

├── infra/

│   ├── k8s/            # Kubernetes manifests

│   └── terraform/      # Terraform IaC

├── docker-compose.yml

├── nginx.conf

├── Jenkinsfile

└── README.md




## Stack

Docker · Kubernetes · Jenkins · Terraform · AWS EKS · AWS ECR · MongoDB · NATS Streaming · Redis



*TicketFlow DevOps Capstone — Loreon Learning*