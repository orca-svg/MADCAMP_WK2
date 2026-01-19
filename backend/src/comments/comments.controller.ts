import { BadRequestException, Controller, Delete, Get, Param, Post, Query, Body } from '@nestjs/common';
import { CommentsService } from './comments.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { ApiGetResponse, ApiPostResponse } from 'src/common/decorators/swagger.decorator';
import { CommentEntity } from './entities/comment.entity';
import { ResponseMessage } from 'src/common/decorators/response-message.decorator';
import { ApiQuery } from '@nestjs/swagger';

@Controller('comments')
export class CommentsController {
  constructor(private readonly commentsService: CommentsService) {}

  private readonly TEMP_USER_ID = '1ae36e69-43ca-47b6-9a68-af21871e0987';

  @Post()
  @ApiPostResponse(CommentEntity, 'Create a comment')
  @ResponseMessage('Comment created.')
  create(@Body() createCommentDto: CreateCommentDto) {
    const userId = createCommentDto.userId ?? this.TEMP_USER_ID;
    return this.commentsService.create(userId, createCommentDto);
  }

  @Get()
  @ApiGetResponse(CommentEntity, 'Get comments by story')
  @ApiQuery({ name: 'storyId', required: true })
  @ResponseMessage('Comments retrieved.')
  findAll(@Query('storyId') storyId?: string) {
    if (!storyId) {
      throw new BadRequestException('storyId is required');
    }

    return this.commentsService.findAll(storyId);
  }

  @Delete(':id')
  @ApiPostResponse(CommentEntity, 'Remove a comment')
  @ResponseMessage('Comment removed.')
  remove(@Param('id') id: string) {
    return this.commentsService.remove(id);
  }
}
