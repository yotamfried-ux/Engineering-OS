# Infrastructure Patterns

> Pattern library for provisioning, containerizing, and operating production infrastructure. See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring and lifecycle.

## Overview

Patterns for defining, packaging, and deploying production infrastructure as code. Use these when provisioning cloud resources, building container images, deploying to Kubernetes, managing shared Terraform state, handling secrets, or choosing between infrastructure-as-code toolchains. Each pattern addresses a failure mode observed in real production environments: state corruption, image bloat, resource starvation, secret leakage, and environment drift.

---

## Pattern: Terraform Module Structure

**Problem:** Infrastructure code is duplicated across environments with no reuse or consistency. Changes to a shared resource (VPC CIDR, ECS task size) must be applied in multiple places and drift over time.

**Solution:** Organize Terraform into reusable child modules with explicit interfaces (variables + outputs). Root modules (`environments/staging`, `environments/production`) call child modules with environment-specific variable values.

**Architecture:**
```
infrastructure/
  modules/
    vpc/
      variables.tf   (inputs: cidr_block, az_count, tags)
      main.tf        (aws_vpc, aws_subnet, aws_internet_gateway)
      outputs.tf     (vpc_id, private_subnet_ids, public_subnet_ids)
    rds/
      variables.tf
      main.tf
      outputs.tf
    ecs-service/
      variables.tf
      main.tf
      outputs.tf
  environments/
    staging/
      main.tf        (calls modules with staging vars)
      terraform.tfvars
    production/
      main.tf        (same modules, production vars)
      terraform.tfvars
  backend.tf         (remote state: S3 + DynamoDB)
```

**Implementation Notes:**
- Module interface: expose only what callers need in `variables.tf`; keep internals private. A module that exposes every resource attribute is not an abstraction.
- Remote state: always use S3 + DynamoDB (AWS) or Terraform Cloud for state locking. Local state is never appropriate in a shared team.
- Environment separation: each environment has its own state file with a distinct S3 key. Never share state between staging and production.
- Secrets: never place secret values in `.tf` files or `.tfvars`. Declare `variable "db_password" { sensitive = true }` and supply the value from Secrets Manager at deploy time via CI.
- `terraform workspace` is appropriate for isolated ephemeral environments (feature branches). Staging and production use separate directories, not workspaces.
- Pin provider versions with `required_providers` to prevent unexpected upgrades between CI runs.

**Example Code:**
```hcl
# modules/ecs-service/variables.tf
variable "service_name"       { type = string }
variable "container_image"    { type = string }
variable "cpu"                { type = number; default = 256 }
variable "memory"             { type = number; default = 512 }
variable "container_port"     { type = number }
variable "desired_count"      { type = number; default = 1 }
variable "cluster_id"         { type = string }
variable "subnet_ids"         { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "tags"               { type = map(string); default = {} }

# modules/ecs-service/outputs.tf
output "service_name"        { value = aws_ecs_service.this.name }
output "task_definition_arn" { value = aws_ecs_task_definition.this.arn }

# modules/ecs-service/main.tf
resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([{
    name  = var.service_name
    image = var.container_image
    portMappings = [{ containerPort = var.container_port }]
  }])
  tags = var.tags
}

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = var.subnet_ids
    security_groups = var.security_group_ids
  }
  tags = var.tags
}
```

```hcl
# environments/staging/main.tf
terraform {
  required_providers {
    aws = { source = "hashicorp/aws"; version = "~> 5.0" }
  }
  backend "s3" {
    bucket         = "my-tf-state"
    key            = "env:/staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-state-locks"
    encrypt        = true
  }
}

module "vpc" {
  source     = "../../modules/vpc"
  cidr_block = "10.1.0.0/16"
  az_count   = 2
  tags       = { Environment = "staging" }
}

module "api" {
  source             = "../../modules/ecs-service"
  service_name       = "api-staging"
  container_image    = var.api_image
  container_port     = 3000
  cluster_id         = aws_ecs_cluster.main.id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.api.id]
  tags               = { Environment = "staging" }
}
```

**Common Mistakes:**
- Hardcoding AWS account IDs or region names inside modules — makes modules non-portable and exposes account structure in version control.
- Storing `terraform.tfstate` in git — state files contain plaintext resource attributes including secrets.
- Running `terraform apply` in CI without first reviewing the plan output — silent destructive changes occur.
- Monolithic root configurations with hundreds of resources — the blast radius of any `apply` is unpredictable and plan output is unreadable.

**Security Considerations:**
- Never store AWS credentials in Terraform files. Use IAM roles (instance profile, ECS task role, OIDC for CI).
- Enable S3 SSE-KMS for state encryption; do not rely on SSE-S3 alone for compliance workloads.
- Use `required_providers` with exact minor version pins (`~> 5.0`) to prevent supply-chain attacks via provider upgrades.
- Restrict who can run `terraform apply` in production by scoping CI/CD IAM roles to least-privilege and requiring manual approval gates.

**Testing Strategy:**
Run `terraform validate` and `terraform plan` in CI on every pull request. Use `tflint` for provider-specific linting and `checkov` (or `tfsec`) for security policy checks. Use `terratest` (Go) or the native `tftest` framework for module integration tests that deploy real resources to a test account and assert outputs.

**Score:** Candidate (see [pattern-lifecycle.md](../../core/pattern-lifecycle.md))

**Official References:**
- Terraform Documentation: https://developer.hashicorp.com/terraform/docs (Official Documentation)
- Terraform Module Structure: https://developer.hashicorp.com/terraform/language/modules/develop/structure (Official Documentation)
- terratest: https://terratest.gruntwork.io/docs/ (Trusted Reference Repository)

---

## Pattern: Docker Production Image

**Problem:** Development Dockerfiles produce images that are hundreds of megabytes larger than necessary, contain build tools and package managers not needed at runtime, and run as root — meaning a container escape grants root on the host.

**Solution:** Multi-stage build that separates the build environment from the runtime image. The runtime stage copies only compiled artifacts from the builder stage, creates a non-root user, and sets a HEALTHCHECK.

**Architecture:**
```
Stage 1 (builder): node:20-alpine
  → COPY package.json, package-lock.json
  → RUN npm ci                          (installs devDependencies)
  → COPY src/
  → RUN npm run build                   (compiles TypeScript to dist/)
  → RUN npm prune --omit=dev            (removes devDependencies)

Stage 2 (runtime): node:20-alpine      (fresh layer — no build tools)
  → COPY --from=builder /app/dist ./dist
  → COPY --from=builder /app/node_modules ./node_modules
  → RUN addgroup -S appgroup && adduser -S appuser -G appgroup
  → EXPOSE 3000
  → HEALTHCHECK CMD wget -qO- http://localhost:3000/health/live || exit 1
  → USER appuser
  → CMD ["node", "dist/index.js"]
```

**Implementation Notes:**
- Use specific version tags (`node:20-alpine`), never `latest`. Pin to a digest (`FROM node:20-alpine@sha256:...`) in high-security environments for fully reproducible builds.
- `.dockerignore` must exclude: `.git`, `node_modules`, `*.env`, `*.env.*`, `coverage/`, `test/`, and any local config files. Without it, secrets and dev data enter the build context.
- Set `NODE_ENV=production` and use `npm prune --omit=dev` in the builder stage before copying `node_modules` to the runtime stage.
- HEALTHCHECK at the Docker layer is a backstop; the primary health signal is the orchestrator probe (Kubernetes readiness probe, ECS health check).
- Do not install debugging tools (`curl`, `bash`) in the runtime stage beyond the minimum required for HEALTHCHECK.

**Example Code:**
```dockerfile
# .dockerignore
.git
node_modules
*.env
*.env.*
coverage
test
*.test.ts
*.spec.ts
```

```dockerfile
# Dockerfile
FROM node:20-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build && npm prune --omit=dev

# --- runtime stage ---
FROM node:20-alpine AS runtime
WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules

ENV NODE_ENV=production
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health/live || exit 1

USER appuser
CMD ["node", "dist/index.js"]
```

**Common Mistakes:**
- Running the container as root — a container escape or path traversal vulnerability escalates to host root immediately.
- Installing `curl` or `wget` in the runtime stage for debugging and leaving it there permanently — expands the attack surface.
- Copying the entire source tree into the runtime stage — exposes TypeScript source, `.env` examples, and internal comments.
- Not using `.dockerignore` — the `.git` directory enters the build context, slowing builds and potentially leaking repository secrets stored in git history.

**Security Considerations:**
- Scan images with Trivy or Docker Scout in CI before pushing to a registry. Fail the build on CRITICAL severity CVEs.
- Never store secrets as `ENV` variables in the Dockerfile — they are visible in `docker inspect` and in the image layer manifest. Inject secrets at runtime via the orchestrator.
- Use `--read-only` filesystem at runtime where the application allows it; mount only required writable paths as `tmpfs`.
- Set `--cap-drop ALL` and restore only required capabilities (e.g., `--cap-add NET_BIND_SERVICE` if binding to port 80).

**Testing Strategy:**
- Run `docker build` in CI on every pull request to catch build-time failures early.
- Run `trivy image <image>` or `grype <image>` as a CI step; fail on CRITICAL findings.
- Validate the HEALTHCHECK: `docker inspect --format='{{.State.Health.Status}}' <container>` must return `healthy` within the start period.
- Assert non-root execution: `docker run --rm <image> whoami` must not return `root`.
- Assert image size has not regressed: compare against a stored baseline in CI.

**Score:** Candidate (see [pattern-lifecycle.md](../../core/pattern-lifecycle.md))

**Official References:**
- Docker Multi-Stage Builds: https://docs.docker.com/build/building/multi-stage/ (Official Documentation)
- Docker Security Best Practices: https://docs.docker.com/develop/security-best-practices/ (Official Documentation)
- Trivy Documentation: https://trivy.dev/latest/docs/ (Official Documentation)

---

## Pattern: Kubernetes Deployment

**Problem:** Deploying applications to Kubernetes without resource limits, health probes, and disruption budgets leads to resource starvation (OOM kills cascade across the node), rolling update failures, and pods restarted for the wrong reasons.

**Solution:** Use a Deployment + Service + ConfigMap + Secret with explicit resource requests and limits, separate liveness and readiness probes, and a PodDisruptionBudget to guarantee availability during node drains and rolling updates.

**Architecture:**
```
Deployment (api-deployment)
  └── Pod template
        ├── Container: api-server
        │     ├── resources.requests  (CPU: 100m, memory: 128Mi)
        │     ├── resources.limits    (CPU: 500m, memory: 512Mi)
        │     ├── livenessProbe  → GET /health/live  (is the process alive?)
        │     ├── readinessProbe → GET /health/ready (can it serve traffic?)
        │     └── envFrom: ConfigMap (non-secret config) + Secret (credentials)
        └── securityContext: runAsNonRoot, readOnlyRootFilesystem

Service (api-service) → ClusterIP
Ingress               → routes external traffic to Service
PodDisruptionBudget   → minAvailable: 1 (guarantees one pod during drain)
```

**Implementation Notes:**
- Always set `resources.requests` and `resources.limits`. Without requests, the scheduler has no basis for placement. Without limits, a memory leak in one pod can OOM-kill every other pod on the node.
- Separate liveness from readiness: a liveness failure triggers a pod restart; a readiness failure removes the pod from the load balancer without restarting it. Never check external dependencies in liveness — a downstream database outage would restart all pods simultaneously.
- `minReadySeconds: 30` prevents a rolling update from declaring a new pod healthy too quickly and cutting over before it has warmed up.
- Use `RollingUpdate` with `maxSurge: 1, maxUnavailable: 0` for zero-downtime deploys. With `maxUnavailable: 0`, old pods are only terminated after new pods pass readiness.
- Never use the `latest` tag in Kubernetes manifests. Without a fixed image tag, there is no rollback story and `imagePullPolicy: Always` introduces uncontrolled rollouts.

**Example Code:**
```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
  namespace: production
data:
  LOG_LEVEL: "info"
  PORT: "3000"
  NODE_ENV: "production"
---
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
  namespace: production
spec:
  replicas: 3
  minReadySeconds: 30
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
      containers:
        - name: api-server
          image: my-registry/api:1.4.2   # never use latest
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
          envFrom:
            - configMapRef:
                name: api-config
            - secretRef:
                name: api-secrets
          livenessProbe:
            httpGet:
              path: /health/live
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 10
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 2
          securityContext:
            readOnlyRootFilesystem: true
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
---
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: production
spec:
  selector:
    app: api
  ports:
    - port: 80
      targetPort: 3000
  type: ClusterIP
---
# pdb.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
  namespace: production
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: api
```

**Common Mistakes:**
- Omitting `resources.limits` — a single misbehaving pod can OOM-kill unrelated pods on the same node.
- Using `imagePullPolicy: Always` with `latest` tag in production — uncontrolled rollouts whenever the image is rebuilt.
- Running a single replica without a PodDisruptionBudget — any node drain (routine maintenance, cluster upgrade) causes downtime.
- Storing credentials in ConfigMaps — ConfigMaps are not encrypted at rest and are readable by any pod in the namespace with default RBAC.

**Security Considerations:**
- Use `securityContext: { runAsNonRoot: true, readOnlyRootFilesystem: true, allowPrivilegeEscalation: false }` on every container.
- Enable encryption at rest for Kubernetes Secrets (`EncryptionConfiguration`) at the cluster level, or use an external secrets operator (External Secrets Operator with AWS Secrets Manager).
- Apply `NetworkPolicy` resources to restrict pod-to-pod communication to the minimum required paths.
- Use separate namespaces per environment with RBAC scoped per namespace. Developers should not have `kubectl exec` access to production pods.

**Testing Strategy:**
- Dry-run manifests before applying: `kubectl apply --dry-run=server -f .`
- Lint manifests with `kubeconform` or `kubeval` in CI to catch schema violations before deployment.
- Test health probe paths independently: assert `/health/live` returns 200 always and `/health/ready` returns 503 when dependencies are down.
- Validate rollout completes in CI: `kubectl rollout status deployment/api-deployment --timeout=120s`
- Verify PodDisruptionBudget in staging: `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data` and assert no service interruption.

**Score:** Candidate (see [pattern-lifecycle.md](../../core/pattern-lifecycle.md))

**Official References:**
- Kubernetes Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/ (Official Documentation)
- Kubernetes ConfigMaps and Secrets: https://kubernetes.io/docs/concepts/configuration/ (Official Documentation)
- Kubernetes Health Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ (Official Documentation)
- Kubernetes Security Context: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ (Official Documentation)

---

## Pattern: Terraform Remote State and Locking

**Problem:** Multiple engineers running `terraform apply` concurrently can corrupt the state file. The second apply reads stale state, plans against it, and overwrites changes made by the first — producing infrastructure that diverges from what either engineer intended.

**Solution:** Store state in a versioned, encrypted remote backend (S3 + DynamoDB on AWS). DynamoDB provides a distributed lock that serializes concurrent applies. Each environment has its own state file; state is never shared between environments.

**Architecture:**
```
terraform apply (engineer A)
  → acquires DynamoDB lock on key "env:/staging/terraform.tfstate"
  → reads current state from S3
  → creates plan, applies changes
  → writes new state to S3
  → releases DynamoDB lock

terraform apply (engineer B — concurrent)
  → attempts to acquire DynamoDB lock
  → BLOCKED: lock already held by engineer A
  → waits until A's apply completes and lock is released
  → reads updated state → safe to plan and apply

S3 bucket: tf-state-<account-id>
  env:/staging/terraform.tfstate      (versioned, SSE-KMS)
  env:/production/terraform.tfstate   (separate key, separate state)

DynamoDB table: tf-state-locks
  LockID (String, hash key)           (one table serves all environments)
```

**Implementation Notes:**
- Use a dedicated S3 bucket for Terraform state with versioning enabled and MFA delete enabled on the bucket policy. This is the only recovery path if state is corrupted.
- One DynamoDB table can serve all environments. The lock key is the full S3 object key, which is unique per environment.
- Each environment uses a distinct `key` in the backend block: `env:/staging/terraform.tfstate` vs `env:/production/terraform.tfstate`. This prevents a staging apply from locking out a concurrent production apply.
- Never commit `.terraform/` directories or any `*.tfstate` or `*.tfstate.backup` files to git. Add these to `.gitignore` globally.
- Use `terraform init -backend-config` to inject the bucket and table names from CI environment variables. This avoids hardcoding account-specific values in committed files.

**Example Code:**
```hcl
# backend.tf (committed — no account-specific values hardcoded)
terraform {
  backend "s3" {
    # All values injected at init time via -backend-config flags
    encrypt = true
  }
  required_providers {
    aws = { source = "hashicorp/aws"; version = "~> 5.0" }
  }
}
```

```hcl
# bootstrap/state-backend.tf — provisioned once per AWS account
resource "aws_s3_bucket" "tf_state" {
  bucket = "tf-state-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tf_state.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = "tf-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.tf_state.arn
  }
}
```

```bash
# CI: inject backend config at init time — no secrets or account IDs in source
terraform init \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="key=env:/${ENVIRONMENT}/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="dynamodb_table=${TF_LOCK_TABLE}"

terraform plan -out=tfplan
# Require human approval gate before apply in production
terraform apply tfplan
```

**Common Mistakes:**
- Using local state in a team environment — the last `apply` to run wins, silently overwriting concurrent changes.
- Sharing a single state file between staging and production — a corrupted or incomplete production apply corrupts the staging state simultaneously.
- No S3 versioning — there is no recovery path if the state file is corrupted by a failed apply or manual edit.
- Committing `terraform.tfstate` to git — exposes all resource attributes including RDS passwords and private IP addresses in plaintext in version control history.

**Security Considerations:**
- Block all public access on the S3 bucket. Enable SSE-KMS with a dedicated KMS key.
- Use separate KMS keys per environment for the state bucket.
- Scope CI IAM roles to the minimum permissions needed per environment. Production roles must not be assumable from the same CI job that runs staging plans.
- Enable CloudTrail data events on the S3 bucket to audit every read and write of the state file.

**Testing Strategy:**
- Verify lock behavior: run two `terraform plan` processes concurrently and assert the second waits rather than proceeding with stale state.
- Test state recovery: delete the current state version from S3, restore the previous S3 version, run `terraform plan`, and assert it shows no changes.
- Assert bucket configuration in CI: `aws s3api get-bucket-versioning --bucket $TF_STATE_BUCKET` must return `Enabled`; `aws s3api get-bucket-encryption` must confirm KMS.

**Score:** Candidate (see [pattern-lifecycle.md](../../core/pattern-lifecycle.md))

**Official References:**
- Terraform S3 Backend: https://developer.hashicorp.com/terraform/language/backend/s3 (Official Documentation)
- Terraform State Locking: https://developer.hashicorp.com/terraform/language/state/locking (Official Documentation)

---

## Pattern: Secrets Management

**Problem:** Secrets hardcoded in environment variables, config files, or CI pipeline variables are leaked through application logs, git history, Docker image layers, and compromised CI pipelines. A single leaked credential is exploitable indefinitely if rotation requires a manual process.

**Solution:** Store all secrets in a dedicated secrets manager. Applications fetch secrets at startup or on-demand. Secrets rotate without redeployment. Every secret access is audited.

**Architecture:**
```
Application startup:
  → authenticate via IAM role / AppRole / OIDC (no long-lived key)
  → fetch secret by path from Secrets Manager / Vault / Doppler
  → parse JSON value → inject into process memory
  → never log, serialize, or include in error responses
  → re-fetch on TTL expiry or rotation signal

CI/CD pipeline:
  → exchange OIDC token for short-lived cloud credentials (no stored secrets)
  → fetch only the secrets needed for this specific job
  → credentials expire when the job ends

Secret rotation (automated):
  → Secrets Manager / Vault rotates on a schedule (Lambda or Vault lease)
  → application catches connection errors → re-fetches secret → reconnects
  → no redeployment required
```

**Implementation Notes:**
- Cache secret values in process memory for the process lifetime. Re-fetch when a TTL or rotation notification indicates the value has changed. Do not re-fetch on every request — this adds latency and can hit provider rate limits.
- Always fetch by logical name and version alias (`AWSCURRENT`), not by a specific version ARN. This ensures rotation transparently delivers the new value.
- Use separate secret paths per environment: `prod/api/db-password` vs `staging/api/db-password`. A staging secret compromise must not expose production credentials.
- Implement graceful rotation handling: catch authentication errors from DB connections, re-fetch the secret, and retry the connection before surfacing an error to the caller.
- Use dynamic secrets where available (Vault database secrets engine): each application instance receives a unique short-lived credential that is automatically revoked when the lease expires.

**Example Code:**
```typescript
// secrets.ts — AWS Secrets Manager with in-memory caching
import {
  SecretsManagerClient,
  GetSecretValueCommand,
} from '@aws-sdk/client-secrets-manager';

const client = new SecretsManagerClient({ region: process.env.AWS_REGION });
const cache = new Map<string, { value: string; fetchedAt: number }>();
const TTL_MS = 5 * 60 * 1000; // re-fetch every 5 minutes

export async function getSecret(secretName: string): Promise<string> {
  const cached = cache.get(secretName);
  if (cached && Date.now() - cached.fetchedAt < TTL_MS) {
    return cached.value;
  }

  const response = await client.send(
    new GetSecretValueCommand({
      SecretId: secretName,
      VersionStage: 'AWSCURRENT',
    })
  );

  const value = response.SecretString ?? '';
  cache.set(secretName, { value, fetchedAt: Date.now() });
  return value;
}

// Usage at startup — never pass the raw value to a logger
async function buildDatabaseConfig() {
  const raw = await getSecret(`${process.env.ENV}/api/db-credentials`);
  const { username, password, host, port, dbname } = JSON.parse(raw);
  return { user: username, password, host, port, database: dbname };
}
```

```typescript
// vault.ts — HashiCorp Vault with AppRole authentication
import axios from 'axios';

const VAULT_ADDR = process.env.VAULT_ADDR!;

async function vaultLogin(): Promise<string> {
  const res = await axios.post(`${VAULT_ADDR}/v1/auth/approle/login`, {
    role_id: process.env.VAULT_ROLE_ID,
    secret_id: process.env.VAULT_SECRET_ID,
  });
  return res.data.auth.client_token;
}

export async function getVaultSecret(path: string): Promise<Record<string, string>> {
  const token = await vaultLogin();
  const res = await axios.get(`${VAULT_ADDR}/v1/${path}`, {
    headers: { 'X-Vault-Token': token },
  });
  return res.data.data.data; // KV v2 response structure
}
```

**Secrets Manager Comparison:**

| Provider | Strengths | Weaknesses | Best For |
|---|---|---|---|
| AWS Secrets Manager | Native AWS IAM integration, automatic rotation via Lambda | Cost per secret ($0.40/month), AWS-only | AWS-native applications |
| HashiCorp Vault | Open source, multi-cloud, dynamic secrets, fine-grained policies | Operational complexity — must run and HA the Vault cluster | Multi-cloud, advanced rotation requirements |
| GCP Secret Manager | Native GCP IAM integration, simple API | GCP-only | GCP-native applications |
| Doppler | Developer-friendly UI, env variable injection, team sync | SaaS dependency, less granular rotation control | Teams prioritizing developer experience |

**Common Mistakes:**
- Setting secrets as `env:` values in Kubernetes Deployment manifests or Docker Compose files — they are visible in `kubectl describe pod` output.
- Logging secret values during startup debugging (`console.log('DB config:', config)`) — secrets appear in log aggregation systems indefinitely.
- One shared secret for all environments — a developer with staging access reads the production database password.
- No rotation strategy — a leaked credential remains valid until someone manually rotates it, which may be months after the leak.

**Security Considerations:**
- Never pass secrets as CLI arguments — they appear in the process listing (`ps aux`) and in shell history.
- Use IAM roles, Kubernetes service accounts with OIDC, or Vault AppRole — never long-lived access keys — for CI and application secret access.
- Enable secret access audit logging in all providers (CloudTrail for AWS Secrets Manager, Vault audit log, GCP audit log).
- Set short TTLs for dynamic secrets: database credentials should expire in 1 hour; API keys in 24 hours.

**Testing Strategy:**
- Assert no hardcoded secrets in source: run `grep -rE "(password|secret|api_key)\s*=\s*['\"][^'\"]{8,}"` over `*.ts` and `*.yaml` files in CI; fail if matches are found outside test fixtures.
- Test rotation: update the secret value in Secrets Manager, wait for the TTL to expire, assert the application uses the new value without restarting.
- Test missing secret: revoke the application's IAM permission, assert the application fails with a clear error message (`AccessDenied`) rather than a crash or silent null pointer.

**Score:** Candidate (see [pattern-lifecycle.md](../../core/pattern-lifecycle.md))

**Official References:**
- AWS Secrets Manager Developer Guide: https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html (Official Documentation)
- HashiCorp Vault Documentation: https://developer.hashicorp.com/vault/docs (Official Documentation)
- GCP Secret Manager Documentation: https://cloud.google.com/secret-manager/docs (Official Documentation)
- Kubernetes Secrets: https://kubernetes.io/docs/concepts/configuration/secret/ (Official Documentation)

---

## Pattern: Pulumi TypeScript Infrastructure

**Problem:** Infrastructure teams writing application code in TypeScript face a context switch writing HCL (Terraform). This leads to poor abstraction, copy-paste across modules, no type safety on resource outputs, and difficulty expressing conditional or loop-heavy configurations.

**Solution:** Use Pulumi with TypeScript to express infrastructure using the same language, type system, and package manager as the application. Extract reusable infrastructure components as typed `ComponentResource` classes with explicit input and output interfaces.

**Architecture:**
```
infrastructure/
  index.ts                    (stack entrypoint: instantiates top-level components)
  components/
    VpcComponent.ts           (extends pulumi.ComponentResource)
    RdsComponent.ts
    EcsServiceComponent.ts
  Pulumi.yaml                 (project metadata: name, runtime: nodejs)
  Pulumi.staging.yaml         (stack config: non-secret values)
  Pulumi.prod.yaml            (stack config: non-secret values)
  package.json
  tsconfig.json
```

**Implementation Notes:**
- Use `pulumi.ComponentResource` to bundle related resources into a single reusable unit with typed inputs and outputs. This is the Pulumi equivalent of a Terraform module.
- Stack configs (`Pulumi.<stack>.yaml`) replace `terraform.tfvars`. Use `pulumi config set --secret <key> <value>` for secrets — values are encrypted at rest using Pulumi's secrets provider (Pulumi Cloud KMS or a customer-managed key).
- `pulumi preview` is equivalent to `terraform plan`. Always run in CI before `pulumi up`. Review the diff before approving the merge.
- `pulumi.Output<T>` is an asynchronous wrapper around resource attribute values. Let outputs flow through the system as `Output<T>`. Using `.apply()` to extract a value for use in a conditional or as an object key breaks Pulumi's dependency graph.
- Pulumi state backends: Pulumi Cloud (managed, recommended for teams), S3 (self-managed), or Azure Blob Storage.

**Example Code:**
```typescript
// components/EcsServiceComponent.ts
import * as pulumi from '@pulumi/pulumi';
import * as aws from '@pulumi/aws';

export interface EcsServiceInputs {
  serviceName: pulumi.Input<string>;
  containerImage: pulumi.Input<string>;
  cpu: pulumi.Input<number>;
  memory: pulumi.Input<number>;
  containerPort: pulumi.Input<number>;
  desiredCount: pulumi.Input<number>;
  clusterId: pulumi.Input<string>;
  subnetIds: pulumi.Input<string[]>;
  securityGroupIds: pulumi.Input<string[]>;
  targetGroupArn: pulumi.Input<string>;
  tags?: pulumi.Input<{ [key: string]: pulumi.Input<string> }>;
}

export interface EcsServiceOutputs {
  serviceArn: pulumi.Output<string>;
  taskDefinitionArn: pulumi.Output<string>;
}

export class EcsServiceComponent
  extends pulumi.ComponentResource
  implements EcsServiceOutputs
{
  readonly serviceArn: pulumi.Output<string>;
  readonly taskDefinitionArn: pulumi.Output<string>;

  constructor(
    name: string,
    inputs: EcsServiceInputs,
    opts?: pulumi.ComponentResourceOptions,
  ) {
    super('myapp:infrastructure:EcsService', name, {}, opts);
    const childOpts = { parent: this };

    const taskDefinition = new aws.ecs.TaskDefinition(
      `${name}-task`,
      {
        family: inputs.serviceName,
        cpu: pulumi.output(inputs.cpu).apply(String),
        memory: pulumi.output(inputs.memory).apply(String),
        networkMode: 'awsvpc',
        requiresCompatibilities: ['FARGATE'],
        containerDefinitions: pulumi
          .all([inputs.serviceName, inputs.containerImage, inputs.containerPort])
          .apply(([svcName, image, port]) =>
            JSON.stringify([{
              name: svcName,
              image,
              portMappings: [{ containerPort: port, protocol: 'tcp' }],
              logConfiguration: {
                logDriver: 'awslogs',
                options: {
                  'awslogs-group': `/ecs/${svcName}`,
                  'awslogs-region': aws.config.region,
                  'awslogs-stream-prefix': 'ecs',
                },
              },
            }])
          ),
        tags: inputs.tags,
      },
      childOpts,
    );

    const service = new aws.ecs.Service(
      `${name}-service`,
      {
        name: inputs.serviceName,
        cluster: inputs.clusterId,
        taskDefinition: taskDefinition.arn,
        desiredCount: inputs.desiredCount,
        launchType: 'FARGATE',
        networkConfiguration: {
          subnets: inputs.subnetIds,
          securityGroups: inputs.securityGroupIds,
          assignPublicIp: false,
        },
        loadBalancers: [{
          targetGroupArn: inputs.targetGroupArn,
          containerName: inputs.serviceName,
          containerPort: inputs.containerPort,
        }],
        tags: inputs.tags,
      },
      childOpts,
    );

    this.serviceArn = service.id;
    this.taskDefinitionArn = taskDefinition.arn;
    this.registerOutputs({
      serviceArn: this.serviceArn,
      taskDefinitionArn: this.taskDefinitionArn,
    });
  }
}
```

```typescript
// index.ts — stack entrypoint
import * as pulumi from '@pulumi/pulumi';
import { EcsServiceComponent } from './components/EcsServiceComponent';

const config = new pulumi.Config();
const apiImage = config.require('apiImage');
const desiredCount = config.getNumber('desiredCount') ?? 2;
const privateSubnetIds = config.requireObject<string[]>('privateSubnetIds');

const apiService = new EcsServiceComponent('api', {
  serviceName: `api-${pulumi.getStack()}`,
  containerImage: apiImage,
  cpu: 256,
  memory: 512,
  containerPort: 3000,
  desiredCount,
  clusterId: config.require('clusterId'),
  subnetIds: privateSubnetIds,
  securityGroupIds: [config.require('apiSecurityGroupId')],
  targetGroupArn: config.require('apiTargetGroupArn'),
  tags: { Environment: pulumi.getStack(), ManagedBy: 'pulumi' },
});

export const serviceArn = apiService.serviceArn;
```

**Pulumi vs Terraform Comparison:**

| Aspect | Pulumi | Terraform |
|---|---|---|
| Language | TypeScript / Python / Go / C# / Java | HCL |
| Abstractions | Full programming language (classes, loops, conditionals) | Modules only; limited looping |
| Ecosystem | npm packages; reuse application utilities directly | Terraform Registry |
| State | Pulumi Cloud or self-managed (S3, Azure Blob) | S3 / Terraform Cloud |
| Testing | Node.js test frameworks (Jest, Mocha); unit mocking built-in | terratest (Go) or native tftest |
| Secret handling | Pulumi ESC; `config.requireSecret()` returns `Output<string>` | `sensitive = true`; encrypted in state |
| Learning curve | Low for TypeScript application developers | Low for operations engineers familiar with DSLs |

**Common Mistakes:**
- Mixing resources from multiple environments in a single Pulumi stack — use separate stacks (`pulumi stack select staging` / `pulumi stack select prod`) with separate stack config files.
- Calling `.apply()` on a `pulumi.Output<string>` that holds a secret to extract its value into a plain string — secrets leak into non-secret outputs and may appear in logs.
- Not setting `deleteBeforeReplace: true` on resources that cannot be updated in-place (e.g., IAM roles with name constraints) — Pulumi will attempt an update that AWS will reject with an error.

**Security Considerations:**
- Use Pulumi ESC (Environments, Secrets, Configurations) to centralize secret injection across stacks and environments.
- Never commit `Pulumi.<stack>.yaml` files with unencrypted secret values. Use `pulumi config set --secret <key>` — values are encrypted at rest using the stack's secrets provider.
- CI authenticates to Pulumi Cloud via short-lived OIDC tokens rather than stored access tokens. Use the `pulumi/auth-actions` GitHub Action.

**Testing Strategy:**
- Unit tests: mock Pulumi resources with `@pulumi/pulumi/testing`; set `pulumi.runtime.setMocks(...)` to intercept resource creation and assert outputs match expected values without deploying anything real.
- Integration tests: deploy to an ephemeral stack (`pulumi stack init test-pr-$PR_NUMBER`), run smoke tests against the deployed resources, destroy the stack regardless of test outcome.
- CI gate: run `pulumi preview --diff` on every pull request and post the diff as a PR comment for review before merge.

**Score:** Candidate (see [pattern-lifecycle.md](../../core/pattern-lifecycle.md))

**Official References:**
- Pulumi Documentation: https://www.pulumi.com/docs/ (Official Documentation)
- Pulumi Component Resources: https://www.pulumi.com/docs/concepts/resources/components/ (Official Documentation)
- Pulumi Testing Guide: https://www.pulumi.com/docs/using-pulumi/testing/ (Official Documentation)
- Pulumi ESC: https://www.pulumi.com/docs/esc/ (Official Documentation)
