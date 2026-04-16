# 🎟️ TicketFlow — Cloud-Native Microservices Platform
## DevOps Engineering Capstone | Loreon Learning

---

> **This is your final capstone project. You are not a student reading about DevOps. You are a DevOps Engineer who has just been handed a codebase and told to ship it.**

---

## Scenario

You have joined **TicketFlow**, a startup building a ticket marketplace platform. The development team has handed you a fully written application — six microservices, a React frontend, and a shared library — but they have done **zero DevOps work**.

There are no Dockerfiles. There is no CI/CD pipeline. There is no cloud infrastructure. The app exists only on a developer's laptop.

**Your job is to change that.**

By the end of this capstone, TicketFlow must be running in a production Kubernetes cluster on AWS, built and deployed automatically through a Jenkins pipeline, with all infrastructure provisioned via Terraform. Every decision you make must be version-controlled, reproducible, and documented.

---

## The Application

TicketFlow is a microservices-based e-commerce platform where users can list, purchase, and manage event tickets. The application is already written in TypeScript. **You are not here to write application code.** You are here to containerize it, automate it, and deploy it.

### Services

| Service | Port | Responsibility |
|---|---|---|
| `auth` | 3000 | User registration, login, JWT issuance |
| `tickets` | 3000 | Ticket creation, updates, version locking |
| `orders` | 3000 | Order lifecycle — create, cancel, expire |
| `payments` | 3000 | Stripe payment processing |
| `expiration` | — | Order expiry via Bull job queue + Redis |
| `client` | 3000 | Next.js server-side rendered frontend |

### Inter-Service Communication

Services do **not** call each other directly. All state-changing events flow through a **NATS Streaming Server** event bus. This is the core architectural decision of the platform — understand it before you touch anything.

```
Auth ──────────────────────────────────────────────────────────────┐
Tickets ──── publishes/subscribes ────► NATS Streaming Server ◄─── Orders
Payments ─────────────────────────────────────────────────────────┘
                                             │
                                        Expiration
                                      (listener only)
```

### Shared Library

All services depend on `@ticketflow/common` — a custom npm package that ships:
- Base event interfaces and subjects
- Error handling middleware
- JWT authentication middleware
- Mongoose optimistic concurrency utilities

---

## Your Deliverables

You will submit a **GitHub repository** containing all of the following. Missing deliverables result in an incomplete assessment.

---

### Deliverable 1 — Dockerfiles

**Every service needs a Dockerfile.** The Dockerfiles do not exist. You must write them.

Requirements:
- Use **multi-stage builds**. Your final image must not contain development dependencies or TypeScript source files.
- Base image must be `node:18-alpine` or smaller.
- The process inside the container must **not run as root**. Create a non-root user.
- Each image must expose the correct port.
- Optimise layer caching — dependency installation must be a separate layer from source copying.

The `client` service (Next.js) has a different build process from the backend services. Handle it separately.

> **Hint:** Think about what `npm run build` produces in a TypeScript project and what files you actually need at runtime.

---

### Deliverable 2 — Docker Compose (Local Validation)

Before you touch Kubernetes, prove your images build and run.

Write a `docker-compose.yml` that:
- Builds and runs all six services
- Includes MongoDB instances for `auth`, `tickets`, `orders`, and `payments`
- Includes a Redis instance for `expiration`
- Includes the NATS Streaming Server
- Wires all environment variables correctly between services
- Exposes the `client` service on `localhost:3000`

> **You must be able to run `docker compose up --build` and reach the frontend in a browser before moving on.**

---

### Deliverable 3 — Kubernetes Manifests

The application runs in Kubernetes. Write the manifests in `infra/k8s/`.

You must provide:

| Manifest | What it must contain |
|---|---|
| One `Deployment` + `ClusterIP Service` per microservice | Correct image reference, env vars from Secrets, resource limits |
| One `Deployment` + `ClusterIP Service` per MongoDB instance | Persistent volume claim for data durability |
| `nats-depl.yaml` | NATS Streaming Server deployment |
| `expiration-redis-depl.yaml` | Redis deployment for Bull queue |
| `ingress-srv.yaml` | nginx Ingress routing all external traffic to the correct services |

**Secrets** — JWT signing key and Stripe API key must **never** appear in a manifest file. Store them as Kubernetes Secrets and reference them via `secretKeyRef`.

**Resource limits** — every container must declare `requests` and `limits` for CPU and memory.

---

### Deliverable 4 — Jenkins CI/CD Pipeline

Write a `Jenkinsfile` in the repository root that implements the following pipeline:

```
Checkout → Lint → Test → Build Images → Push to Registry → Deploy to K8s
```

Requirements:
- Use a **declarative pipeline** (`pipeline { }` syntax)
- Lint and test stages must run **in parallel** across all services
- Images must be tagged with the **short Git commit SHA** — never just `latest`
- The **deploy stage must only run on the `main` branch**
- Docker Hub credentials must be stored as a Jenkins credential, never hardcoded
- The pipeline must update the running Kubernetes deployments after pushing new images
- On failure, the pipeline must **not** leave broken images in the registry

> **Document in your README which Jenkins plugins are required and how to configure the pipeline in a fresh Jenkins instance.**

---

### Deliverable 5 — Terraform Infrastructure

Provision the entire AWS environment from scratch using Terraform. All files live in `infra/terraform/`.

You must provision:

| Resource | Specification |
|---|---|
| **VPC** | 2 public + 2 private subnets across 2 AZs, NAT Gateway per AZ |
| **EKS Cluster** | Kubernetes 1.28, managed node group, `t3.medium` instances, min 2 / max 5 nodes |
| **ECR Repositories** | One per service, image scanning enabled, lifecycle policy retaining last 10 images |
| **AWS Secrets Manager** | Entries for JWT key and Stripe key |
| **IAM** | Node group role with ECR read access |

Requirements:
- Remote state must be stored in **S3** with **DynamoDB locking** — no local `terraform.tfstate` files committed to the repo
- Split your configuration across logical files: `main.tf`, `vpc.tf`, `eks.tf`, `ecr.tf`, `secrets.tf`, `variables.tf`, `outputs.tf`
- All resources must be tagged with `Project`, `Environment`, and `ManagedBy = Terraform`
- Hardcoded values belong in `variables.tf` — not scattered through resource blocks

> **Your README must include the exact sequence of commands to run a first-time infrastructure provisioning from a clean AWS account.**

---

### Deliverable 6 — Version Control Discipline

Your repository's Git history is part of your submission. It will be reviewed.

Requirements:
- Follow **GitFlow**: `main`, `develop`, `feature/*`, `fix/*` branches
- All commits must follow **Conventional Commits** format:
  ```
  feat(auth): add Dockerfile with multi-stage build
  fix(pipeline): correct image tag reference in deploy stage
  chore(terraform): extract hardcoded region into variable
  docs(readme): add first-time provisioning guide
  ```
- `main` must only receive merges from `develop` via Pull Request
- No secrets, `.env` files, or `terraform.tfstate` files in any commit — ever. Your `.gitignore` must prevent this.

---

### Deliverable 7 — README

Your repository must include a `README.md` written for a **new engineer joining the team** — not for a marker. It must cover:

1. **Architecture overview** — diagram showing services, databases, NATS, and ingress
2. **Prerequisites** — exact tools and versions required
3. **Local development setup** — from zero to running app in one section
4. **First-time production deployment** — step-by-step, including Terraform provisioning
5. **CI/CD pipeline overview** — what triggers what, and what the deploy process looks like
6. **Environment variables reference** — every variable, which service uses it, and what it does
7. **Troubleshooting** — at least five real failure scenarios you encountered and how to resolve them

> **A README that reads like it was generated in bulk will not be accepted. It must reflect your actual deployment decisions.**

---

## Architecture Reference

Use this as your starting point. Your final architecture may differ — document any deviations and justify them.

```
                    ┌──────────────────────────────────┐
                    │         Route 53 / DNS            │
                    └─────────────┬────────────────────┘
                                  │
                    ┌─────────────▼────────────────────┐
                    │     AWS Load Balancer (EKS)       │
                    └─────────────┬────────────────────┘
                                  │
                    ┌─────────────▼────────────────────┐
                    │     ingress-nginx Controller      │
                    └──┬──────┬──────┬──────┬──────────┘
                       │      │      │      │
                  ┌────▼──┐ ┌─▼───┐ ┌▼────┐ ┌▼──────┐
                  │ auth  │ │tick │ │order│ │payment│
                  └───┬───┘ └──┬──┘ └──┬──┘ └───┬───┘
                      │        │        │         │
                    Mongo    Mongo    Mongo      Mongo
                                  │
                          ┌───────▼────────┐
                          │ NATS Streaming │
                          └───────┬────────┘
                                  │
                          ┌───────▼────────┐
                          │   Expiration   │
                          │  (Bull/Redis)  │
                          └────────────────┘

            ┌──────────────────────────────────────────┐
            │              AWS EKS Cluster              │
            │         (private subnets, 2 AZs)          │
            └──────────────────────────────────────────┘
```

---

## Environment Variables Reference

| Variable | Service(s) | Description |
|---|---|---|
| `JWT_KEY` | auth, orders, tickets, payments | Secret used to sign and verify JWTs |
| `STRIPE_KEY` | payments | Stripe secret API key |
| `MONGO_URI` | auth, tickets, orders, payments | MongoDB connection string |
| `NATS_URL` | auth, tickets, orders, payments, expiration | NATS Streaming Server URL |
| `NATS_CLUSTER_ID` | all event-driven services | NATS cluster identifier string |
| `NATS_CLIENT_ID` | all event-driven services | Unique ID per pod — use pod name or generated UUID |

> `NATS_CLIENT_ID` must be unique per running instance. Two pods with the same client ID will cause one to be silently dropped by NATS. Use the Kubernetes `fieldRef` downward API to inject the pod name as this value.

---

## Grading Rubric

| Deliverable | Weight | Pass Criteria |
|---|---|---|
| Dockerfiles | 15% | All 6 images build without error; multi-stage; non-root user |
| Docker Compose | 10% | `docker compose up --build` reaches the frontend |
| Kubernetes Manifests | 20% | All pods reach `Running` state; ingress routes correctly |
| Jenkins Pipeline | 20% | Pipeline runs end-to-end on push to `main`; deploy stage gated |
| Terraform | 20% | `terraform apply` provisions a working cluster from scratch |
| Git History | 5% | GitFlow followed; conventional commits; no secrets committed |
| README | 10% | Covers all 7 required sections; reflects real deployment |

**Total: 100%**

A submission where any single deliverable is missing will be capped at 60%.

---

## Submission

1. Push your final work to a **public GitHub repository**
2. Submit the repository URL via the Loreon Learning portal
3. Include a short (3–5 minute) **Loom video** walking through:
   - Your Jenkins pipeline running a successful build
   - `kubectl get pods -n ticketflow` showing all pods `Running`
   - `terraform show` confirming provisioned infrastructure

**Deadline and portal link are in your cohort dashboard.**

---

## Getting Started

```bash
# 1. Fork this repository to your own GitHub account
# 2. Clone your fork
git clone https://github.com/<your-username>/ticketflow-capstone.git
cd ticketflow-capstone

# 3. Create your develop branch
git checkout -b develop
git push -u origin develop

# 4. Explore the codebase before writing a single line of config
ls -la
cat auth/package.json
cat tickets/src/index.ts
```

> There is no skeleton code, no starter Dockerfile, and no example pipeline to copy. You are expected to produce these from scratch using the skills developed throughout the Loreon Learning DevOps programme.

---

## A Note on Academic Integrity

The internet contains many implementations of this type of application. You are permitted to read documentation, Stack Overflow, and community resources. You are not permitted to copy another student's Jenkinsfile, Terraform configuration, or Dockerfiles verbatim.

Your submission must reflect **your** understanding and **your** decisions. The Loom walkthrough exists precisely to verify this.

---

<div align="center">

**Loreon Learning — DevOps Engineering Programme**
*Capstone Project — Advanced Track*

</div>
