import { Module } from '@nestjs/common';
import { AdviceService } from './advice.service';
import { AdviceController } from './advice.controller';

@Module({
  controllers: [AdviceController],
  providers: [AdviceService],
})
export class AdviceModule {}
