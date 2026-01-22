---
name: local-k3d-testing
description: Test Eve Horizon deployments using a local k3d cluster. Ask user for stack operations.
---

# Local k3d Testing

## Purpose

Run production-like deployment tests locally using k3d (k3s in Docker). This gives you a real Kubernetes environment without cloud costs.

## CRITICAL: Do Not Control the k3d Stack

**Agents must NOT start, stop, or rebuild the k3d stack.**

The k3d cluster may be in use by agents working in `../eve-horizon`.

**If you cannot connect to Eve API:**
1. STOP what you're doing
2. Tell the user: "Cannot connect to Eve API. Please start/rebuild the k3d stack."
3. Provide the commands the USER should run
4. Wait for confirmation before proceeding

**Commands the USER runs (not the agent):**
```bash
cd ../eve-horizon
./bin/eh k8s start     # Start cluster
./bin/eh k8s deploy    # Deploy Eve stack
./bin/eh k8s stop      # Stop cluster
./bin/eh k8s status    # Check status
```

## Prerequisites

Before using this skill, ensure:
1. **User has started k3d** - Ask if unsure
2. **Docker Desktop** - Running with 8GB+ memory
3. **k3d** - Installed (`brew install k3d`)
4. **kubectl** - Installed (`brew install kubectl`)
5. **Eve CLI** - Available in PATH

## Agent Workflow

### Step 1: Verify Connectivity

```bash
export EVE_API_URL=http://api.eve.lvh.me
eve system health
```

**If this fails:**
```
I cannot connect to the Eve API at http://api.eve.lvh.me.

Please start the k3d stack by running these commands:
  cd ../eve-horizon
  ./bin/eh k8s start
  ./bin/eh k8s deploy

Let me know when the stack is ready.
```

### Step 2: Register Project (if needed)

```bash
eve org ensure test-org
eve project ensure \
  --name fullstack-example \
  --repo-url https://github.com/incept5/eve-horizon-fullstack-example \
  --branch main
```

### Step 3: Build and Import Images

Agents CAN build and import images (this doesn't affect the stack):

```bash
# Build Docker images
docker build -t ghcr.io/incept5/eve-horizon-fullstack-example-api:local apps/api
docker build -t ghcr.io/incept5/eve-horizon-fullstack-example-web:local apps/web

# Import to k3d (makes images available to cluster)
k3d image import ghcr.io/incept5/eve-horizon-fullstack-example-api:local -c eve-local
k3d image import ghcr.io/incept5/eve-horizon-fullstack-example-web:local -c eve-local
```

### Step 4: Deploy

```bash
eve env deploy <project-id> test --tag local
```

### Step 5: Verify Deployment

```bash
# Check pods are running
kubectl -n eve-fullstack-example-test get pods

# Test endpoints
curl http://api.fullstack-example-test.lvh.me/health
curl -I http://web.fullstack-example-test.lvh.me
```

## Testing Workflows

### Smoke Test

```bash
./scripts/smoke-test.sh
```

### Full Pipeline (if registry configured)

```bash
eve pipeline run deploy-test --project <id> --env test --wait
```

## Debugging (Read-Only Operations)

Agents CAN run kubectl commands to inspect state:

```bash
# List pods
kubectl -n eve-fullstack-example-test get pods

# Get pod logs
kubectl -n eve-fullstack-example-test logs deployment/api

# Describe pod
kubectl -n eve-fullstack-example-test describe pod <pod-name>

# Check events
kubectl -n eve-fullstack-example-test get events --sort-by='.lastTimestamp'
```

Agents CAN check Eve component logs:

```bash
kubectl -n eve logs deployment/eve-orchestrator --tail=50
kubectl -n eve logs deployment/eve-worker --tail=50
kubectl -n eve logs deployment/eve-api --tail=50
```

## Common Issues and User Actions

### "Connection refused" to Ingress URLs

**Tell the user:**
```
Cannot reach http://api.eve.lvh.me - connection refused.

The k3d cluster may be stopped. Please run:
  cd ../eve-horizon
  ./bin/eh k8s status   # Check current state
  ./bin/eh k8s start    # If stopped
  ./bin/eh k8s deploy   # Redeploy stack
```

### "Image not found" during deployment

**Agent can fix this:**
```bash
k3d image import ghcr.io/incept5/eve-horizon-fullstack-example-api:local -c eve-local
k3d image import ghcr.io/incept5/eve-horizon-fullstack-example-web:local -c eve-local
```

### Pods stuck in "Pending"

**Tell the user:**
```
Pods are stuck in Pending state. This usually means resource constraints.

Please check:
  kubectl describe node
  kubectl -n eve-fullstack-example-test get events

You may need to restart the k3d cluster with more resources:
  cd ../eve-horizon
  ./bin/eh k8s stop
  ./bin/eh k8s start
```

### Database connection errors

**Check first:**
```bash
kubectl -n eve-fullstack-example-test get pods -l app=db
kubectl -n eve-fullstack-example-test logs job/db-migrate
```

**If db pod is unhealthy, tell the user:**
```
The database pod is not healthy. This may require a stack rebuild.

Please run:
  cd ../eve-horizon
  ./bin/eh k8s deploy
```

## What Agents CAN Do

- Build Docker images
- Import images to k3d (`k3d image import`)
- Run `eve` CLI commands
- Run `kubectl` commands to inspect state
- Deploy environments
- Run smoke tests

## What Agents CANNOT Do

- Start the k3d cluster (`./bin/eh k8s start`)
- Deploy the Eve stack (`./bin/eh k8s deploy`)
- Stop the k3d cluster (`./bin/eh k8s stop`)
- Run any commands in `../eve-horizon`

## Quick Reference

| Action | Who | Command |
|--------|-----|---------|
| Start cluster | USER | `./bin/eh k8s start` |
| Deploy Eve stack | USER | `./bin/eh k8s deploy` |
| Stop cluster | USER | `./bin/eh k8s stop` |
| Check status | USER | `./bin/eh k8s status` |
| Build images | AGENT | `docker build ...` |
| Import images | AGENT | `k3d image import ...` |
| Deploy env | AGENT | `eve env deploy ...` |
| Check pods | AGENT | `kubectl get pods ...` |
| Get logs | AGENT | `kubectl logs ...` |
