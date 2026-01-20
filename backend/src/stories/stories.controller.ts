import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { StoriesService } from './stories.service';
import { CreateStoryDto } from './dto/create-story.dto';
import { UpdateStoryDto } from './dto/update-story.dto';
import { ResponseMessage } from 'src/common/decorators/response-message.decorator';
import { StoryEntity } from './entities/story.entity';
import { ApiPostResponse, ApiGetResponse } from 'src/common/decorators/swagger.decorator';
import { UseGuards, Req } from '@nestjs/common';
import { SessionAuthGuard } from 'src/auth/guards/session-auth.guard';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('stories')
@Controller('stories')
export class StoriesController {
  constructor(private readonly storiesService: StoriesService) {}

  @Post()
  @UseGuards(SessionAuthGuard)
  @ApiPostResponse(StoryEntity, '사연 송신하기')
  @ResponseMessage('사연이 성공적으로 송신되었습니다.')
  create(@Body() createStoryDto: CreateStoryDto, @Req() req: any) {
    return this.storiesService.create(req.user.id, createStoryDto);
  }

  @Get()
  @ApiGetResponse(StoryEntity, '공개된 사연들 조회하기')
  @ResponseMessage('공개된 사연들을 성공적으로 조회했습니다.')
  findAll(@Req() req: any) {
    const userId = req.user?.id;
    return this.storiesService.findAll(userId);
  }

  @Get(':id')
  @ApiGetResponse(StoryEntity, '사연 상세 조회하기')
  @ResponseMessage('사연 상세 정보를 성공적으로 조회했습니다.')
  findOne(@Param('id') id: string, @Req() req: any) {
    const userId = req.user?.id;
    return this.storiesService.findOne(id, userId);
  }

  @Patch(':id')
  @ApiPostResponse(StoryEntity, '사연 수정하기')
  @ResponseMessage('사연이 성공적으로 수정되었습니다.')
  update(@Param('id') id: string, @Req() req: any, @Body() updateStoryDto: UpdateStoryDto) {
    const userId = req.user?.id;
    return this.storiesService.update(id, updateStoryDto);
  }

  @Delete(':id')
  @ApiGetResponse(StoryEntity, '사연 삭제하기')
  @ResponseMessage('사연이 성공적으로 삭제되었습니다.')
  remove(@Param('id') id: string) {
    return this.storiesService.remove(id);
  }

  @UseGuards(SessionAuthGuard)
  @Post(':id/like')
  async toggleLike(@Req() req: any, @Param('id') storyId: string) {
    return this.storiesService.toggleLike(req.user.id, storyId);
  }
}
