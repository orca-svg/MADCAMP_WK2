import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { AdviceService } from './advice.service';
import { CreateAdviceDto } from './dto/create-advice.dto';
import { UpdateAdviceDto } from './dto/update-advice.dto';

@Controller('advice')
export class AdviceController {
  constructor(private readonly adviceService: AdviceService) {}

  @Post()
  create(@Body() createAdviceDto: CreateAdviceDto) {
    return this.adviceService.create(createAdviceDto);
  }

  @Get()
  findAll() {
    return this.adviceService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.adviceService.findOne(+id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateAdviceDto: UpdateAdviceDto) {
    return this.adviceService.update(+id, updateAdviceDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.adviceService.remove(+id);
  }
}
