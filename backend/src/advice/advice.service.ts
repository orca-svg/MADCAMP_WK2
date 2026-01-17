import { Injectable } from '@nestjs/common';
import { CreateAdviceDto } from './dto/create-advice.dto';
import { UpdateAdviceDto } from './dto/update-advice.dto';

@Injectable()
export class AdviceService {
  create(createAdviceDto: CreateAdviceDto) {
    return 'This action adds a new advice';
  }

  findAll() {
    return `This action returns all advice`;
  }

  findOne(id: number) {
    return `This action returns a #${id} advice`;
  }

  update(id: number, updateAdviceDto: UpdateAdviceDto) {
    return `This action updates a #${id} advice`;
  }

  remove(id: number) {
    return `This action removes a #${id} advice`;
  }
}
