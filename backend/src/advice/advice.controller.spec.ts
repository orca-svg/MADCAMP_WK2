import { Test, TestingModule } from '@nestjs/testing';
import { AdviceController } from './advice.controller';
import { AdviceService } from './advice.service';

describe('AdviceController', () => {
  let controller: AdviceController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AdviceController],
      providers: [AdviceService],
    }).compile();

    controller = module.get<AdviceController>(AdviceController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
