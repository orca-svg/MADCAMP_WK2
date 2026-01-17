import { Test, TestingModule } from '@nestjs/testing';
import { AdviceService } from './advice.service';

describe('AdviceService', () => {
  let service: AdviceService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [AdviceService],
    }).compile();

    service = module.get<AdviceService>(AdviceService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
