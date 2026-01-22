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

## This Repo's Role

This is the **canonical example** for Eve Horizon projects. It serves as:

1. **Reference implementation** for manifest patterns
2. **E2E test fixture** for the main eve-horizon repo
3. **Documentation source** for deployment workflows

## Key Rules

1. **Always push before E2E tests** - Tests clone via git, not local filesystem
2. **Coordinate with `../eve-horizon`** - Changes here may need matching changes there
3. **Use the skills** - `/sync-with-eve-horizon`, `/eve-cli-workflows`, `/local-k3d-testing`

## When in Doubt

Read `AGENTS.md`. It's the single source of truth for agents working in this codebase.
