# Eve Horizon Fullstack Example

Canonical example repo for Eve Horizon.

Stack:
- React (Vite) frontend in `apps/web`
- NestJS API in `apps/api`
- Postgres

## Eve Horizon usage

```bash
eve project ensure \
  --name eve-fullstack-example \
  --repo-url https://github.com/incept5/eve-horizon-fullstack-example \
  --branch main

eve job create --project <id> --description "Add a button to the homepage"
```

Eve will:
- Run `.eve/hooks/on-clone.sh`
- Install skills listed in `skills.txt`
- Provision Postgres from `.eve/services.yaml` in k8s runtime

## Local dev (Docker Compose)

```bash
cp .env.example .env
docker compose up -d db

# API
cd apps/api
npm install
npm run dev

# Web
cd ../web
npm install
npm run dev
```

Default endpoints:
- Web: http://localhost:5173
- API: http://localhost:3000/health

## Environment

`DATABASE_URL` is required for the API. When using Docker Compose, it is:

```
postgres://app:app@localhost:5432/app_dev
```

