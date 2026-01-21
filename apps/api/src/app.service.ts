import { Injectable, OnModuleInit } from '@nestjs/common';
import { pool } from './db';

@Injectable()
export class AppService implements OnModuleInit {
  async onModuleInit() {
    await pool.query(
      `CREATE TABLE IF NOT EXISTS todos (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )`,
    );
  }

  async health() {
    const result = await pool.query('SELECT 1 as ok');
    return { ok: result.rows[0]?.ok === 1 };
  }

  async listTodos() {
    const result = await pool.query(
      'SELECT id, title, created_at FROM todos ORDER BY id DESC LIMIT 50',
    );
    return result.rows;
  }

  async createTodo(title: string) {
    const result = await pool.query(
      'INSERT INTO todos (title) VALUES ($1) RETURNING id, title, created_at',
      [title],
    );
    return result.rows[0];
  }

  async getStatus() {
    try {
      const result = await pool.query('SELECT COUNT(*) as count FROM todos');
      const todosCount = parseInt(result.rows[0]?.count || '0', 10);
      return {
        api: 'ok',
        database: 'ok',
        todos_count: todosCount,
      };
    } catch (error) {
      return {
        api: 'ok',
        database: 'error',
        database_error: error instanceof Error ? error.message : 'Unknown error',
        todos_count: 0,
      };
    }
  }
}
