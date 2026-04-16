# DevOps Capstone: Complete Student Guide
## Loreon Learning — Ticketing App Microservices

**Welcome!** You're about to build production-grade DevOps infrastructure for a real microservices application. You won't write any app code — the engineers already built that. Your job is to make it run, scale, and deploy reliably.

This guide breaks your capstone into 7 deliverables across 6 phases. Each phase builds on the last. Follow the steps, use the hints, and check your work at each checkpoint. Let's go.

---

## Phase 0: Understand Before You Build (Day 1)

### Why This Matters
You can't build infrastructure for code you don't understand. Spend 2-3 hours reading and documenting the application architecture. This prevents mistakes later.

### Step 1: Explore the Codebase
1. Open each service directory (`auth`, `tickets`, `orders`, `payments`, `expiration`, `client`)
2. Read the `package.json` in each — note the name, version, and scripts
3. Look at the `Dockerfile` if one exists (you'll be writing these soon)
4. Check for `.env.example` or comments showing required environment variables

> **Hint:** The `package.json` scripts show you how the app starts. Look for `"start"` or `"dev"`. That's what your Dockerfile will need to run.

### Step 2: Map Out the Architecture
Create a diagram (pen and paper is fine) showing:
- Which services connect to which databases (look for `MONGO_*` env vars)
- Which services talk to NATS (event bus) — check imports for `nats` or message publishing
- Which ports each service listens on (grep for `listen` or `PORT` env vars)
- Dependencies between services (e.g., orders needs tickets service)

> **Hint:** Look at `k8s-config` or deployment docs if they exist — they reveal the actual runtime setup the app expects.

### Step 3: Identify Key Patterns
1. **Shared code**: Find the `@sgtickets/common` package — this is published to npm
2. **Database needs**: List all MongoDB instances (each service typically gets its own)
3. **Event system**: Find NATS references — this is how services communicate async
4. **Client framework**: The `client` directory uses Next.js — different build process than backend

> **Common Mistake:** Don't assume services all run on port 3000. Check each service's code to find the actual port.

### Step 4: Set Up Git Workflow
1. Clone or initialize the repo locally
2. Create a `develop` branch: `git checkout -b develop`
3. Create a feature branch for your work: `git checkout -b feature/docker-setup`
4. Learn conventional commits: `feat:`, `fix:`, `docs:`, `refactor:` prefixes

> **Checkpoint:** You should have a written-out architecture diagram and a Git feature branch ready to work in.

---

## Phase 1: Dockerfiles (Deliverable 1 — 15%)

### The Goal
Each service needs a `Dockerfile` that builds and runs independently. You'll use **multi-stage builds** to keep images small.

### Why Multi-Stage?
Backend services are written in TypeScript. The container needs:
1. **Build stage**: Compile `.ts` files to `.js`
2. **Runtime stage**: Run only the compiled JS (doesn't need TypeScript compiler)

This cuts your image size in half.

### Step 1: Backend Services (auth, tickets, orders, payments, expiration)

1. Create a `Dockerfile` in each service directory
2. **Build stage** (Stage 1):
   ```
   - Use node:18 as base image
   - Set WORKDIR
   - COPY package*.json
   - RUN npm install
   - COPY source code
   - RUN npm run build (or tsc)
   ```

> **Hint:** Check if the service has a `build` script in `package.json`. If not, look at `tsconfig.json`. Notice `outDir`? If not set, you might need `RUN tsc --outDir dist` or similar. Each service might compile to a different folder.

3. **Runtime stage** (Stage 2):
   ```
   - Use node:18-alpine (smaller base)
   - Set WORKDIR /app
   - COPY --from=0 /build/dist ./dist  (or whatever the actual output folder is)
   - COPY package*.json and RUN npm ci --only=production
   - Create a non-root user
   - RUN chown -R appuser:appuser /app
   - USER appuser
   - EXPOSE <port>
   - CMD ["node", "dist/index.js"]
   ```

> **Hint:** For the non-root user, something like `RUN useradd -m -u 1001 appuser` works. Why? Security. Root containers are a liability.

> **Common Mistake:** Some students put `npm run build` in the runtime stage. That's wasteful — build once in stage 1, copy only the output to stage 2.

### Step 2: Client Service (Next.js is Different)

1. Next.js apps use `next build` which produces a `.next/` folder and needs the `node_modules`
2. Create `Dockerfile` in the `client` directory:
   ```
   - node:18 base
   - npm install
   - COPY source
   - RUN next build
   - EXPOSE 3000
   - USER appuser (non-root)
   - CMD ["npm", "start"]
   ```

> **Hint:** Next.js doesn't compile down to a single `.js` file like TypeScript. You need `.next/` folder at runtime, plus `node_modules`. So you might not need a multi-stage build for client, or you do but differently. Check if `next export` is an option (static build).

### Step 3: Layer Caching Optimization

Docker caches layers. Layers that change often should go last. Correct order:

1. COPY `package*.json` first
2. RUN `npm install`
3. COPY source code last (this changes constantly)

> **Why?** If source code changes, Docker reruns npm install. If npm install is separate, changes to src don't rebuild `node_modules`.

### Step 4: Testing Your Dockerfiles

For each service:
```bash
cd auth
docker build -t auth:latest .
docker run -p 3000:3000 auth:latest
```

Check for:
- No errors during build
- Container starts without crashing
- (Later, you'll verify it actually runs, but that requires a database)

> **Checkpoint:** `docker build -t auth .`, `docker build -t tickets .`, etc. should all succeed with no errors. Run `docker images` and see all 6 services listed.

---

## Phase 2: Docker Compose (Deliverable 2 — 10%)

### The Goal
A single `docker-compose.yaml` file that brings up all services + databases locally. This is your testing environment.

### Why Compose Before Kubernetes?
Compose catches 90% of configuration errors before you deploy to Kubernetes. Do this right and K8s will feel easy.

### Step 1: List All Services

Your `docker-compose.yaml` needs services for:
- All 6 app services (auth, tickets, orders, payments, expiration, client)
- All MongoDB instances (usually one per service that needs data)
- NATS (the event bus)

### Step 2: Service Discovery Basics

In Compose (and Kubernetes), services discover each other by name. If you define a service called `auth`, other services reach it at `http://auth:3000` (or whatever port).

> **Hint:** The MONGO_URI for the auth service should be `mongodb://auth-mongo:27017/auth` where `auth-mongo` is the MongoDB service name in Compose.

> **Hint:** NATS URL is `http://nats:4222` where `nats` is the service name.

### Step 3: Build the compose.yaml File

1. Add each backend service:
   ```yaml
   services:
     auth:
       build: ./auth
       ports:
         - "3001:3001"  (or actual port)
       environment:
         - MONGO_URI=mongodb://auth-mongo:27017/auth
         - NATS_URL=http://nats:4222
         - NATS_CLIENT_ID=auth-service
         - JWT_KEY=example_key_change_later
       depends_on:
         - auth-mongo
         - nats
   ```

2. Add MongoDB services:
   ```yaml
   auth-mongo:
     image: mongo:5
     volumes:
       - auth-mongo-data:/data/db
   volumes:
     auth-mongo-data:
   ```

3. Add NATS:
   ```yaml
   nats:
     image: nats:2.9-alpine
   ```

4. Add the client service (port 3000, probably)

> **Hint:** Each backend service needs a **unique** NATS_CLIENT_ID. Don't reuse. Why? NATS uses client IDs to track subscriptions.

> **Hint:** Some services might not need a database (check your architecture diagram). Some might share one. Check the app code.

### Step 4: Environment Variables

Check `.env.example` or code comments for all required vars. Common ones:
- `MONGO_URI`
- `NATS_URL`
- `NATS_CLIENT_ID`
- `JWT_KEY` (can be a placeholder for local testing)
- Service-to-service URLs (e.g., `TICKETS_SERVICE_URL=http://tickets:3002`)

> **Common Mistake:** Forgetting `depends_on`. Without it, services start before databases are ready. Use `depends_on` to control startup order.

### Step 5: Test Locally

```bash
docker compose up --build
# Wait for all services to start
# In another terminal:
curl http://localhost:3000  # or whatever client port
```

Check Docker logs:
```bash
docker compose logs auth
docker compose logs tickets
```

> **Checkpoint:** `docker compose up` completes without errors. Visit `localhost:3000` and see the client app load. Check no service is in a restart loop.

---

## Phase 3: Kubernetes Manifests (Deliverable 3 — 20%)

### The Goal
Write YAML manifests to deploy everything to Kubernetes. Bigger step, but it's just a translation from Compose.

### Understanding the Relationship

- **Deployment**: Tells Kubernetes how many replicas to run, what image, what env vars
- **Pod**: The actual running container(s)
- **Service**: Exposes pods internally (ClusterIP) or externally (LoadBalancer/NodePort)
- **ConfigMap/Secret**: Store configuration and sensitive data
- **PVC**: Persistent storage for databases

### Step 1: Create Secrets

Before writing manifests, create secrets in your cluster:

```bash
kubectl create secret generic jwt-secret --from-literal=JWT_KEY=your-secret-key-here
```

> **Hint:** In production, use a secrets manager (AWS Secrets Manager, HashiCorp Vault). For this capstone, kubectl secrets are fine.

### Step 2: Create ConfigMap (Optional but Recommended)

Store non-sensitive config:
```bash
kubectl create configmap app-config --from-literal=LOG_LEVEL=info
```

### Step 3: Write Deployment Manifests

Create a file like `k8s/auth-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth
spec:
  replicas: 2
  selector:
    matchLabels:
      app: auth
  template:
    metadata:
      labels:
        app: auth
    spec:
      containers:
      - name: auth
        image: <YOUR_REGISTRY>/auth:latest
        ports:
        - containerPort: 3001
        env:
        - name: MONGO_URI
          value: "mongodb://auth-mongo:27017/auth"
        - name: NATS_URL
          value: "http://nats:4222"
        - name: NATS_CLIENT_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: JWT_KEY
          valueFrom:
            secretKeyRef:
              name: jwt-secret
              key: JWT_KEY
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
```

> **Hint:** For `NATS_CLIENT_ID`, use `fieldRef` with `metadata.name`. Each pod gets a unique name (e.g., `auth-abc123def`), so this auto-generates unique IDs.

> **Hint:** Resource requests are important. Start with `100m` CPU and `128Mi` memory. Test under load and adjust.

### Step 4: Write Service Manifests

Create `k8s/auth-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: auth
spec:
  selector:
    app: auth
  ports:
  - port: 3001
    targetPort: 3001
  type: ClusterIP
```

> **Hint:** `ClusterIP` is internal-only (services talk to each other). Use `LoadBalancer` or `NodePort` only for client-facing services.

### Step 5: StatefulSet for MongoDB

Databases need persistent storage. Use StatefulSet + PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: auth-mongo-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: auth-mongo
spec:
  serviceName: auth-mongo
  replicas: 1
  selector:
    matchLabels:
      app: auth-mongo
  template:
    metadata:
      labels:
        app: auth-mongo
    spec:
      containers:
      - name: mongo
        image: mongo:5
        ports:
        - containerPort: 27017
        volumeMounts:
        - name: mongo-storage
          mountPath: /data/db
      volumes:
      - name: mongo-storage
        persistentVolumeClaim:
          claimName: auth-mongo-pvc
```

> **Hint:** PVC size depends on your app. For a capstone, `5Gi` per service is plenty. In production, monitor and scale.

### Step 6: Ingress for External Access

Create `k8s/ingress.yaml` to expose the client service:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: "app.local"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: client
            port:
              number: 3000
```

> **Hint:** Before deploying, ensure the nginx-ingress controller is running: `kubectl get pods -n ingress-nginx`. If not, install it with Helm.

### Step 7: NATS Service

NATS needs a Service too:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nats
spec:
  selector:
    app: nats
  ports:
  - port: 4222
    targetPort: 4222
  type: ClusterIP

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nats
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nats
  template:
    metadata:
      labels:
        app: nats
    spec:
      containers:
      - name: nats
        image: nats:2.9-alpine
        ports:
        - containerPort: 4222
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
```

### Step 8: Apply and Verify

```bash
kubectl apply -f k8s/
kubectl get pods
kubectl get svc
```

Wait for all pods to show `Running`:

```bash
kubectl get pods --watch
```

> **Checkpoint:** `kubectl get pods` shows all services running. `kubectl logs <pod-name>` shows no errors. Test with `kubectl port-forward svc/client 3000:3000` then visit `localhost:3000`.

> **Common Mistake:** Forgetting the nginx-ingress controller. Or deploying but not exposing via Ingress — apps are running but unreachable externally.

---

## Phase 4: Jenkins Pipeline (Deliverable 4 — 20%)

### The Goal
A declarative Jenkins pipeline that builds, tests, pushes images, and deploys on each commit.

### Understanding Pipeline Stages

1. **Build**: Compile and create Docker images
2. **Push**: Push images to Docker Hub (or your registry)
3. **Deploy**: Update Kubernetes with new images (main branch only)

### Step 1: Jenkinsfile Structure

Create a `Jenkinsfile` in the repo root:

```groovy
pipeline {
  agent any

  environment {
    DOCKER_REGISTRY = "your-docker-hub-username"
    GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
  }

  stages {
    stage('Build') {
      parallel {
        stage('Auth') {
          steps {
            dir('auth') {
              sh "docker build -t ${DOCKER_REGISTRY}/auth:${GIT_SHA} -t ${DOCKER_REGISTRY}/auth:latest ."
            }
          }
        }
        stage('Tickets') {
          steps {
            dir('tickets') {
              sh "docker build -t ${DOCKER_REGISTRY}/tickets:${GIT_SHA} -t ${DOCKER_REGISTRY}/tickets:latest ."
            }
          }
        }
        // Repeat for all services...
      }
    }

    stage('Push') {
      when {
        branch 'main'
      }
      steps {
        script {
          sh "docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}"
          sh "docker push ${DOCKER_REGISTRY}/auth:${GIT_SHA}"
          sh "docker push ${DOCKER_REGISTRY}/auth:latest"
          // Repeat for all services...
        }
      }
    }

    stage('Deploy') {
      when {
        branch 'main'
      }
      steps {
        sh "kubectl set image deployment/auth auth=${DOCKER_REGISTRY}/auth:${GIT_SHA}"
        sh "kubectl set image deployment/tickets tickets=${DOCKER_REGISTRY}/tickets:${GIT_SHA}"
        // Repeat for all services...
        sh "kubectl rollout status deployment/auth"
      }
    }
  }
}
```

> **Hint:** Use `parallel { stage(...) { } stage(...) { } }` to build all services at once. Faster.

> **Hint:** Tag images with git SHA and `latest`. The SHA lets you rollback; `latest` is convenient for testing.

> **Hint:** The `when { branch 'main' }` block means "only push and deploy on the main branch." Feature branches build but don't push.

### Step 2: Credentials in Jenkins

1. Go to Jenkins dashboard → Manage Jenkins → Manage Credentials
2. Create credentials for Docker Hub (username + password or token)
3. In your Jenkinsfile, use `withCredentials`:

```groovy
withCredentials([
  usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')
]) {
  sh "docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}"
  sh "docker push ..."
}
```

> **Hint:** Never hardcode credentials in Jenkinsfile. Jenkins provides credential binding to inject them at runtime.

### Step 3: Rolling Updates

The `kubectl set image` command updates deployments without downtime:

```groovy
sh "kubectl set image deployment/auth auth=${DOCKER_REGISTRY}/auth:${GIT_SHA}"
sh "kubectl rollout status deployment/auth --timeout=5m"
```

This rolls out new pods while old ones are still running, then removes old pods once new ones are healthy.

### Step 4: Test the Pipeline

1. Commit your Jenkinsfile: `git add Jenkinsfile && git commit -m "ci: add Jenkins pipeline"`
2. Push to your feature branch
3. In Jenkins, create a pipeline job pointing to your repo
4. Trigger a build
5. Watch the console output — all stages should pass

> **Common Mistake:** Forgetting to add services to the Deploy stage. You build 6 services but only deploy 3 to K8s.

> **Checkpoint:** Push to the `main` branch. Jenkins should build all services, push to Docker Hub, and deploy to Kubernetes. Check Kubernetes: `kubectl get pods` should show new pod creation (age = 0s).

---

## Phase 5: Terraform (Deliverable 5 — 20%)

### The Goal
Write Infrastructure as Code (Terraform) to provision AWS infrastructure: VPC, EKS cluster, ECR registry, etc.

### Understanding the Structure

```
terraform/
  main.tf          # Provider config
  variables.tf     # Input variables
  outputs.tf       # Outputs (cluster endpoint, etc.)
  vpc.tf           # VPC, subnets, NAT gateway
  eks.tf           # EKS cluster, node groups
  ecr.tf           # ECR repositories
  iam.tf           # IAM roles and policies
```

### Step 1: Configure the Provider

Create `terraform/main.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "capstone/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
}
```

> **Hint:** The S3 backend stores state remotely. First run `terraform init` locally, then move state to S3. Create the bucket and DynamoDB table manually (or with Terraform in a separate stack).

### Step 2: Define Variables

Create `terraform/variables.tf`:

```hcl
variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  default     = "ticketing-app"
}

variable "environment" {
  description = "Environment name"
  default     = "capstone"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}
```

### Step 3: VPC Configuration

Create `terraform/vpc.tf`:

```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Environment = var.environment
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
```

> **Hint:** Use the `terraform-aws-modules/vpc` module — it's battle-tested and handles all the complexity (NAT gateways, route tables, etc.).

### Step 4: EKS Cluster

Create `terraform/eks.tf`:

```hcl
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.27"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)

  eks_managed_node_groups = {
    general = {
      name           = "${var.cluster_name}-node-group"
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 5
      desired_size   = 2

      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }

  tags = {
    Environment = var.environment
  }
}
```

> **Hint:** Start with small nodes (`t3.medium`) for a capstone. Watch costs. t3 instances are cheaper than compute-optimized.

### Step 5: ECR Repositories

Create `terraform/ecr.tf`:

```hcl
resource "aws_ecr_repository" "services" {
  for_each = toset(["auth", "tickets", "orders", "payments", "expiration", "client"])

  name                 = "${var.cluster_name}/${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
  }
}

output "ecr_repositories" {
  value = { for name, repo in aws_ecr_repository.services : name => repo.repository_url }
}
```

> **Hint:** This creates 6 repos (one per service) using a `for_each` loop. Cleaner than writing 6 resource blocks.

### Step 6: Outputs

Create `terraform/outputs.tf`:

```hcl
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID"
  value       = module.eks.cluster_security_group_id
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}
```

### Step 7: Plan and Deploy

```bash
cd terraform
terraform init
terraform plan
# Review the plan carefully
terraform apply
```

After apply:
```bash
# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name ticketing-app
kubectl get nodes
```

> **Checkpoint:** `terraform plan` shows expected resources without errors. `terraform apply` creates the cluster. `kubectl get nodes` shows 2 worker nodes.

> **Common Mistake:** Not creating the S3 backend bucket before running `terraform init`. Or committing `terraform.tfstate` to git (add it to `.gitignore`).

---

## Phase 6: Git Discipline & README (Deliverables 6 & 7 — 15%)

### The Goal
- **Deliverable 6**: Proper Git workflow with conventional commits
- **Deliverable 7**: Comprehensive README for the project

### Step 1: Conventional Commits

Each commit should follow the pattern: `type(scope): message`

Examples for your capstone:
```
feat(docker): add multi-stage Dockerfile for auth service
feat(compose): add MongoDB and NATS services to docker-compose.yaml
feat(k8s): create auth deployment and service manifests
feat(jenkins): add declarative pipeline with build and deploy stages
feat(terraform): provision EKS cluster and VPC
docs(readme): document deployment steps
fix(k8s): set resource limits for NATS pod
chore(git): initialize feature branch
```

> **Hint:** Conventional commits make the changelog automatic. Tools read the commit history and generate release notes.

### Step 2: Git Workflow

```bash
# Start work on a deliverable
git checkout -b feature/deliverable-1-docker

# Make changes, commit
git add Dockerfile
git commit -m "feat(docker): add Dockerfile for auth service"

# When deliverable is done, create a pull request
git push origin feature/deliverable-1-docker
# Open PR on GitHub/GitLab, request review
# After review, merge to develop branch

# When ready to release (all deliverables done)
git checkout develop
git pull origin develop
git checkout main
git pull origin main
git merge develop
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin main --tags
```

> **Hint:** Use a PR template to document what was done:
> ```markdown
> ## What does this PR do?
> Adds Dockerfiles for all 6 microservices with multi-stage builds.
> 
> ## Testing
> Ran `docker build` for each service; images built successfully.
> 
> ## Related deliverables
> Deliverable 1: Dockerfiles
> ```

### Step 3: README Sections

Create `/docs/README.md` or update the root `README.md` with these sections:

1. **Project Overview**
   - What is this capstone?
   - Architecture diagram (link to diagram or embed)

2. **Prerequisites**
   - Docker & Docker Compose
   - Kubernetes (local: minikube or kind)
   - kubectl CLI
   - AWS CLI (for Terraform)
   - Jenkins (optional for local testing)

3. **Local Development**
   ```bash
   docker compose up --build
   # Services available at localhost:3000, etc.
   ```

4. **Kubernetes Deployment**
   - Steps to apply manifests
   - How to verify deployment
   - How to access the app (port-forward or Ingress URL)

5. **Jenkins Pipeline**
   - How to set up Jenkins
   - How to connect the repo
   - What credentials to configure

6. **Terraform**
   - Prerequisites (AWS account, credentials)
   - Steps: `terraform init`, `terraform plan`, `terraform apply`
   - Cost notes (t3.medium nodes, 2 replicas = ~$XX/month)

7. **Troubleshooting**
   - Service won't start: Check logs with `docker compose logs <service>`
   - Pod in CrashLoopBackOff: Check K8s logs with `kubectl logs <pod>`
   - NATS_CLIENT_ID errors: Ensure each service has unique ID
   - MongoDB connection refused: Check if MongoDB pod is running
   - Jenkins build fails: Check if Docker daemon is accessible

8. **Future Improvements**
   - Add SSL/TLS with cert-manager
   - Add Prometheus monitoring
   - Add log aggregation with ELK
   - Implement GitOps with ArgoCD

> **Hint:** Add a troubleshooting section with real problems you encountered. This shows you actually tested everything.

### Step 4: Commit and Document

```bash
git add docs/README.md
git commit -m "docs(readme): comprehensive deployment guide and troubleshooting"
```

> **Checkpoint:** `git log --oneline` shows clean, conventional commit history. README is complete and accurate.

---

## Tips & Common Mistakes

### Don't Skip Docker Compose
Tempting to jump straight to Kubernetes, but Compose catches 90% of configuration issues first. Services fail to find each other? DNS problem? Database connection? All easier to debug in Compose.

### NATS_CLIENT_ID Must Be Unique
NATS tracks subscriptions per client ID. If two services use the same ID, subscriptions conflict and messages get lost. In Kubernetes, use the `fieldRef` trick from Phase 3.

### Never Commit Secrets or State Files
Add to `.gitignore`:
```
.env
.env.local
tfstate*
terraform/.terraform/
```

### Test Locally Before EKS
Use `minikube` or `kind` (Kubernetes in Docker) to test locally first. Faster feedback, no AWS costs.

```bash
# Start a local cluster with minikube
minikube start --cpus 4 --memory 4096
# Apply K8s manifests
kubectl apply -f k8s/
# Test
minikube tunnel  # Makes services accessible
```

### @sgtickets/common is on npm
Don't try to build it yourself. Your Dockerfiles just run `npm install`, which pulls it from the npm registry.

### Resource Limits Matter
Too many pods with unlimited resources = node out of memory. Start conservative (`100m` CPU, `128Mi` memory) and increase under load testing.

### Document Your Architecture Decisions
In a real project, teams need to understand WHY you chose multi-stage builds, or why you use StatefulSet for MongoDB. Add ADR (Architecture Decision Record) files if time permits.

---

## Checkpoint Summary

| Deliverable | Goal | Done When |
|---|---|---|
| Phase 0 | Understand the codebase and architecture | Architecture diagram complete, Git feature branch ready |
| Phase 1 | Write Dockerfiles for all 6 services | `docker build` succeeds for each service |
| Phase 2 | Docker Compose file with all services + DBs | `docker compose up` runs all services, client accessible at localhost |
| Phase 3 | Kubernetes manifests (Deployments, Services, etc.) | `kubectl get pods` shows all services Running |
| Phase 4 | Jenkins pipeline for CI/CD | Push to main branch, Jenkins builds/pushes/deploys without errors |
| Phase 5 | Terraform infrastructure on AWS | `terraform apply` creates EKS cluster, `kubectl get nodes` shows 2 nodes |
| Phase 6 | Git discipline and comprehensive README | Clean commit history, README has 8+ sections with accurate info |

---

## Final Thoughts

You've just built production-grade DevOps infrastructure. You've containerized 6 services, orchestrated them locally and in the cloud, automated deployment, and documented everything.

Real teams do this every day. The patterns you learned — multi-stage builds, service discovery, Kubernetes manifests, CI/CD pipelines, infrastructure as code — are used at companies of all sizes.

You're ready to help run real systems. Keep this guide handy, and use it as a reference when you encounter similar challenges in your career.

Good luck, and reach out if you get stuck. You've got this.
