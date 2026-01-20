import { BadRequestException, Controller, Delete, Get, Param, Post, Query, Body } from '@nestjs/common';
import { CommentsService } from './comments.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { ApiGetResponse, ApiPostResponse } from 'src/common/decorators/swagger.decorator';
import { CommentEntity } from './entities/comment.entity';
import { ResponseMessage } from 'src/common/decorators/response-message.decorator';
import { ApiQuery, ApiTags } from '@nestjs/swagger';
import { SessionAuthGuard } from 'src/auth/guards/session-auth.guard';
import { UseGuards, Req } from '@nestjs/common';

@ApiTags('comments')
@Controller('comments')
export class CommentsController {
  constructor(private readonly commentsService: CommentsService) {}

  @Post()
  @UseGuards(SessionAuthGuard)
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
    if (!storyId) {
      throw new BadRequestException('storyId is required');
    }

    const userId = req.user?.id;
    return this.commentsService.findAll(storyId, userId);
  }

  @Delete(':id')
  @ApiPostResponse(CommentEntity, 'Remove a comment')
  @ResponseMessage('Comment removed.')
  remove(@Param('id') id: string) {
    return this.commentsService.remove(id);
  }

  @UseGuards(SessionAuthGuard)
  @Post(':id/like')
  async toggleLike(@Req() req: any, @Param('id') commentId: string) {
    return this.commentsService.toggleLike(req.user.id, commentId);
  }
}
