import { ApiProperty } from '@nestjs/swagger';
import { User } from '@prisma/client';

export class UserEntity implements User {
    @ApiProperty({ description: 'User 고유 ID', example: '1234' })
    id!: string;

    @ApiProperty({ description: 'User 이메일', example: 'test@example.com' })
    email!: string;

    @ApiProperty({ 
        description: 'User 이름', 
        example: '홍길동', 
        nullable: true 
    })
    name!: string | null;

    @ApiProperty({ 
        description: 'User 이미지 URL', 
        nullable: true 
    })
    image!: string | null;

    @ApiProperty({ 
        description: 'User 닉네임', 
        example: '길동이', 
        nullable: true 
    })
    nickname!: string | null;

    @ApiProperty({ description: 'User 주파수', example: 5.0 })
    frequency!: number;

    @ApiProperty({ description: 'User가 받은 좋아요 수', example: 20 })
    totalLikesReceived!: number;

    @ApiProperty({ description: 'User 댓글 수', example: 10})
    totalCommentsSent!: number;

    @ApiProperty({ description: 'User 생성일', example: '2023-10-01T12:34:56Z' })
    createdAt!: Date;
}
