import { IsString, IsNotEmpty, IsBoolean, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Emotion } from '@prisma/client';

export class CreateStoryDto {
    @ApiProperty({ 
        description: '사연 제목',
        example: ''
    })
    @IsString()
    @IsNotEmpty()
    title: string;

    @ApiProperty({
        description: '사연 내용'
    })
    @IsString()
    @IsNotEmpty()
    content: string;

    @ApiProperty({
        description: '사연 공개 여부',
        example: true,
        required: false,
        default: false
    })
    @IsBoolean()
    @IsOptional()
    isPublic?: boolean;

    @ApiProperty({
        description: 'Emotion associated with the story',
        enum: Emotion,
        example: Emotion.SAD,
        required: false
    })
    @IsEnum(Emotion)
    @IsOptional()
    emotion?: Emotion;
} 