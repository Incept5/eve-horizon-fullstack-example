# Eve Horizon Fullstack Example - Agent Guide

> **Purpose**: Living document for AI agents. This repo is the canonical example for Eve Horizon projects.
>
> **Last Updated**: 2026-01-22

For human documentation (setup, endpoints, directory structure), see [README.md](./README.md).

---

## Quick Start

```bash
# Prerequisites: Eve CLI installed, k3d cluster running with Eve deployed

# 1. Set API URL (no port-forward needed with Ingress)
export EVE_API_URL=http://api.eve.lvh.me

# 2. Register this project with Eve
eve org ensure test-org
eve project ensure \
  --name fullstack-example \
  --repo-url https://github.com/incept5/eve-horizon-fullstack-example \
  --branch main

# 3. Deploy to test environment
eve env deploy <project-id> test --tag local

# 4. Access the deployed app (no port-forward!)
open http://web.fullstack-example-test.lvh.me
open http://api.fullstack-example-test.lvh.me/health
```

**URL Pattern**: `{component}.{project}-{env}.lvh.me`

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

Use the `/sync-with-eve-horizon` skill to check this repo against the sister project:

```bash
# The skill will:
# 1. Check manifest.yaml against latest eve-horizon spec
# 2. Verify CLI commands in docs match current eve CLI
# 3. Report any drift or needed updates
# 4. Propose changes to THIS repo only (not eve-horizon)
```

---

## Manifest Structure

The `.eve/manifest.yaml` defines the complete deployment model:

```yaml
name: fullstack-example

# Container registry for images
registry:
  host: ghcr.io
  namespace: incept5
  auth:
    username_secret: GHCR_USERNAME
    token_secret: GHCR_TOKEN

# Components: api, web, db
components:
  api:
    image: ghcr.io/incept5/eve-horizon-fullstack-example-api
    port: 3000
    depends_on:
      db: { condition: healthy, migrations: true }

  web:
    image: ghcr.io/incept5/eve-horizon-fullstack-example-web
    port: 80
    depends_on:
      api: { condition: healthy }

  db:
    type: database
    image: postgres:16
    migrations:
      path: .eve/migrations
      on_deploy: true

# Environments with pipelines
environments:
  test:     { pipeline: deploy-test, db_ref: db }
  staging:  { pipeline: deploy-staging, db_ref: db }
  production: { pipeline: deploy-production, approval: required, db_ref: db }

# Pipelines: deterministic action sequences
pipelines:
  deploy-test:    [build, release, deploy, smoke-test]
  deploy-staging: [build, release, deploy]
  deploy-production: [build, release, deploy]

# Event-driven CI/CD
pipelines:
  ci-main:
    trigger: { event: github.push, branch: main }
    steps: [build, test, deploy-staging]
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

# 4. Deploy with local tag
eve env deploy <project-id> test --tag local

# 5. Access via Ingress
curl http://api.fullstack-example-test.lvh.me/health
```

---

## Testing Workflows

### Smoke Test (Post-Deploy)

```bash
# Run the smoke test script
./scripts/smoke-test.sh

# Or via Eve pipeline (includes build + deploy + test)
eve pipeline run deploy-test --project <id> --env test --wait
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
eve pipeline run deploy-test --project <id> --env test --ref main --wait
```

### Environment Operations

```bash
# Deploy to environment
eve env deploy <project-id> <env> --tag <tag>

# Quick deploy (uses env's pipeline)
eve env deploy test --ref main
```

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

| Skill | Description |
|-------|-------------|
| `/eve-horizon-dev` | PR-style development workflow |
| `/sync-with-eve-horizon` | Check and sync with sister repo |
| `/eve-cli-workflows` | Learn Eve CLI patterns |
| `/local-k3d-testing` | Test with local k3d stack |

---

## Troubleshooting

### "Cannot connect to database"

```bash
# Check if db component is healthy
kubectl -n eve-fullstack-example-test get pods

# Check environment variables
kubectl -n eve-fullstack-example-test exec deploy/api -- env | grep DATABASE
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

- **2026-01-22**: Created AGENTS.md with comprehensive agent guide, added sync and workflow skills
- **2026-01-22**: Added event-driven pipelines and workflows to manifest
- **2026-01-22**: Added component healthchecks, dependencies, and migrations

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
