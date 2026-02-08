---
name: notes-api-reference
description: Reference for the fullstack-example Notes API endpoints and database schema
triggers:
  - notes api
  - notes endpoint
  - database schema
---

# Notes API Reference

Use this skill when working with the Notes API or its underlying database.

## Endpoints

### GET /health
Returns `{ ok: true }` when the API is ready.

### GET /notes
Lists all notes for the authenticated user (filtered by RLS).

**Headers:** `Authorization: Bearer <eve-jwt>`
**Response:** `200 OK` with JSON array of note objects.

### POST /notes
Creates a new note.

**Headers:** `Authorization: Bearer <eve-jwt>`
**Body:** `{ "title": "string", "body": "string" }`
**Response:** `201 Created` with the new note object.

## Database Schema

```sql
CREATE TABLE notes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id     TEXT NOT NULL,
  user_id    TEXT NOT NULL,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

Row-level security is enabled — users only see their own notes.

**Indexes:** `idx_notes_org_id`, `idx_notes_user_id`

## Connection

The API connects to PostgreSQL via `DATABASE_URL` env var.
Format: `postgres://eve:<password>@<host>:5432/eve`
