-- =============================================================================
-- Eve Horizon Fullstack Example - Initial Schema
-- =============================================================================
--
-- This migration demonstrates Eve Horizon's Row-Level Security (RLS) pattern
-- for multi-tenant data isolation.
--
-- RLS OVERVIEW
-- ------------
-- Row-Level Security allows the database to automatically filter rows based on
-- the current user context. This provides defense-in-depth: even if application
-- code has bugs, users cannot access data belonging to other users/orgs.
--
-- HOW IT WORKS
-- ------------
-- 1. The API sets session variables before each query:
--      SELECT set_config('app.user_id', '<user-id>', true);
--      SELECT set_config('app.org_id', '<org-id>', true);
--
-- 2. RLS policies reference these variables:
--      USING (user_id = current_setting('app.user_id', true))
--
-- 3. PostgreSQL automatically filters rows that don't match the policy.
--
-- THE 'app' NAMESPACE
-- -------------------
-- 'app.user_id' and 'app.org_id' are NOT special PostgreSQL features.
-- They are custom session variables using a dotted namespace convention.
-- You can use any name (e.g., 'myapp.tenant_id'), but 'app.*' is the Eve
-- Horizon convention.
--
-- FUNCTION PARAMETERS
-- -------------------
-- set_config(name, value, is_local):
--   - is_local=true: Setting is transaction-local (cleared on COMMIT/ROLLBACK)
--   - is_local=false: Setting persists for the session
--
-- current_setting(name, missing_ok):
--   - missing_ok=true: Return NULL if not set (recommended)
--   - missing_ok=false: Raise error if not set
--
-- SECURITY MODEL
-- --------------
-- - SELECT: User can only see their own rows (filtered by user_id)
-- - INSERT: Must set user_id and org_id matching the session context
-- - UPDATE: Can only update own rows, must preserve user_id/org_id
-- - DELETE: Not shown here, but would use USING clause like SELECT
--
-- SEE ALSO
-- --------
-- - apps/api/src/app.service.ts - How the API sets session context
-- - apps/api/src/eve-auth.ts - How user context is extracted from JWT
-- - ../eve-horizon/apps/api/src/environments/env-db.service.ts - Eve's RLS impl
-- =============================================================================

-- Enable pgcrypto for UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =============================================================================
-- NOTES TABLE
-- =============================================================================
-- A simple multi-tenant table demonstrating the RLS pattern.
-- Each note belongs to a user within an organization.

CREATE TABLE IF NOT EXISTS notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id TEXT NOT NULL,      -- Organization ID (from Eve JWT claims)
  user_id TEXT NOT NULL,     -- User ID (from Eve JWT claims)
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- ROW-LEVEL SECURITY
-- =============================================================================
-- Enable RLS on the table. Without policies, this blocks ALL access.
-- Policies below define who can access what.

ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SELECT POLICY: Users can only see their own notes
-- -----------------------------------------------------------------------------
-- The USING clause filters which rows are visible.
-- We check that app.user_id is set (not NULL) AND matches the row's user_id.

CREATE POLICY notes_select ON notes
  FOR SELECT
  USING (
    current_setting('app.user_id', true) IS NOT NULL
    AND user_id = current_setting('app.user_id', true)
  );

-- -----------------------------------------------------------------------------
-- INSERT POLICY: Users can only insert notes for themselves
-- -----------------------------------------------------------------------------
-- WITH CHECK validates the data being inserted.
-- Both user_id and org_id must match the session context.

CREATE POLICY notes_insert ON notes
  FOR INSERT
  WITH CHECK (
    current_setting('app.user_id', true) IS NOT NULL
    AND current_setting('app.org_id', true) IS NOT NULL
    AND user_id = current_setting('app.user_id', true)
    AND org_id = current_setting('app.org_id', true)
  );

-- -----------------------------------------------------------------------------
-- UPDATE POLICY: Users can only update their own notes
-- -----------------------------------------------------------------------------
-- USING: Filters which rows can be updated (same as SELECT)
-- WITH CHECK: Validates the new values (prevents changing user_id/org_id)

CREATE POLICY notes_update ON notes
  FOR UPDATE
  USING (
    current_setting('app.user_id', true) IS NOT NULL
    AND user_id = current_setting('app.user_id', true)
  )
  WITH CHECK (
    current_setting('app.user_id', true) IS NOT NULL
    AND current_setting('app.org_id', true) IS NOT NULL
    AND user_id = current_setting('app.user_id', true)
    AND org_id = current_setting('app.org_id', true)
  );

-- =============================================================================
-- NOTES ON BYPASSING RLS
-- =============================================================================
-- Superusers and table owners bypass RLS by default.
-- In production, the app should connect as a non-superuser role.
--
-- To force RLS for table owners (for testing):
--   ALTER TABLE notes FORCE ROW LEVEL SECURITY;
--
-- To check RLS status:
--   SELECT relname, relrowsecurity, relforcerowsecurity
--   FROM pg_class WHERE relname = 'notes';
-- =============================================================================
