import { BadRequestException, Controller, Delete, Get, Post, Query, Body, Req, UseGuards } from '@nestjs/common';
import { BookmarksService } from './bookmarks.service';
import { CreateBookmarkDto } from './dto/create-bookmark.dto';
import { ApiGetResponse, ApiPostResponse } from 'src/common/decorators/swagger.decorator';
import { BookmarkEntity } from './entities/bookmark.entity';
import { ResponseMessage } from 'src/common/decorators/response-message.decorator';
import { ApiQuery } from '@nestjs/swagger';
import { SessionAuthGuard } from 'src/auth/guards/session-auth.guard';

@Controller('bookmarks')
@UseGuards(SessionAuthGuard)
export class BookmarksController {
  constructor(private readonly bookmarksService: BookmarksService) {}

  @Post()
  @ApiPostResponse(BookmarkEntity, 'Create a bookmark')
  @ResponseMessage('Bookmark created.')
  create(@Body() createBookmarkDto: CreateBookmarkDto, @Req() req: any) {
    return this.bookmarksService.create(req.user.id, createBookmarkDto);
  }

  @Get()
  @ApiGetResponse(BookmarkEntity, 'Get bookmarks by user')
  @ResponseMessage('Bookmarks retrieved.')
  findAll(@Req() req: any) {
    return this.bookmarksService.findAll(req.user.id);
  }

  @Delete()
  @ApiPostResponse(BookmarkEntity, 'Remove a bookmark')
  @ApiQuery({ name: 'adviceId', required: true })
  @ResponseMessage('Bookmark removed.')
  remove(@Req() req: any, @Query('adviceId') adviceId?: string) {
    if (!adviceId) {
      throw new BadRequestException('adviceId is required');
    }

    return this.bookmarksService.remove(req.user.id, adviceId);
  }
}
