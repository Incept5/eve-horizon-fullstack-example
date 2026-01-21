import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { eveAuthMiddleware } from './eve-auth';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(eveAuthMiddleware);
  const port = Number(process.env.PORT || 3000);
  await app.listen(port);
  console.log(`API listening on http://localhost:${port}`);
}

bootstrap();
