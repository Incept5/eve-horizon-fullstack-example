# Eve Horizon Fullstack Example

Canonical example repo for Eve Horizon, demonstrating persistent environments and Docker-based deployments.

**Stack:**
- React (Vite) frontend in `apps/web`
- NestJS API in `apps/api`
- Postgres database

**Environments:**
- `test` - Integration testing
- `staging` - Pre-production validation
- `production` - Live environment (requires approval)

## Eve Horizon Setup

```bash
# 1. Register the project with Eve Horizon
eve project ensure \
  --name fullstack-example \
  --repo-url https://github.com/incept5/eve-horizon-fullstack-example \
  --branch main

# 2. Sync the manifest (pushes .eve/manifest.yaml to Eve)
eve project sync

# 3. Inspect pipelines
eve pipeline list --project <project-id>
eve pipeline show deploy-test --project <project-id>

# 4. Run a deterministic pipeline
eve pipeline run deploy-test --project <project-id> --env test --ref main --repo-dir . --wait

# Optional: env deploy shortcut (maps to the env's pipeline)
# Note: --ref is required (40-character SHA or a ref resolved against --repo-dir)
eve env deploy test --ref main --repo-dir .
```

### Auth (SSH-only)

Eve Horizon uses GitHub SSH key login. For local stacks, bootstrap the first admin:

```bash
export EVE_BOOTSTRAP_TOKEN=test-bootstrap-token
eve auth bootstrap --email admin@example.com --public-key ~/.ssh/id_ed25519.pub
```

Then login with SSH challenge/verify:

```bash
eve auth login --email admin@example.com --private-key ~/.ssh/id_ed25519
```

### Webhook Secrets

If you plan to use GitHub/Slack triggers, configure secrets on the Eve stack:

```bash
export EVE_GITHUB_WEBHOOK_SECRET=your-github-secret
export EVE_SLACK_SIGNING_SECRET=your-slack-secret
```

## Docker Image Build

The project includes Dockerfiles for both components:

```bash
# Build API image
docker build -t ghcr.io/incept5/eve-horizon-fullstack-example-api:latest apps/api

# Build Web image
docker build -t ghcr.io/incept5/eve-horizon-fullstack-example-web:latest apps/web
```

## Manifest Structure

The `.eve/manifest.yaml` defines:

- **components**: Docker images for api and web
- **environments**: test, staging, production with resource limits
- **databases**: Postgres database shared across environments
- **apis**: OpenAPI source for the API (used by `eve api` commands)
- **migrations**: SQL migrations for the environment database
- **registry**: container registry settings for build actions
- **tests**: smoke test command references
- **pipelines**: deterministic build/release/deploy actions per env + CI triggers
- **triggers**: embedded in pipelines via `trigger.github` or `trigger.system`
- **workflows**: manual operations and remediation

## Local Development (Docker Compose)

```bash
# Start the database
cp .env.example .env
docker compose up -d db

# Run the API
cd apps/api
npm install
npm run dev

# Run the Web frontend
cd apps/web
npm install
npm run dev
```

**Default endpoints:**
- Web: http://localhost:5173
- API: http://localhost:3000/health
- API Notes: http://localhost:3000/notes

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | Postgres connection string | `postgres://app:app@localhost:5432/app_dev` |
| `NODE_ENV` | Environment mode | `development` or `production` |
| `PORT` | API port (default: 3000) | `3000` |

## Deployment Flow

Deterministic pipelines run per environment:

1. **deploy-test**: Build + release + deploy + smoke test
2. **deploy-staging**: Build + release + deploy
3. **deploy-production**: Build + release + deploy (approval required)

Approvals are enforced at the pipeline boundary for production. Jobs targeting the same environment are gated.

## Image Builds

Eve Horizon tracks builds as first-class primitives. When you deploy, the pipeline automatically:

1. Creates a **BuildSpec** (immutable input describing what to build)
2. Executes a **BuildRun** (using BuildKit on K8s or Docker Buildx locally)
3. Produces **BuildArtifacts** (image digests like `sha256:abc123...`)

Each build is tracked and can be inspected:

```bash
# List builds for this project
eve build list --project <project-id>

# Show build details and artifacts
eve build show <build_id>

# Inspect build artifacts (image digests)
eve build artifacts <build_id>

# Diagnose build failures
eve build diagnose <build_id>
```

**Build Backends:**
- **BuildKit** (default on Kubernetes) - Fast, parallel multi-stage builds
- **Docker Buildx** (local development) - Uses local Docker daemon
- **Kaniko** (fallback) - Rootless builds in restricted environments

**Image Registry:**
- Images are pushed to `ghcr.io/incept5/eve-horizon-fullstack-example-{service}`
- Releases reference images by digest (immutable) rather than tag
- Digests ensure exactly the same image is deployed across environments

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| GET | `/notes` | List notes |
| POST | `/notes` | Create a note |
| GET | `/openapi.json` | OpenAPI spec |

## Directory Structure

```
.
├── .eve/
│   ├── manifest.yaml    # Eve Horizon configuration
│   └── hooks/
│       └── on-clone.sh  # Post-clone setup script
├── apps/
│   ├── api/             # NestJS backend
│   │   ├── Dockerfile
│   │   └── src/
│   └── web/             # React frontend
│       ├── Dockerfile
│       └── src/
├── db/
│   ├── schema.sql       # Database schema
│   └── seed.sql         # Seed data
├── skills/              # Eve skills
│   └── eve-horizon-dev/
├── docker-compose.yml   # Local development
└── skills.txt           # Skill manifest
```
