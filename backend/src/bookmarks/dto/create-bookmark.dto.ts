import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateBookmarkDto {
  @ApiProperty({ description: 'Advice ID', example: '1234' })
  @IsString()
  @IsNotEmpty()
  adviceId: string;

  @ApiPropertyOptional({ description: 'User ID', example: '1234' })
  @IsString()
  @IsOptional()
  userId?: string;
}
