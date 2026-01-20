import {
  BadRequestException,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Body,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiQuery, ApiTags } from '@nestjs/swagger';

import { CommentsService } from './comments.service';
import { CreateCommentDto } from './dto/create-comment.dto';

import { ApiGetResponse, ApiPostResponse } from 'src/common/decorators/swagger.decorator';
import { CommentEntity } from './entities/comment.entity';
import { ResponseMessage } from 'src/common/decorators/response-message.decorator';
import { SessionAuthGuard } from 'src/auth/guards/session-auth.guard';

@ApiTags('comments')
@Controller('comments')
@UseGuards(SessionAuthGuard) // ✅ comments는 모두 로그인 사용자 기준으로 동작시키는게 깔끔합니다.
export class CommentsController {
  constructor(private readonly commentsService: CommentsService) {}

  @Post()
  @ApiPostResponse(CommentEntity, 'Create a comment')
  @ResponseMessage('Comment created.')
  create(@Body() createCommentDto: CreateCommentDto, @Req() req: any) {
    return this.commentsService.create(req.user.id, createCommentDto);
  }

  @Get()
  @ApiGetResponse(CommentEntity, 'Get comments by story')
  @ApiQuery({ name: 'storyId', required: true })
  @ResponseMessage('Comments retrieved.')
  findAll(@Query('storyId') storyId: string, @Req() req: any) {
    if (!storyId) throw new BadRequestException('storyId is required');
    return this.commentsService.findAll(storyId, req.user.id);
  }

  @Delete(':id')
  @ApiPostResponse(CommentEntity, 'Remove a comment')
  @ResponseMessage('Comment removed.')
  remove(@Param('id') id: string, @Req() req: any) {
    return this.commentsService.remove(req.user.id, id);
  }

  @Post(':id/like')
  @ResponseMessage('좋아요 상태가 변경되었습니다.')
  toggleLike(@Req() req: any, @Param('id') commentId: string) {
    return this.commentsService.toggleLike(req.user.id, commentId);
  }

  @Patch(':id/adopt')
  @ApiPostResponse(CommentEntity, 'Adopt a comment (one-way, one per story)')
  @ResponseMessage('댓글이 채택되었습니다.')
  adopt(@Req() req: any, @Param('id') commentId: string) {
    return this.commentsService.adopt(req.user.id, commentId);
  }
}
