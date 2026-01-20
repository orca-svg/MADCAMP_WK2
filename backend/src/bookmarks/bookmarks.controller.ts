import { BadRequestException, Controller, Delete, Get, Post, Query, Body } from '@nestjs/common';
import { BookmarksService } from './bookmarks.service';
import { CreateBookmarkDto } from './dto/create-bookmark.dto';
import { ApiGetResponse, ApiPostResponse } from 'src/common/decorators/swagger.decorator';
import { BookmarkEntity } from './entities/bookmark.entity';
import { ResponseMessage } from 'src/common/decorators/response-message.decorator';
import { ApiQuery } from '@nestjs/swagger';

@Controller('bookmarks')
export class BookmarksController {
  constructor(private readonly bookmarksService: BookmarksService) {}

  private readonly TEMP_USER_ID = '1ae36e69-43ca-47b6-9a68-af21871e0987';

  @Post()
  @ApiPostResponse(BookmarkEntity, 'Create a bookmark')
  @ResponseMessage('Bookmark created.')
  create(@Body() createBookmarkDto: CreateBookmarkDto) {
    const userId = createBookmarkDto.userId ?? this.TEMP_USER_ID;
    return this.bookmarksService.create(userId, createBookmarkDto);
  }

  @Get()
  @ApiGetResponse(BookmarkEntity, 'Get bookmarks by user')
  @ApiQuery({ name: 'userId', required: false })
  @ResponseMessage('Bookmarks retrieved.')
  findAll(@Query('userId') userId?: string) {
    const resolvedUserId = userId ?? this.TEMP_USER_ID;
    return this.bookmarksService.findAll(resolvedUserId);
  }

  @Delete()
  @ApiPostResponse(BookmarkEntity, 'Remove a bookmark')
  @ApiQuery({ name: 'adviceId', required: true })
  @ApiQuery({ name: 'userId', required: false })
  @ResponseMessage('Bookmark removed.')
  remove(@Query('adviceId') adviceId?: string, @Query('userId') userId?: string) {
    if (!adviceId) {
      throw new BadRequestException('adviceId is required');
    }

    const resolvedUserId = userId ?? this.TEMP_USER_ID;
    return this.bookmarksService.remove(resolvedUserId, adviceId);
  }
}
