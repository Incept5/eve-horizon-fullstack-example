---
name: local-k3d-testing
description: Test Eve Horizon deployments using a local k3d Kubernetes cluster.
---

# Local k3d Testing

## Purpose

Run production-like deployment tests locally using k3d (k3s in Docker). This gives you a real Kubernetes environment without cloud costs or remote access.

## Prerequisites

1. **Docker Desktop** - Running with 8GB+ memory, 4+ CPUs
2. **k3d** - `brew install k3d` or see https://k3d.io
3. **kubectl** - `brew install kubectl`
4. **Eve CLI** - Installed and available

## Setup Flow

### Step 1: Start the Eve Stack (from eve-horizon repo)

```bash
# Navigate to eve-horizon
cd ../eve-horizon

# Start k3d cluster and deploy Eve
./bin/eh k8s start
./bin/eh k8s deploy

# Verify stack is healthy
./bin/eh k8s status
```

This creates:
- k3d cluster named `eve-local`
- Namespace `eve` with API, orchestrator, worker, postgres
- Ingress routing via `*.lvh.me` (resolves to localhost)

### Step 2: Set API URL

```bash
# No port-forward needed - Ingress handles routing
export EVE_API_URL=http://api.eve.lvh.me

# Verify connectivity
eve system health
```

### Step 3: Register This Project

```bash
cd ../eve-horizon-fullstack-example

# Create org and project
eve org ensure test-org
eve project ensure \
  --name fullstack-example \
  --repo-url https://github.com/incept5/eve-horizon-fullstack-example \
  --branch main
```

## Testing Workflows

### Test 1: Build and Deploy Locally

```bash
# Build Docker images
docker build -t ghcr.io/incept5/eve-horizon-fullstack-example-api:local apps/api
docker build -t ghcr.io/incept5/eve-horizon-fullstack-example-web:local apps/web

# Import to k3d (makes images available to cluster)
k3d image import ghcr.io/incept5/eve-horizon-fullstack-example-api:local -c eve-local
k3d image import ghcr.io/incept5/eve-horizon-fullstack-example-web:local -c eve-local

# Deploy with local tag
eve env deploy <project-id> test --tag local
```

### Test 2: Verify Deployment

```bash
# Check pods are running
kubectl -n eve-fullstack-example-test get pods

# Test API health
curl http://api.fullstack-example-test.lvh.me/health

# Test web frontend
curl -I http://web.fullstack-example-test.lvh.me

# Test full status endpoint
curl http://api.fullstack-example-test.lvh.me/api/status
```

### Test 3: Run Smoke Tests

```bash
# Manual smoke test
./scripts/smoke-test.sh

# Or via pipeline (if registry is configured)
eve pipeline run deploy-test --project <id> --env test --wait
```

### Test 4: Test Database Operations

```bash
# Create a note (requires auth or test mode)
curl -X POST http://api.fullstack-example-test.lvh.me/notes \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Note", "body": "Hello from k3d"}'

# List notes
curl http://api.fullstack-example-test.lvh.me/notes
```

### Test 5: Full E2E Suite

Run the complete E2E test suite from eve-horizon:

```bash
cd ../eve-horizon

# Ensure this repo is pushed (tests clone via git!)
cd ../eve-horizon-fullstack-example
git status  # Commit any changes
git push

# Run E2E tests
cd ../eve-horizon
./bin/eh test e2e --env stack
```

## Debugging in k3d

### Check Pod Status

```bash
# List all pods in the environment namespace
kubectl -n eve-fullstack-example-test get pods

# Describe a specific pod
kubectl -n eve-fullstack-example-test describe pod <pod-name>

# Get pod logs
kubectl -n eve-fullstack-example-test logs deployment/api
kubectl -n eve-fullstack-example-test logs deployment/web
```

### Check Eve Components

```bash
# Eve namespace pods
kubectl -n eve get pods

# Orchestrator logs (job claiming, workspace creation)
kubectl -n eve logs deployment/eve-orchestrator --tail=50

# Worker logs (harness execution)
kubectl -n eve logs deployment/eve-worker --tail=50

# API logs (request handling)
kubectl -n eve logs deployment/eve-api --tail=50
```

### Check Ingress

```bash
# List ingress rules
kubectl get ingress -A

# Check specific environment ingress
kubectl -n eve-fullstack-example-test get ingress
```

### Database Access

```bash
# Port-forward to postgres (if needed)
kubectl -n eve-fullstack-example-test port-forward svc/db 5432:5432

# Connect with psql
psql postgres://eve:eve@localhost:5432/eve
```

## Common Issues

### "Connection refused" to Ingress URLs

```bash
# Check if k3d cluster is running
k3d cluster list

# Restart cluster if needed
cd ../eve-horizon
./bin/eh k8s stop
./bin/eh k8s start
./bin/eh k8s deploy
```

### "Image not found" during deployment

```bash
# Re-import images to k3d
k3d image import ghcr.io/incept5/eve-horizon-fullstack-example-api:local -c eve-local
k3d image import ghcr.io/incept5/eve-horizon-fullstack-example-web:local -c eve-local
```

### Pods stuck in "Pending"

```bash
# Check for resource constraints
kubectl describe node

# Check events
kubectl -n eve-fullstack-example-test get events --sort-by='.lastTimestamp'
```

### Database connection errors

```bash
# Check db pod is healthy
kubectl -n eve-fullstack-example-test get pods -l app=db

# Check migrations ran
kubectl -n eve-fullstack-example-test logs job/db-migrate
```

## Cleanup

```bash
# Delete environment namespace
kubectl delete namespace eve-fullstack-example-test

# Or stop entire k3d cluster
cd ../eve-horizon
./bin/eh k8s stop
```

## Quick Reference

| Action | Command |
|--------|---------|
| Start cluster | `./bin/eh k8s start && ./bin/eh k8s deploy` |
| Stop cluster | `./bin/eh k8s stop` |
| Check status | `./bin/eh k8s status` |
| Import image | `k3d image import <image>:local -c eve-local` |
| Deploy env | `eve env deploy <project-id> test --tag local` |
| Get pods | `kubectl -n eve-fullstack-example-test get pods` |
| Get logs | `kubectl -n eve-fullstack-example-test logs deploy/api` |

## Tips

1. **Always import images after rebuild** - k3d doesn't auto-sync with Docker
2. **Check orchestrator logs for job failures** - Not harness logs
3. **Use `--tag local`** to skip registry pulls
4. **lvh.me resolves to 127.0.0.1** - No /etc/hosts changes needed
