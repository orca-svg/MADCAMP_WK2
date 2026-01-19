import { ApiProperty } from '@nestjs/swagger';
import { Comment } from '@prisma/client';

export class CommentEntity implements Comment {
  @ApiProperty({ description: 'Comment ID', example: '1234' })
  id: string;

  @ApiProperty({ description: 'Comment content', example: 'Great story.' })
  content: string;

  @ApiProperty({ description: 'Is best comment', example: false })
  isBest: boolean;

  @ApiProperty({ description: 'Like count', example: 0 })
  likeCount: number;

  @ApiProperty({ description: 'Story ID', example: '1234' })
  storyId: string;

  @ApiProperty({ description: 'User ID', example: '1234' })
  userId: string;

  @ApiProperty({ description: 'Comment created at', example: '2023-10-01T12:34:56Z' })
  createdAt: Date;
}
