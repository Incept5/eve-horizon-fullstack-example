# Claude Code Instructions

**CRITICAL: READ AGENTS.md FIRST**

This repo is the **canonical example** for Eve Horizon projects. `AGENTS.md` contains all instructions for working here.

## Non-Negotiable Restrictions

1. **DO NOT modify `../eve-horizon` or `../eve-skillpacks`** - Read only
2. **DO NOT control the k3d stack** - Ask the user to run `./bin/eh k8s ...` commands
3. **Always push before E2E tests** - Tests clone via git, not local filesystem

## Skills

Skills are installed via `eve-skillpacks`. Key skills for this repo:
- `eve-manifest-authoring` - Manifest editing
- `eve-deploy-debugging` - Deploy and debug
- `eve-repo-upkeep` - Keep aligned with platform conventions
- `eve-troubleshooting` - CLI-first diagnostics

Agent runtime config lives in `agents/`. After editing, sync it:

```bash
eve agents sync --project proj_xxx --ref main --repo-dir .
```
