import { IsString, IsNotEmpty, IsBoolean, IsOptional, IsEnum, IsArray, ArrayMaxSize } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateStoryDto {
    @ApiProperty({ 
        description: '사연 제목',
        example: ''
    })
    @IsString()
    @IsNotEmpty()
    title!: string;

    @ApiProperty({
        description: '사연 내용'
    })
    @IsString()
    @IsNotEmpty()
    content!: string;

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
        description: '사연 태그'
    })
    @IsArray()
    @IsString({ each: true })
    @ArrayMaxSize(3, { message: '태그는 최대 3개까지만 선택할 수 있습니다. '})
    @IsOptional()
    tagNames?: string[];
} 
