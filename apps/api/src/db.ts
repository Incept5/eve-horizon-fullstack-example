import { Pool } from 'pg';

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  throw new Error('DATABASE_URL is required');
}

// RDS uses AWS CA-signed certs; strip sslmode from URL and configure SSL explicitly
const url = new URL(databaseUrl);
const needsSsl = url.searchParams.get('sslmode') === 'require';
url.searchParams.delete('sslmode');

export const pool = new Pool({
  connectionString: url.toString(),
  ssl: needsSsl ? { rejectUnauthorized: false } : undefined,
});
