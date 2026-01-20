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

# 3. Create a job targeting the default environment (staging)
eve job create --project <project-id> --description "Add a button to the homepage"

# 4. Deploy to a specific environment
eve env deploy staging --ref main
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
- **pipelines**: CD pipeline from test -> staging -> approval -> production
- **triggers**: GitHub webhook for main branch pushes

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
- API Todos: http://localhost:3000/todos

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | Postgres connection string | `postgres://app:app@localhost:5432/app_dev` |
| `NODE_ENV` | Environment mode | `development` or `production` |
| `PORT` | API port (default: 3000) | `3000` |

## Deployment Flow

When you push to `main`, the CD pipeline runs:

1. **deploy-test**: Deploy to test environment
2. **smoke-test**: Verify API health
3. **deploy-staging**: Deploy to staging
4. **e2e-test**: Run integration tests
5. **review**: Wait for manual approval
6. **deploy-prod**: Deploy to production

Jobs targeting the same environment are automatically gated - only one deployment at a time per environment.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| GET | `/todos` | List all todos |
| POST | `/todos` | Create a todo |

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
