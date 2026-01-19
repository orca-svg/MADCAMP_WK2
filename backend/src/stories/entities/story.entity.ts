import { ApiProperty } from '@nestjs/swagger';
import { Story, Emotion } from '@prisma/client';

export class StoryEntity implements Story {
    @ApiProperty({ description: '사연 고유 ID', example: '1234' })
    id!: string;

    @ApiProperty({ description: '사연 제목', example: '힘든 하루' })
    title!: string;

    @ApiProperty({ description: '사연 내용', example: '오늘은 정말 힘든 하루였어요...' })
    content!: string;

    @ApiProperty({ description: '사연 공개 여부', example: true })
    isPublic!: boolean;

    @ApiProperty({ description: 'Emotion associated with the story', example: 'SAD' })
    emotion: Emotion | null = null;

    @ApiProperty({ description: '사연 작성자 ID', example: '1234'})
    userId!: string;

    @ApiProperty({ description: '사연 작성일', example: '2023-10-01T12:34:56Z' })
    createdAt!: Date;
}
