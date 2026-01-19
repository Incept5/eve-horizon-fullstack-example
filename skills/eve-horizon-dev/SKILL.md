---
name: eve-horizon-dev
description: Develop changes in an Eve Horizon-compatible repo using a PR-style workflow.
---

# Eve Horizon Dev Workflow

## Purpose

Use a standard PR-style workflow:
1) Create a feature branch
2) Implement changes
3) Run relevant tests
4) Commit
5) Open a PR and report the link

## Required behavior

- Use a branch name like `feat/<short-topic>`
- Prefer smallest change set needed to solve the task
- Run the most relevant test command for the change
- If tests are slow, run a targeted subset and explain why
- Create a PR using `gh pr create` and report the resulting link

## Project basics

- React app: `apps/web`
- API: `apps/api`
- Postgres via `.eve/services.yaml`
- Local dev via `docker-compose.yml`

## Typical commands

```bash
# Create a feature branch
git checkout -b feat/<topic>

# Web
cd apps/web
npm install
npm run dev

# API
cd apps/api
npm install
npm run dev

# Build
npm run build

# Commit + PR
git status
git add -A
git commit -m "<message>"
gh pr create --fill
```

