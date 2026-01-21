import { Body, Controller, Get, Post, Req, UnauthorizedException } from '@nestjs/common';
import { AppService } from './app.service';
import type { EveRequest } from './eve-auth';

const OPENAPI_SPEC = {
  openapi: '3.0.3',
  info: {
    title: 'Eve Horizon Example API',
    version: '1.0.0',
  },
  servers: [
    { url: '{EVE_API_BASE}' },
    { url: 'http://localhost:3000' },
  ],
  paths: {
    '/notes': {
      get: {
        summary: 'List notes',
        responses: {
          '200': {
            description: 'List notes',
          },
        },
      },
      post: {
        summary: 'Create a note',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              example: { title: 'Hello', body: 'World' },
            },
          },
        },
        responses: {
          '200': {
            description: 'Created note',
          },
          '401': {
            description: 'Unauthorized',
          },
        },
      },
    },
    '/health': {
      get: {
        summary: 'Health check',
        responses: {
          '200': { description: 'OK' },
        },
      },
    },
    '/api/status': {
      get: {
        summary: 'System status',
        responses: {
          '200': { description: 'Status' },
        },
      },
    },
  },
};

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('health')
  health() {
    return this.appService.health();
  }

  @Get('openapi.json')
  openApi() {
    return OPENAPI_SPEC;
  }

  @Get('notes')
  listNotes(@Req() req: EveRequest) {
    return this.appService.listNotes(req.eveUser ?? null);
  }

  @Post('notes')
  createNote(@Req() req: EveRequest, @Body() body: { title?: string; body?: string }) {
    if (!req.eveUser?.user_id || !req.eveUser.org_id) {
      throw new UnauthorizedException('Missing user context.');
    }
    const title = body.title?.trim();
    if (!title) {
      return { error: 'title is required' };
    }
    const content = body.body?.trim() ?? '';
    return this.appService.createNote(req.eveUser, title, content);
  }

  @Get('api/status')
  getStatus() {
    return this.appService.getStatus();
  }
}
