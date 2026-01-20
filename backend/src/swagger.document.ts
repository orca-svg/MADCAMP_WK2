import { DocumentBuilder } from '@nestjs/swagger';

export class BaseApiDocument {
  public builder = new DocumentBuilder();

  public initializeOptions() {
    return this.builder
      .setTitle('Service Backend API')
      .setDescription('This API provides backend services for the application.')
      .setVersion('1.0.0')
      .build();
  }
}
