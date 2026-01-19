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
}
