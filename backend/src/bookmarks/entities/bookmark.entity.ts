import { ApiProperty } from '@nestjs/swagger';
import { Bookmark } from '@prisma/client';

export class BookmarkEntity implements Bookmark {
  @ApiProperty({ description: 'Bookmark ID', example: '1234' })
  id: string;

  @ApiProperty({ description: 'User ID', example: '1234' })
  userId: string;

  @ApiProperty({ description: 'Advice ID', example: '1234' })
  adviceId: string;

  @ApiProperty({ description: 'Bookmark created at', example: '2023-10-01T12:34:56Z' })
  createdAt: Date;
}
