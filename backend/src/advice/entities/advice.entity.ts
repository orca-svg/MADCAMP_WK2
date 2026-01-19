import { ApiProperty } from '@nestjs/swagger';
import { Advice } from '@prisma/client';

export class AdviceEntity implements Advice {
  @ApiProperty({ description: 'Advice ID', example: '1234' })
  id: string;

  @ApiProperty({ description: 'Advice content', example: 'Keep going.' })
  content: string;

  @ApiProperty({
    description: 'Advice author',
    example: 'Anonymous',
    required: false,
    nullable: true,
  })
  author: string | null;
}
