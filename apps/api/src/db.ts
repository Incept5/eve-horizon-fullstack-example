import { Pool } from 'pg';

const rawDatabaseUrl = process.env.DATABASE_URL ?? '';
if (!rawDatabaseUrl) {
  throw new Error('DATABASE_URL is required');
}

const isLocal =
  rawDatabaseUrl.includes('localhost') || rawDatabaseUrl.includes('127.0.0.1');

// Managed DBs set sslmode=require. pg v8 treats that as verify-full,
// which fails without the provider's CA cert. Replace with no-verify
// until the platform trust store is available (see managed-db-tls-trust-plan).
const databaseUrl = isLocal
  ? rawDatabaseUrl
  : rawDatabaseUrl.replace(/sslmode=[^&]+/, 'sslmode=no-verify');

export const pool = new Pool({
  connectionString: databaseUrl,
  ssl: isLocal ? false : { rejectUnauthorized: false },
  max: 20,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
});
