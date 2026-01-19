import { Controller, Get } from '@nestjs/common';
import { AdviceService } from './advice.service';
import { ApiGetResponse } from 'src/common/decorators/swagger.decorator';
import { AdviceEntity } from './entities/advice.entity';
import { ResponseMessage } from 'src/common/decorators/response-message.decorator';

@Controller('advice')
export class AdviceController {
  constructor(private readonly adviceService: AdviceService) {}

  @Get()
  @ApiGetResponse(AdviceEntity, 'Get all advice')
  @ResponseMessage('Advice list retrieved.')
  findAll() {
    return this.adviceService.findAll();
  }

  @Get('random')
  @ApiGetResponse(AdviceEntity, 'Get random advice')
  @ResponseMessage('Random advice retrieved.')
  funcRandom() {
    return this.adviceService.funcRandom();
  }
}
