CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY notes_select ON notes
  FOR SELECT
  USING (
    current_setting('app.user_id', true) IS NOT NULL
    AND user_id = current_setting('app.user_id', true)
  );

CREATE POLICY notes_insert ON notes
  FOR INSERT
  WITH CHECK (
    current_setting('app.user_id', true) IS NOT NULL
    AND current_setting('app.org_id', true) IS NOT NULL
    AND user_id = current_setting('app.user_id', true)
    AND org_id = current_setting('app.org_id', true)
  );

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
