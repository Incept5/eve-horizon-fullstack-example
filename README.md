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
eve pipeline run deploy-test --project <project-id> --env test --ref main --wait

# Optional: env deploy shortcut (maps to the env's pipeline)
eve env deploy test --ref main
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
- **registry**: container registry settings for build actions
- **tests**: smoke test command references
- **pipelines**: deterministic build/release/deploy actions per env

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
