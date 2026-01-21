import { Injectable, NotFoundException, ForbiddenException, ConflictException } from '@nestjs/common';
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

  /**
   * Get all adopted comments authored by the current user
   */
  async findMyAdopted(userId: string) {
    const comments = await this.prisma.comment.findMany({
      where: { userId, isBest: true },
      orderBy: { createdAt: 'desc' },
      include: {
        story: { select: { id: true, title: true, createdAt: true } },
      },
    });

    return comments.map((c) => ({
      id: c.id,
      content: c.content,
      likeCount: c.likeCount,
      createdAt: c.createdAt,
      story: c.story,
    }));
  }

  async remove(userId: string, id: string) {
    const comment = await this.prisma.comment.findUnique({
      where: { id },
      select: { id: true, userId: true, storyId: true },
    });
    if (!comment) throw new NotFoundException('Comment not found');

    // ✅ 작성자 본인 OR 사연 작성자(스토리 오너)만 삭제 가능
    if (comment.userId !== userId) {
      const story = await this.prisma.story.findUnique({
        where: { id: comment.storyId },
        select: { userId: true },
      });
      if (!story || story.userId !== userId) throw new ForbiddenException('No permission');
    }

    return this.prisma.comment.delete({ where: { id } });
  }

  /**
   * Adopt a comment (one-way, one per story)
   * - Only story owner can adopt
   * - A story can have at most ONE adopted comment
   * - If already adopted, return success without changing
   */
  async adopt(userId: string, commentId: string) {
    // 1. Fetch comment with its story
    const comment = await this.prisma.comment.findUnique({
      where: { id: commentId },
      include: { story: { select: { id: true, userId: true } } },
    });
    if (!comment) throw new NotFoundException('Comment not found');

    // 2. Ownership check: only story owner can adopt
    if (comment.story.userId !== userId) {
      throw new ForbiddenException('Only the story owner can adopt a comment');
    }

    // 3. If this comment is already adopted, return success (idempotent)
    if (comment.isBest) {
      return {
        id: comment.id,
        content: comment.content,
        isBest: comment.isBest,
        likeCount: comment.likeCount,
        createdAt: comment.createdAt,
        adopted: true,
      };
    }

    // 4. Scarcity check: does the story already have an adopted comment?
    const existingAdopted = await this.prisma.comment.findFirst({
      where: { storyId: comment.storyId, isBest: true },
    });
    if (existingAdopted) {
      throw new ConflictException('This story already has an adopted comment');
    }

    // 5. Adopt: set isBest = true
    const updated = await this.prisma.comment.update({
      where: { id: commentId },
      data: { isBest: true },
    });

    return {
      id: updated.id,
      content: updated.content,
      isBest: updated.isBest,
      likeCount: updated.likeCount,
      createdAt: updated.createdAt,
      adopted: true,
    };
  }
}
