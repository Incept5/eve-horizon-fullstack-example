# Claude Code Instructions

**CRITICAL**: Before starting any work in this repository, you MUST read and internalize `AGENTS.md`.

```
Read AGENTS.md first. It contains:
- Quick start commands for local and k3d testing
- Manifest structure and variable interpolation
- Sister repository coordination rules
- CLI command reference
- Troubleshooting guides
```

## Restrictions (Non-Negotiable)

**DO NOT modify `../eve-horizon` or `../eve-skillpacks`**
- Read files for reference only
- Surface issues to the user with specific details
- Propose changes for THIS repo, not the sister repos

**DO NOT control the k3d stack**
- Never run `./bin/eh k8s start`, `./bin/eh k8s deploy`, or `./bin/eh k8s stop`
- If you cannot connect to Eve API, **stop and ask the user** to start/rebuild the stack
- The stack may be in use by agents working in `../eve-horizon`

## This Repo's Role

This is the **canonical example** for Eve Horizon projects. It serves as:

1. **Reference implementation** for manifest patterns
2. **E2E test fixture** for the main eve-horizon repo
3. **Documentation source** for deployment workflows

## Key Rules

1. **Always push before E2E tests** - Tests clone via git, not local filesystem
2. **Read-only for sister repos** - Only modify files in THIS repository
3. **Ask user for stack control** - Never start/stop k3d yourself
4. **Use the skills** - `/sync-with-eve-horizon`, `/eve-cli-workflows`, `/local-k3d-testing`

## When in Doubt

Read `AGENTS.md`. It's the single source of truth for agents working in this codebase.
