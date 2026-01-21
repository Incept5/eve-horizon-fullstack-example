import { Body, Controller, Get, Post } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('health')
  health() {
    return this.appService.health();
  }

  @Get('todos')
  listTodos() {
    return this.appService.listTodos();
  }

  @Post('todos')
  createTodo(@Body() body: { title?: string }) {
    const title = body.title?.trim();
    if (!title) {
      return { error: 'title is required' };
    }
    return this.appService.createTodo(title);
  }

  @Get('api/status')
  getStatus() {
    return this.appService.getStatus();
  }
}
