import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Req,
  UseGuards,
  Query,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { StoriesService } from './stories.service';
import { CreateStoryDto } from './dto/create-story.dto';
import { UpdateStoryDto } from './dto/update-story.dto';

import { SessionAuthGuard } from 'src/auth/guards/session-auth.guard';
import { ResponseMessage } from 'src/common/decorators/response-message.decorator';
import { ApiGetResponse, ApiPostResponse } from 'src/common/decorators/swagger.decorator';
import { StoryEntity } from './entities/story.entity';

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
  @UseGuards(SessionAuthGuard)
  @ApiGetResponse(StoryEntity, '공개된 사연들 조회하기')
  @ResponseMessage('공개된 사연들을 성공적으로 조회했습니다.')
  findAll(@Req() req: any, @Query('mine') mine?: string) {
    const mineOnly = mine === 'true' || mine === '1';
    return this.storiesService.findAll(req.user.id, mineOnly);
  }

  @Get(':id')
  @UseGuards(SessionAuthGuard)
  @ApiGetResponse(StoryEntity, '사연 상세 조회하기')
  @ResponseMessage('사연 상세 정보를 성공적으로 조회했습니다.')
  findOne(@Param('id') id: string, @Req() req: any) {
    return this.storiesService.findOne(id, req.user.id);
  }

  @Patch(':id')
  @UseGuards(SessionAuthGuard)
  @ApiPostResponse(StoryEntity, '사연 수정하기') // (프로젝트 데코레이터가 POST/GET만 있으면 유지)
  @ResponseMessage('사연이 성공적으로 수정되었습니다.')
  update(@Param('id') id: string, @Req() req: any, @Body() updateStoryDto: UpdateStoryDto) {
    return this.storiesService.update(req.user.id, id, updateStoryDto);
  }

  @Delete(':id')
  @UseGuards(SessionAuthGuard)
  @ApiGetResponse(StoryEntity, '사연 삭제하기')
  @ResponseMessage('사연이 성공적으로 삭제되었습니다.')
  remove(@Param('id') id: string, @Req() req: any) {
    return this.storiesService.remove(req.user.id, id);
  }

  @Post(':id/like')
  @UseGuards(SessionAuthGuard)
  @ResponseMessage('좋아요 상태가 변경되었습니다.')
  toggleLike(@Req() req: any, @Param('id') storyId: string) {
    return this.storiesService.toggleLike(req.user.id, storyId);
  }
}
