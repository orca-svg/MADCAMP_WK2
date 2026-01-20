import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateCommentDto } from './dto/create-comment.dto';
import { PrismaService } from 'src/prisma/prisma.service';

@Injectable()
export class CommentsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, createCommentDto: CreateCommentDto) {
    const { storyId, content } = createCommentDto;

    const [user, story] = await Promise.all([
      this.prisma.user.findUnique({ where: { id: userId } }),
      this.prisma.story.findUnique({ where: { id: storyId } }),
    ]);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (!story) {
      throw new NotFoundException('Story not found');
    }

    return this.prisma.comment.create({
      data: {
        userId,
        storyId,
        content,
      },
    });
  }

  async toggleLike(userId: string, commentId: string) {
    const existingLike = await this.prisma.commentLike.findUnique({
      where: {
        userId_commentId: { userId, commentId }
      }
    });

    if (existingLike) {
      await this.prisma.$transaction([
        this.prisma.commentLike.delete({ where: { id: existingLike.id } }),
        this.prisma.comment.update({
          where: { id: commentId },
          data: { likeCount: { decrement: 1 } }
        })
      ]);
      return { liked: false };
    } else {
        await this.prisma.$transaction([
          this.prisma.commentLike.create({ data: { userId, commentId } }),
          this.prisma.comment.update({
            where: { id: commentId },
            data: { likeCount: { increment: 1 } }
          })
        ]);
      return { liked: true };
    }
  }

  async findAll(storyId: string, userId?: string) {
    const story = await this.prisma.story.findUnique({ where: { id: storyId } });
    if (!story) {
      throw new NotFoundException('Story not found');
    }

    const comments = await this.prisma.comment.findMany({
      where: { storyId },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { nickname: true, image: true } },
        _count: {
          select: { likes: true },
        },
        likes: userId
          ? {
            where: { userId },
            take: 1,
          }
          : false,
      },
    });

    return comments.map((comment) => {
      const { likes, ...rest } = comment;
      return {
        ...rest,
        isLiked: likes && likes.length > 0,
      };
    }); 
  }

  async remove(id: string) {
    const comment = await this.prisma.comment.findUnique({ where: { id } });
    if (!comment) {
      throw new NotFoundException('Comment not found');
    }

    return this.prisma.comment.delete({ where: { id } });
  }
}
