import { NestFactory } from '@nestjs/core';
import { TransformInterceptor } from './common/interfaces/transform.interceptor';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { AppModule } from './app.module';
import { BaseApiDocument } from './swagger.document';
import { SwaggerModule } from '@nestjs/swagger';
import cookieParser from 'cookie-parser';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // ✅ CORS: 세션(쿠키) 기반이면 credentials + origin 관리가 중요합니다.
  // Flutter 앱 자체는 CORS 영향이 적지만, 추후 웹/스웨거/디버깅에 필수라 넣는 게 좋습니다.
  app.enableCors({
    origin: [
      'https://reso-app.cloud',
      'http://localhost:3000',
      'http://localhost:5173',
    ],
    credentials: true,
  });

  const reflector = app.get('Reflector');
  app.useGlobalInterceptors(new TransformInterceptor(reflector));
  app.useGlobalFilters(new HttpExceptionFilter());

  // ✅ cookie parser (SessionAuthGuard가 request.cookies를 읽음)
  app.use(cookieParser());

  const config = new BaseApiDocument().initializeOptions();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
