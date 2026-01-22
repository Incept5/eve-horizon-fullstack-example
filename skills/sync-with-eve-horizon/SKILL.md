---
name: sync-with-eve-horizon
description: Check and sync this example repo against the latest eve-horizon docs, manifest spec, and code patterns.
---

# Sync with Eve Horizon

## Purpose

Keep this canonical example repository in sync with the main Eve Horizon project. This skill helps you:

1. Verify manifest.yaml follows the latest spec
2. Update CLI commands in documentation
3. Adopt new patterns from eve-horizon
4. Ensure E2E test compatibility

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

If not found, clone it:
```bash
cd .. && git clone https://github.com/incept5/eve-horizon.git
```

### Step 2: Review Latest Patterns

Read these files from eve-horizon for the current truth:

1. **AGENTS.md** - Development workflow and conventions
2. **docs/system/deployment.md** - Manifest structure and deployment model
3. **docs/system/secrets.md** - Secret interpolation patterns
4. **packages/shared/src/manifest/** - TypeScript types for manifest validation

```bash
# Quick diff check on key docs
diff <(cat ../eve-horizon/AGENTS.md | head -100) <(cat ./AGENTS.md | head -100)
```

### Step 3: Validate Manifest Structure

Compare this repo's manifest against eve-horizon's expectations:

```bash
# Check manifest keys
cat .eve/manifest.yaml | grep -E "^[a-z]+" | head -20

# Look for new required fields in eve-horizon
grep -r "manifest" ../eve-horizon/packages/shared/src/ | grep -i required
```

Key sections to verify:
- `components` - Image, port, healthcheck, depends_on
- `environments` - Pipeline ref, db_ref, approval
- `pipelines` - Action types, triggers
- `workflows` - Manual/scheduled operations
- `apis` - OpenAPI source configuration

### Step 4: Update CLI Commands

Verify CLI commands in documentation match current eve CLI:

```bash
# Check available commands
eve --help
eve project --help
eve pipeline --help
eve env --help
eve job --help
```

Update any stale commands in:
- `README.md` - Human documentation
- `AGENTS.md` - Agent documentation
- `skills/*/SKILL.md` - Skill files

### Step 5: Check E2E Test Compatibility

From eve-horizon, run E2E tests against this repo:

```bash
cd ../eve-horizon

# Ensure this repo is pushed (tests clone via git)
cd ../eve-horizon-fullstack-example
git status  # Should be clean or committed

# Run E2E tests
cd ../eve-horizon
./bin/eh test e2e --env stack
```

### Step 6: Update and Commit

If changes were needed:

```bash
# Stage and commit changes
git add -A
git commit -m "chore: sync with eve-horizon latest patterns"
git push

# Then re-run E2E tests to verify
cd ../eve-horizon
./bin/eh test e2e --env stack
```

## Key Files to Keep in Sync

| This Repo | Eve Horizon Source |
|-----------|-------------------|
| `.eve/manifest.yaml` | `docs/system/deployment.md`, `packages/shared/src/manifest/` |
| `AGENTS.md` | `AGENTS.md` (patterns, not content) |
| `README.md` | CLI help output, `docs/system/` |
| `scripts/smoke-test.sh` | `tests/e2e/` patterns |

## Common Drift Issues

### New Manifest Fields

Eve-horizon adds new manifest features. Check for:
- New component options (healthcheck formats, resource limits)
- New environment options (approval types, quotas)
- New pipeline actions or triggers
- New workflow capabilities

### CLI Changes

Commands may be renamed or restructured:
- `eve deploy` vs `eve env deploy`
- `eve run` vs `eve pipeline run`
- New flags or required parameters

### Variable Interpolation

New interpolation variables may be available:
- Check `${...}` syntax in eve-horizon docs
- Verify this repo uses the correct variable names

## Automation Hint

Consider adding a GitHub Action to:
1. Clone eve-horizon on a schedule
2. Run a diff check on key files
3. Open an issue if drift is detected

## Output

When complete, report:
- Files checked and their sync status
- Any changes made
- E2E test results
- Recommendations for manual review
