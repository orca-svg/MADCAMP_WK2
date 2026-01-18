import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { StoriesService } from './stories.service';
import { CreateStoryDto } from './dto/create-story.dto';
import { UpdateStoryDto } from './dto/update-story.dto';
import { ApiOperation } from '@nestjs/swagger';
import { ResponseMessage } from 'src/common/decorators/response-message.decorator';
import { StoryEntity } from './entities/story.entity';
import { ApiPostResponse, ApiGetResponse } from 'src/common/decorators/swagger.decorator';

@Controller('stories')
export class StoriesController {
  constructor(private readonly storiesService: StoriesService) {}

  private readonly TEMP_USER_ID = '1ae36e69-43ca-47b6-9a68-af21871e0987'

  @Post()
  @ApiPostResponse(StoryEntity, '사연 송신하기')
  @ResponseMessage('사연이 성공적으로 송신되었습니다.')
  create(@Body() createStoryDto: CreateStoryDto) {
    return this.storiesService.create(this.TEMP_USER_ID, createStoryDto);
  }

  @Get()
  @ApiGetResponse(StoryEntity, '공개된 사연들 조회하기')
  @ResponseMessage('공개된 사연들을 성공적으로 조회했습니다.')
  findAll() {
    return this.storiesService.findAll();
  }

  @Get(':id')
  @ApiGetResponse(StoryEntity, '사연 상세 조회하기')
  @ResponseMessage('사연 상세 정보를 성공적으로 조회했습니다.')
  findOne(@Param('id') id: string) {
    return this.storiesService.findOne(id);
  }

  @Patch(':id')
  @ApiPostResponse(StoryEntity, '사연 수정하기')
  @ResponseMessage('사연이 성공적으로 수정되었습니다.')
  update(@Param('id') id: string, @Body() updateStoryDto: UpdateStoryDto) {
    return this.storiesService.update(id, updateStoryDto);
  }

  @Delete(':id')
  @ApiGetResponse(StoryEntity, '사연 삭제하기')
  @ResponseMessage('사연이 성공적으로 삭제되었습니다.')
  remove(@Param('id') id: string) {
    return this.storiesService.remove(id);
  }
}
