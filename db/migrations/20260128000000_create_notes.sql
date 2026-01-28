-- Migration: create_notes
-- Creates the notes table for storing user notes

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable row-level security
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Create index for org_id filtering
CREATE INDEX IF NOT EXISTS idx_notes_org_id ON notes(org_id);

-- Create index for user_id filtering
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
