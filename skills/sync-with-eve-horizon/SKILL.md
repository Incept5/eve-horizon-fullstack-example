---
name: sync-with-eve-horizon
description: Check this example repo against the latest eve-horizon docs and manifest spec. Report drift to user.
---

# Sync with Eve Horizon

## Purpose

Check this canonical example repository against the main Eve Horizon project and **report any drift to the user**. This skill helps identify when this repo needs updates to match new patterns.

## CRITICAL: Read-Only for Sister Repo

**DO NOT modify files in `../eve-horizon`.**

This skill:
- Reads files from eve-horizon for comparison
- Identifies drift and issues
- Reports findings to the user
- Proposes changes for THIS repo only

## When to Use

- After eve-horizon has significant updates
- Before making changes that might drift from the main project
- When E2E tests fail unexpectedly
- As a periodic maintenance check

## Sync Procedure

### Step 1: Check Sister Repo Exists

```bash
# Verify eve-horizon is at expected path
ls ../eve-horizon/AGENTS.md
ls ../eve-horizon/docs/system/
```

If not found:
- **STOP and tell the user** the sister repo is not available
- Ask them to clone it: `cd .. && git clone https://github.com/incept5/eve-horizon.git`

### Step 2: Read and Compare Key Files

Read these files from eve-horizon (DO NOT MODIFY):

1. **AGENTS.md** - Development workflow and conventions
2. **docs/system/deployment.md** - Manifest structure and deployment model
3. **docs/system/secrets.md** - Secret interpolation patterns

Compare patterns against this repo's files.

### Step 3: Validate Manifest Structure

Read and compare manifest expectations:

```bash
# Read eve-horizon manifest docs
cat ../eve-horizon/docs/system/deployment.md

# Compare with this repo's manifest
cat .eve/manifest.yaml
```

Key sections to check:
- `components` - Image, port, healthcheck, depends_on
- `environments` - Pipeline ref, db_ref, approval
- `pipelines` - Action types, triggers
- `workflows` - Manual/scheduled operations
- `apis` - OpenAPI source configuration

### Step 4: Check CLI Command Patterns

Verify CLI commands in documentation match current eve CLI:

```bash
# Check available commands
eve --help
eve project --help
eve pipeline --help
```

Compare against commands documented in:
- `README.md`
- `AGENTS.md`
- `skills/*/SKILL.md`

### Step 5: Report Findings

**DO NOT make changes automatically.** Instead, report to the user:

```
## Sync Report

### Drift Detected
1. [File]: [Issue description]
2. [File]: [Issue description]

### Recommended Changes (for this repo)
1. Update `.eve/manifest.yaml`:
   - [specific change]
2. Update `AGENTS.md`:
   - [specific change]

### Changes Needed in eve-horizon (USER ACTION REQUIRED)
1. [description] - User should update in ../eve-horizon

### No Issues
- [List files that are in sync]
```

### Step 6: Propose Changes for This Repo

If changes are needed in THIS repo:
1. Show the user the proposed edits
2. Wait for approval before making changes
3. Make changes only in this repo's files

## Key Files to Check

| This Repo | Eve Horizon Reference |
|-----------|----------------------|
| `.eve/manifest.yaml` | `docs/system/deployment.md` |
| `AGENTS.md` | `AGENTS.md` (patterns only) |
| `README.md` | CLI help output |
| `scripts/smoke-test.sh` | `tests/e2e/` patterns |

## Common Drift Issues

### New Manifest Fields
Eve-horizon may add new manifest features:
- New component options (healthcheck formats, resource limits)
- New environment options (approval types, quotas)
- New pipeline actions or triggers

**Action**: Report to user, propose manifest updates for this repo.

### CLI Changes
Commands may be renamed or restructured.

**Action**: Report stale commands, propose doc updates for this repo.

### Variable Interpolation
New interpolation variables may be available.

**Action**: Report new variables, suggest where to use them.

## Output Template

When complete, provide this report:

```markdown
## Eve Horizon Sync Check - [DATE]

### Status: [IN SYNC | DRIFT DETECTED]

### Files Checked
- [ ] .eve/manifest.yaml
- [ ] AGENTS.md
- [ ] README.md
- [ ] skills/*/SKILL.md

### Issues Found
[List each issue with file and line if applicable]

### Recommended Actions
[List specific changes to make in THIS repo]

### User Action Required
[List anything that needs user intervention, especially for eve-horizon]
```
