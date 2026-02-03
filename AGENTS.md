# Eve Horizon Fullstack Example - Agent Guide

> **Purpose**: Living document for AI agents. This repo is the canonical example for Eve Horizon projects.
>
> **Last Updated**: 2026-01-23

For human documentation (setup, endpoints, directory structure), see [README.md](./README.md).

---

## Quick Start

```bash
# Prerequisites: Eve CLI installed, k3d cluster running with Eve deployed

# 1. Set API URL (no port-forward needed with Ingress)
export EVE_API_URL=http://api.eve.lvh.me

# 2. Register this project with Eve
eve org ensure test-org --slug torg
eve project ensure \
  --name fullstack-example \
  --repo-url https://github.com/incept5/eve-horizon-fullstack-example \
  --branch main

# 3. Deploy to test environment
# Note: --ref is required (40-character SHA or a ref resolved against --repo-dir)
eve env deploy test --ref main --repo-dir .

# 4. Access the deployed app (no port-forward!)
open http://web.torg-fullstack-example-test.lvh.me
open http://api.torg-fullstack-example-test.lvh.me/health
```

**URL Pattern**: `{component}.{orgSlug}-{project}-{env}.lvh.me`

---

## This Repo's Purpose

This repository serves three critical functions:

1. **Canonical Example**: Shows the correct structure for Eve Horizon projects
2. **E2E Test Fixture**: Used by `../eve-horizon` to validate deployment pipelines
3. **Documentation Reference**: Demonstrates manifest patterns, pipelines, and workflows

**IMPORTANT**: Changes here affect Eve Horizon's E2E tests. After modifying this repo:
```bash
git add -A && git commit -m "feat: description" && git push
# E2E tests clone via git - push is required before testing
```

---

## Sister Repository Coordination

This repo works alongside `../eve-horizon` (the main Eve Horizon project).

| Repo | Path | Relationship |
| --- | --- | --- |
| eve-horizon | `../eve-horizon` | Source of truth for Eve CLI, manifest spec, deployment model |
| eve-skillpacks | `../eve-skillpacks` | Published skills (referenced in `skills.txt`) |

### CRITICAL: Read-Only Access to Sister Repos

**Agents in this repo must NOT modify `../eve-horizon` or `../eve-skillpacks`.**

When you detect drift or issues:
1. **Read and analyze** the sister repo files
2. **Surface the issue** to the user with specific details
3. **Propose changes** for this repo only
4. **Ask the user** to make any changes needed in eve-horizon

This prevents conflicts when agents are working in both repos simultaneously.

### Staying in Sync

Use the `eve-repo-upkeep` skill to check this repo against platform conventions:

```bash
# The skill will:
# 1. Check manifest.yaml schema and structure
# 2. Verify CLI commands match current eve CLI
# 3. Report any drift or needed updates
```

---

## Manifest Structure (v2 Compose Spec)

The `.eve/manifest.yaml` uses the v2 compose specification:

```yaml
schema: eve/compose/v1
project: fullstack-example

# Container registry for images
registry:
  host: ghcr.io
  namespace: incept5
  auth:
    username_secret: GHCR_USERNAME
    token_secret: GHCR_TOKEN

# Services (Docker Compose style with x-eve extensions)
services:
  api:
    image: ghcr.io/incept5/eve-horizon-fullstack-example-api
    build:
      context: ./apps/api
      dockerfile: ./apps/api/Dockerfile
    ports: [3000]
    depends_on:
      db:
        condition: service_healthy    # v2 uses service_healthy
    x-eve:
      api_spec:
        type: openapi
        spec_url: /openapi.json

  web:
    image: ghcr.io/incept5/eve-horizon-fullstack-example-web
    ports: [80]
    depends_on:
      api:
        condition: service_healthy

  db:
    image: postgres:16
    x-eve:
      role: database

# Environments (pipeline assignments)
environments:
  test:
    pipeline: deploy-test
  staging:
    pipeline: deploy-staging
  production:
    pipeline: deploy-production
    approval: required

# Pipelines with explicit step dependencies
pipelines:
  deploy-test:
    steps:
      - name: build
        action: { type: build }
      - name: release
        depends_on: [build]
        action: { type: release }
      - name: deploy
        depends_on: [release]
        action: { type: deploy }
      - name: smoke-test
        depends_on: [deploy]
        script:
          run: ./scripts/smoke-test.sh
          timeout: 300

  # Event-driven CI/CD
  ci-main:
    trigger:
      github:
        event: push
        branch: main
    steps:
      - name: build
        script: { run: npm run build }
      - name: test
        depends_on: [build]
        script: { run: npm test }
```

### Variable Interpolation

Available in env vars and some fields:
- `${ENV_NAME}` - Current environment (test, staging, production)
- `${PROJECT_ID}` - Project ID
- `${ORG_ID}` - Organization ID
- `${COMPONENT_NAME}` - Component name
- `${secret.KEY_NAME}` - From `.eve/secrets.yaml`

---

## Local Development

### Without Eve (Pure Docker)

```bash
# Start database
docker compose up -d db

# Run API (hot-reload)
cd apps/api && npm install && npm run dev

# Run Web (hot-reload)
cd apps/web && npm install && npm run dev
```

### With Eve (k3d Local Stack)

**CRITICAL: Agents must NOT start, stop, or rebuild the k3d stack.**

The k3d cluster may be in use by agents working in `../eve-horizon`. If you cannot connect:
1. **Stop and ask the user** to start/rebuild the stack
2. **Do not run** `./bin/eh k8s start`, `./bin/eh k8s deploy`, or `./bin/eh k8s stop`

**Prerequisite**: Ask user to ensure k3d is running:
```bash
# USER should run this in ../eve-horizon (not the agent)
cd ../eve-horizon
./bin/eh k8s start
./bin/eh k8s deploy
```

**Agent workflow** (once stack is running):
```bash
# 1. Set API URL and verify connectivity
export EVE_API_URL=http://api.eve.lvh.me
eve system health  # If this fails, ASK USER to restart stack

# 2. Register this project
eve project ensure --name fullstack-example \
  --repo-url https://github.com/incept5/eve-horizon-fullstack-example \
  --branch main

# 3. Build and import images to k3d
docker build -t ghcr.io/incept5/eve-horizon-fullstack-example-api:local apps/api
docker build -t ghcr.io/incept5/eve-horizon-fullstack-example-web:local apps/web
k3d image import ghcr.io/incept5/eve-horizon-fullstack-example-api:local -c eve-local
k3d image import ghcr.io/incept5/eve-horizon-fullstack-example-web:local -c eve-local

# 4. Deploy with local tag (--ref required)
eve env deploy test --ref main --repo-dir .

# 5. Access via Ingress
curl http://api.torg-fullstack-example-test.lvh.me/health
```

---

## Testing Workflows

### Smoke Test (Post-Deploy)

```bash
# Run the smoke test script
./scripts/smoke-test.sh

# Or via Eve pipeline (includes build + deploy + test)
eve pipeline run deploy-test --project <id> --env test --ref main --repo-dir . --wait
```

### As E2E Test Fixture

From the `../eve-horizon` repo:

```bash
# E2E tests clone this repo and run full deployment cycles
./bin/eh test e2e --env stack
```

The E2E tests:
1. Create an org and project pointing to this repo
2. Run pipelines (build, release, deploy)
3. Verify health endpoints respond
4. Clean up

---

## CLI Command Reference

### Project Lifecycle

```bash
# Register project
eve project ensure --name NAME --repo-url URL --branch BRANCH

# Sync manifest to Eve
eve project sync

# List pipelines
eve pipeline list --project <id>

# Show pipeline details
eve pipeline show deploy-test --project <id>

# Run pipeline
eve pipeline run deploy-test --project <id> --env test --ref main --repo-dir . --wait
```

### Environment Operations

```bash
# Deploy to environment (--ref is REQUIRED: 40-character SHA or ref resolved via --repo-dir)
eve env deploy <env> --ref <git-ref> --repo-dir ./my-app

# Examples:
eve env deploy test --ref main --repo-dir .
eve env deploy staging --ref 0123456789abcdef0123456789abcdef01234567

# Promotion flow:
# 1. Build in test
eve env deploy test --ref 0123456789abcdef0123456789abcdef01234567

# 2. Get release info
eve release resolve v1.2.3

# 3. Promote to staging (reuse same ref, pass release_id)
eve env deploy staging --ref 0123456789abcdef0123456789abcdef01234567 --inputs '{"release_id":"rel_xxx"}'
```

### Builds

Eve Horizon tracks builds as first-class primitives. Each build creates a **BuildSpec** (what to build), **BuildRun** (execution), and **BuildArtifact** (image digests).

```bash
# List builds for a project
eve build list --project <id>

# Show build details
eve build show <build_id>

# Create a new build spec
eve build create --project <id> --ref <sha> --manifest-hash <hash> [--services <list>]

# Run a build (creates BuildRun)
eve build run <build_id>

# View build runs
eve build runs <build_id>

# View build logs
eve build logs <build_id> [--run <id>]

# View build artifacts (image digests)
eve build artifacts <build_id>

# Diagnose build failures
eve build diagnose <build_id>

# Cancel a running build
eve build cancel <build_id>
```

**Build Flow:**
- Deploy pipelines automatically create BuildSpec + BuildRun records during the `build` step
- Build backends: Docker Buildx (local), BuildKit (K8s default), Kaniko (fallback)
- Artifacts track image digests (sha256:...) for immutable deployments
- Releases reference `build_id` with digest-based image references

**Debugging builds:**
- Use `eve build diagnose <build_id>` as the primary debugging tool for build failures
- Check build logs with `eve build logs <build_id>`
- View artifacts to verify images were pushed correctly

### Debugging

```bash
# Check system health
eve system health

# Job diagnostics
eve job diagnose <job-id>
eve job logs <job-id>
eve job follow <job-id>  # Real-time logs
```

---

## Component Architecture

```
apps/
├── api/                    # NestJS backend
│   ├── src/
│   │   ├── main.ts        # Bootstrap, listens on PORT
│   │   ├── app.module.ts  # NestJS module
│   │   ├── app.service.ts # Business logic + DB
│   │   ├── eve-auth.ts    # JWT verification via JWKS
│   │   └── db.ts          # PostgreSQL pool
│   └── Dockerfile         # Multi-stage build
│
└── web/                    # React frontend
    ├── src/
    │   ├── App.tsx        # Main component
    │   └── main.tsx       # Entry point
    ├── vite.config.ts     # Dev proxy to API
    └── Dockerfile         # Build + nginx serve
```

### API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | No | Health check (includes DB) |
| GET | `/notes` | Optional | List notes (RLS enforced) |
| POST | `/notes` | Required | Create note |
| GET | `/openapi.json` | No | OpenAPI spec |
| GET | `/api/status` | No | System status |

### Authentication Flow

1. Eve injects `EVE_JWKS_URL` into containers
2. API fetches JWKS and validates JWT signatures
3. Claims (`user_id`, `org_id`, `scopes`) set as Postgres session vars
4. Row-level security (RLS) enforces data isolation

---

## Database & Migrations

### Schema Location

- **Migrations**: `.eve/migrations/` (auto-applied on deploy)
- **Local schema**: `db/schema.sql` (for docker-compose)
- **Seed data**: `db/seed.sql`

### RLS Pattern

```sql
-- All notes table queries filter by current user
CREATE POLICY notes_select ON notes FOR SELECT
  USING (user_id = current_setting('app.user_id', true));
```

The API sets session vars before queries:
```typescript
await pool.query(`SET app.user_id = '${userId}'`);
await pool.query(`SET app.org_id = '${orgId}'`);
```

---

## When Making Changes

### Manifest Changes

1. Edit `.eve/manifest.yaml`
2. Commit and push (E2E tests need to clone)
3. From `../eve-horizon`, run E2E tests to verify

### Code Changes

1. Make changes in `apps/api` or `apps/web`
2. Test locally with `npm run dev`
3. Build Docker images and verify
4. Commit and push

### Adding New Pipelines/Workflows

1. Add to `.eve/manifest.yaml` under `pipelines:` or `workflows:`
2. Ensure any referenced scripts exist in `scripts/`
3. Test via `eve pipeline run` or `eve workflow run`

---

## Skills Available

Skills are installed via `eve-skillpacks` (see `skills.txt`). Key skills:

| Skill | Description |
|-------|-------------|
| `eve-manifest-authoring` | Manifest editing and validation |
| `eve-deploy-debugging` | Deploy and debug Eve apps |
| `eve-repo-upkeep` | Keep repo aligned with platform conventions |
| `eve-cli-primitives` | Core CLI commands reference |
| `eve-troubleshooting` | CLI-first diagnostics |
| `eve-local-dev-loop` | Docker Compose local dev |

Run `openskills list` to see all installed skills.

---

## Troubleshooting

### "Cannot connect to database"

```bash
# Check if db component is healthy
kubectl -n eve-torg-fullstack-example-test get pods

# Check environment variables
kubectl -n eve-torg-fullstack-example-test exec deploy/api -- env | grep DATABASE
```

### "Image not found"

```bash
# Ensure images are imported to k3d
k3d image import ghcr.io/incept5/eve-horizon-fullstack-example-api:local -c eve-local
```

### "Pipeline failed"

```bash
# Get detailed job output
eve job diagnose <job-id>

# Check orchestrator/worker logs
kubectl -n eve logs deployment/eve-orchestrator --tail=100
kubectl -n eve logs deployment/eve-worker --tail=100
```

---

## Update Log

- **2026-01-22**: Created AGENTS.md with comprehensive agent guide
- **2026-01-22**: Added event-driven pipelines and workflows to manifest
- **2026-01-22**: Added component healthchecks, dependencies, and migrations
- **2026-01-23**: Updated manifest to new trigger/step schema
- **2026-01-28**: Migrated manifest to full v2 compose spec
- **2026-01-28**: Removed custom skills in favor of eve-skillpacks (aligned with eve-horizon-starter)

---

## Critical Restrictions

**DO NOT** (ask the user instead):
1. **Modify `../eve-horizon`** - Surface issues, propose changes, but do not edit files there
2. **Start/stop/rebuild k3d** - Ask the user to run `./bin/eh k8s start|deploy|stop`
3. **Run commands in `../eve-horizon`** - Only read files for reference

**DO**:
1. **Push before E2E tests** - Tests clone via git, not local filesystem
2. **Keep manifest in sync** - This is the canonical example; patterns should match eve-horizon docs
3. **Test changes locally first** - Use docker-compose before k3d deployment
4. **Update AGENTS.md** - When adding new patterns or changing workflows
5. **Ask the user** - When you can't connect to Eve API or k3d cluster

<skills_system priority="1">

## Available Skills

<!-- SKILLS_TABLE_START -->
<usage>
When users ask you to perform tasks, check if any of the available skills below can help complete the task more effectively. Skills provide specialized capabilities and domain knowledge.

How to use skills:
- Invoke: Bash("openskills read <skill-name>")
- The skill content will load with detailed instructions on how to complete the task
- Base directory provided in output for resolving bundled resources (references/, scripts/, assets/)

Usage notes:
- Only use skills listed in <available_skills> below
- Do not invoke a skill that is already loaded in your context
- Each skill invocation is stateless
</usage>

<available_skills>

<skill>
<name>eve-auth-and-secrets</name>
<description>Authenticate with Eve and manage project secrets for deployments and workflows.</description>
<location>project</location>
</skill>

<skill>
<name>eve-cli-primitives</name>
<description>Core Eve CLI primitives and capabilities for app developers. Use as the quick reference for commands and flows.</description>
<location>project</location>
</skill>

<skill>
<name>eve-deploy-debugging</name>
<description>Deploy and debug Eve-compatible apps via the CLI, with a focus on staging environments.</description>
<location>project</location>
</skill>

<skill>
<name>eve-job-debugging</name>
<description>Monitor and debug Eve jobs with CLI follow, logs, wait, and diagnose commands. Use when work is stuck, failing, or you need fast status.</description>
<location>project</location>
</skill>

<skill>
<name>eve-job-lifecycle</name>
<description>Create, manage, and review Eve jobs, phases, and dependencies. Use when running knowledge work in Eve or structuring job hierarchies.</description>
<location>project</location>
</skill>

<skill>
<name>eve-local-dev-loop</name>
<description>Local Docker Compose development loop for Eve-compatible apps, with handoff to staging deploys.</description>
<location>project</location>
</skill>

<skill>
<name>eve-manifest-authoring</name>
<description>Author and maintain Eve manifest files (.eve/manifest.yaml) for services, environments, pipelines, workflows, and secret interpolation. Use when changing deployment shape or runtime configuration in an Eve-compatible repo.</description>
<location>project</location>
</skill>

<skill>
<name>eve-new-project-setup</name>
<description>Configure a new Eve Horizon project after running eve init (profile, auth, manifest, and repo linkage).</description>
<location>project</location>
</skill>

<skill>
<name>eve-orchestration</name>
<description>Orchestrate jobs via depth propagation, parallel decomposition, relations, and control signals</description>
<location>project</location>
</skill>

<skill>
<name>eve-pipelines-workflows</name>
<description>Define and run Eve pipelines and workflows via manifest and CLI. Use when wiring build, release, deploy flows or invoking workflow jobs.</description>
<location>project</location>
</skill>

<skill>
<name>eve-plan-implementation</name>
<description>Execute software engineering plan documents using Eve jobs, dependencies, and review gating.</description>
<location>project</location>
</skill>

<skill>
<name>eve-project-bootstrap</name>
<description>Bootstrap an Eve-compatible project with org/project setup, profile defaults, repo linkage, and first deploy.</description>
<location>project</location>
</skill>

<skill>
<name>eve-read-eve-docs</name>
<description>Load first. Index of distilled Eve Horizon system docs for CLI usage, manifests, pipelines, jobs, secrets, and debugging.</description>
<location>project</location>
</skill>

<skill>
<name>eve-repo-upkeep</name>
<description>Keep Eve-compatible repos aligned with platform best practices and current manifest conventions.</description>
<location>project</location>
</skill>

<skill>
<name>eve-se-index</name>
<description>Load this first. Routes to the right Eve SE skill for developing, deploying, and debugging Eve-compatible apps.</description>
<location>project</location>
</skill>

<skill>
<name>eve-skill-distillation</name>
<description>Distill repeated work into Eve skillpacks by creating or updating skills with concise instructions and references. Use when a workflow repeats or knowledge should be shared across agents.</description>
<location>project</location>
</skill>

<skill>
<name>eve-troubleshooting</name>
<description>Troubleshoot common Eve deploy and job failures using CLI-first diagnostics.</description>
<location>project</location>
</skill>

</available_skills>
<!-- SKILLS_TABLE_END -->

</skills_system>
