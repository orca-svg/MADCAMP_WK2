import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { StoriesService } from './stories.service';
import { CreateStoryDto } from './dto/create-story.dto';
import { UpdateStoryDto } from './dto/update-story.dto';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@Controller('stories')
export class StoriesController {
  constructor(private readonly storiesService: StoriesService) {}

  private readonly TEMP_USER_ID = '1ae36e69-43ca-47b6-9a68-af21871e0987'

  @Post()
  @ApiOperation({ summary: '사연 송신하기' })
  create(@Body() createStoryDto: CreateStoryDto) {
    return this.storiesService.create(this.TEMP_USER_ID, createStoryDto);
  }

  @Get()
  @ApiOperation({ summary: '공개된 사연들 조회하기' })
  findAll() {
    return this.storiesService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: '사연 상세 조회하기' })
  findOne(@Param('id') id: string) {
    return this.storiesService.findOne(id);
  }

  @Patch(':id')
  @ApiOperation({ summary: '사연 수정하기' })
  update(@Param('id') id: string, @Body() updateStoryDto: UpdateStoryDto) {
    return this.storiesService.update(id, updateStoryDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: '사연 삭제하기' })
  remove(@Param('id') id: string) {
    return this.storiesService.remove(id);
  }
}
