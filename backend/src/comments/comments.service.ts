import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateCommentDto } from './dto/create-comment.dto';

@Injectable()
export class CommentsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, createCommentDto: CreateCommentDto) {
    const { storyId, content } = createCommentDto;

    const story = await this.prisma.story.findUnique({ where: { id: storyId } });
    if (!story) throw new NotFoundException('Story not found');

    const created = await this.prisma.comment.create({
      data: { userId, storyId, content },
      include: { user: { select: { id: true, nickname: true, image: true } } },
    });

    return {
      id: created.id,
      content: created.content,
      isBest: created.isBest,
      likeCount: created.likeCount,
      createdAt: created.createdAt,
      user: created.user,
      isLiked: false,
    };
  }

  async toggleLike(userId: string, commentId: string) {
    const comment = await this.prisma.comment.findUnique({ where: { id: commentId } });
    if (!comment) throw new NotFoundException('Comment not found');

    const existingLike = await this.prisma.commentLike.findUnique({
      where: { userId_commentId: { userId, commentId } },
    });

    if (existingLike) {
      const [, updated] = await this.prisma.$transaction([
        this.prisma.commentLike.delete({ where: { id: existingLike.id } }),
        this.prisma.comment.update({
          where: { id: commentId },
          data: { likeCount: { decrement: 1 } },
        }),
      ]);
      return { liked: false, likeCount: updated.likeCount };
    }

    const [, updated] = await this.prisma.$transaction([
      this.prisma.commentLike.create({ data: { userId, commentId } }),
      this.prisma.comment.update({
        where: { id: commentId },
        data: { likeCount: { increment: 1 } },
      }),
    ]);
    return { liked: true, likeCount: updated.likeCount };
  }

  async findAll(storyId: string, userId: string) {
    const story = await this.prisma.story.findUnique({ where: { id: storyId } });
    if (!story) throw new NotFoundException('Story not found');

    const comments = await this.prisma.comment.findMany({
      where: { storyId },
      orderBy: [{ isBest: 'desc' }, { createdAt: 'desc' }], // ✅ best 먼저
      include: {
        user: { select: { id: true, nickname: true, image: true } },
        likes: { where: { userId }, take: 1 },
      },
    });

    return comments.map((c) => ({
      id: c.id,
      content: c.content,
      isBest: c.isBest,
      likeCount: c.likeCount,
      createdAt: c.createdAt,
      user: c.user,
      isLiked: c.likes.length > 0,
    }));
  }

  async remove(userId: string, id: string) {
    const comment = await this.prisma.comment.findUnique({ where: { id } });
    if (!comment) throw new NotFoundException('Comment not found');
    if (comment.userId !== userId) throw new ForbiddenException('No permission');

    return this.prisma.comment.delete({ where: { id } });
  }
}
