import { Injectable } from '@nestjs/common';
import type { PoolClient } from 'pg';
import { pool } from './db';
import type { EveUser } from './eve-auth';

@Injectable()
export class AppService {
  async health() {
    const result = await pool.query('SELECT 1 as ok');
    return { ok: result.rows[0]?.ok === 1 };
  }

  async listNotes(user: EveUser | null) {
    return this.withClient(user, async (client) => {
      const result = await client.query(
        'SELECT id, title, body, created_at FROM notes ORDER BY created_at DESC LIMIT 50',
      );
      return result.rows;
    });
  }

  async createNote(user: EveUser, title: string, body: string) {
    return this.withClient(user, async (client) => {
      const result = await client.query(
        'INSERT INTO notes (org_id, user_id, title, body) VALUES ($1, $2, $3, $4) RETURNING id, title, body, created_at',
        [user.org_id, user.user_id, title, body],
      );
      return result.rows[0];
    });
  }

  async getStatus() {
    try {
      const result = await pool.query('SELECT COUNT(*) as count FROM notes');
      const notesCount = parseInt(result.rows[0]?.count || '0', 10);
      return {
        api: 'ok',
        database: 'ok',
        notes_count: notesCount,
      };
    } catch (error) {
      return {
        api: 'ok',
        database: 'error',
        database_error: error instanceof Error ? error.message : 'Unknown error',
        notes_count: 0,
      };
    }
  }

  private async withClient<T>(user: EveUser | null, fn: (client: PoolClient) => Promise<T>): Promise<T> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      if (user?.user_id) {
        await client.query("SELECT set_config('app.user_id', $1, true)", [user.user_id]);
      }
      if (user?.org_id) {
        await client.query("SELECT set_config('app.org_id', $1, true)", [user.org_id]);
      }

      const result = await fn(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}
