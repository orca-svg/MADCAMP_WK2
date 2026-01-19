import { IsString, IsNotEmpty, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateAdviceDto {
    @ApiProperty({
        description: 'Advice 내용',
        example: 'content'
    })
    @IsString()
    @IsNotEmpty()
    content!: string;

    @ApiPropertyOptional({
        description: 'Advice 작성자',
        example: 'author'
    })
    @IsString()
    @IsOptional()
    author?: string;
}
