---
name: eve-cli-workflows
description: Learn and execute Eve CLI workflows for project management, deployment, and debugging.
---

# Eve CLI Workflows

## Purpose

Master the Eve CLI for managing projects, running pipelines, and debugging deployments. This skill teaches the primary workflows you'll use daily.

## Prerequisites

```bash
# Ensure Eve CLI is available
eve --version

# Set API URL (for local k3d stack)
export EVE_API_URL=http://api.eve.lvh.me
```

## Core Workflows

### 1. Project Registration

Register this repo as an Eve project:

```bash
# Create or ensure org exists
eve org ensure "My Org"

# Register project with repo URL
eve project ensure \
  --name fullstack-example \
  --repo-url https://github.com/incept5/eve-horizon-fullstack-example \
  --branch main

# Set as default project for subsequent commands
eve profile set --project <project-id>
```

### 2. Pipeline Inspection

Understand what pipelines are available:

```bash
# List all pipelines
eve pipeline list --project <project-id>

# Show pipeline details (actions, triggers)
eve pipeline show deploy-test --project <project-id>

# View deterministic pipelines
eve pipeline show deploy-staging --project <project-id>
```

### 3. Running Pipelines

Execute deployment pipelines:

```bash
# Run pipeline with specific ref (commit/tag)
eve pipeline run deploy-test \
  --project <project-id> \
  --env test \
  --ref main \
  --wait

# Quick deploy using environment's default pipeline
eve env deploy <project-id> test --ref main
```

### 4. Environment Deployment (Local Images)

For local development with k3d:

```bash
# Build images locally
docker build -t ghcr.io/incept5/eve-horizon-fullstack-example-api:local apps/api
docker build -t ghcr.io/incept5/eve-horizon-fullstack-example-web:local apps/web

# Import to k3d cluster
k3d image import ghcr.io/incept5/eve-horizon-fullstack-example-api:local -c eve-local
k3d image import ghcr.io/incept5/eve-horizon-fullstack-example-web:local -c eve-local

# Deploy with local tag (skips registry pull)
eve env deploy <project-id> test --tag local
```

### 5. Job Management

Work with jobs (pipeline runs):

```bash
# List recent jobs
eve job list --project <project-id>

# Show job status
eve job show <job-id>
eve job show <job-id> --verbose  # With attempt details

# Watch job in real-time
eve job follow <job-id>

# Get job logs after completion
eve job logs <job-id>

# Wait for job completion
eve job wait <job-id> --timeout 300
```

### 6. Debugging

When things go wrong:

```bash
# Comprehensive job diagnosis
eve job diagnose <job-id>

# System health check
eve system health

# Check harness availability
eve harness list --json
```

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `EVE_API_URL` | Eve API endpoint | `http://api.eve.lvh.me` |
| `EVE_DEFAULT_PROJECT` | Default project for commands | `proj_abc123` |

## Common Patterns

### Deploy and Verify

```bash
# Full deploy cycle with verification
eve pipeline run deploy-test --project <id> --env test --ref main --wait

# Verify deployment
curl http://api.fullstack-example-test.lvh.me/health
curl http://web.fullstack-example-test.lvh.me
```

### Quick Iteration Loop

```bash
# 1. Make code changes
vim apps/api/src/app.service.ts

# 2. Build and import
docker build -t ghcr.io/incept5/eve-horizon-fullstack-example-api:local apps/api
k3d image import ghcr.io/incept5/eve-horizon-fullstack-example-api:local -c eve-local

# 3. Deploy
eve env deploy <project-id> test --tag local

# 4. Test
curl http://api.fullstack-example-test.lvh.me/health
```

### Debug Failed Deployment

```bash
# 1. Check job status
eve job show <job-id> --verbose

# 2. Get detailed diagnosis
eve job diagnose <job-id>

# 3. Check pod status
kubectl -n eve-fullstack-example-test get pods
kubectl -n eve-fullstack-example-test describe pod <pod-name>

# 4. Check pod logs
kubectl -n eve-fullstack-example-test logs deployment/api
```

## Output Formats

Most commands support JSON output for scripting:

```bash
# Get project ID for scripts
PROJECT_ID=$(eve project show fullstack-example --json | jq -r '.id')

# List jobs as JSON
eve job list --project $PROJECT_ID --json

# Parse job status
eve job show <job-id> --json | jq '.phase'
```

## Tips

1. **Use `--wait`** for pipeline runs to block until completion
2. **Use `--json`** for scripting and automation
3. **Check `eve job diagnose`** first when debugging failures
4. **Set `EVE_DEFAULT_PROJECT`** to avoid repeating `--project` flags
