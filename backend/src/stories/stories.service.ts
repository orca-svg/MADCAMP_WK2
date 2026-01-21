import { Injectable, NotFoundException, ForbiddenException, Logger } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { EmbeddingService } from 'src/embedding/embedding.service';

import { CreateStoryDto } from './dto/create-story.dto';
import { UpdateStoryDto } from './dto/update-story.dto';

@Injectable()
export class StoriesService {
  private readonly logger = new Logger(StoriesService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly embeddingService: EmbeddingService,
  ) {}

  /**
   * B 방식:
   * - create는 myStory + similarStories를 반환
   * - similarStories는 public 중에서 랜덤 5개 (스키마에 없는 컬럼 emotion 제거)
   */
  async create(userId: string, createStoryDto: CreateStoryDto) {
    const { tagNames, ...storyData } = createStoryDto;
    const embeddingText = [storyData.title, storyData.content]
      .filter(Boolean)
      .join('\n')
      .trim();
    let embedding: number[] | null = null;
    try {
      embedding = await this.embeddingService.embedOne(embeddingText);
    } catch (error) {
      this.logger.warn('Embedding failed; saving story without embedding.', error as Error);
    }

    const myStory = await this.prisma.story.create({
      data: {
        ...storyData, // title, content, isPublic 등
        userId,
        tags: {
          connectOrCreate: (tagNames ?? []).map((name) => ({
            where: { name },
            create: { name },
          })),
        },
      },
      include: {
        tags: true,
        user: { select: { nickname: true, image: true } },
      },
    });

    // 유사도는 추후 vector로. 현재는 랜덤 5개.
    let similarStories: any[] = [];
    if (embedding) {
      try {
        await this._setStoryEmbedding(myStory.id, embedding);
        similarStories = await this._findSimilarStories(
          embedding,
          myStory.id,
          userId,
          5,
        );
      } catch (error) {
        this.logger.warn('Embedding save or search failed; falling back.', error as Error);
      }
    }
    if (!embedding || similarStories.length === 0) {
      similarStories = await this._findFallbackStories(myStory.id, userId, 5);
    }

    return {
      myStory: this._toStoryListItem(myStory, userId),
      similarStories,
    };
  }

  async toggleLike(userId: string, storyId: string) {
    const story = await this.prisma.story.findUnique({ where: { id: storyId } });
    if (!story) throw new NotFoundException('Story not found');

    const existingLike = await this.prisma.storyLike.findUnique({
      where: { userId_storyId: { userId, storyId } },
    });

    if (existingLike) {
      const [, updated] = await this.prisma.$transaction([
        this.prisma.storyLike.delete({ where: { id: existingLike.id } }),
        this.prisma.story.update({
          where: { id: storyId },
          data: { likeCount: { decrement: 1 } },
        }),
      ]);
      return { liked: false, likeCount: updated.likeCount };
    }

    const [, updated] = await this.prisma.$transaction([
      this.prisma.storyLike.create({ data: { userId, storyId } }),
      this.prisma.story.update({
        where: { id: storyId },
        data: { likeCount: { increment: 1 } },
      }),
    ]);
    return { liked: true, likeCount: updated.likeCount };
  }

  /**
   * 공개된 사연들 (OpenScreen 용)
   * - isLiked: 현재 유저가 좋아요 했는지
   * - acceptedCommentId: best comment id (없으면 null)
   */
  async findAll(userId: string, mineOnly = false) {
    try {
      const check = await this.prisma.$queryRaw`
        SELECT id, title, embedding::text 
        FROM "Story" 
        WHERE embedding IS NOT NULL 
        LIMIT 1
      `;
      console.log('🔎 벡터 데이터 확인:', check);
    } catch (e) {
      console.error('⚠️ 벡터 확인 실패:', e);
    }

    const where = mineOnly ? { userId } : { isPublic: true };
    const stories = await this.prisma.story.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { nickname: true, image: true, id: true } },
        tags: true,
        likes: { where: { userId }, take: 1 },
        comments: { where: { isBest: true }, select: { id: true }, take: 1 },
      },
    });

    return stories.map((s) => this._toStoryListItem(s, userId));
  }

  /**
   * 상세 (OpenDetailScreen 용)
   * - comments 포함
   */
  async findOne(id: string, userId: string) {
    const story = await this.prisma.story.findUnique({
      where: { id },
      include: {
        user: { select: { nickname: true, image: true, id: true } },
        tags: true,
        likes: { where: { userId }, take: 1 },
        comments: {
          orderBy: { createdAt: 'desc' },
          include: {
            user: { select: { nickname: true, image: true, id: true } },
            likes: { where: { userId }, take: 1 },
          },
        },
      },
    });

    if (!story) throw new NotFoundException('Story not found');

    const accepted = story.comments.find((c) => c.isBest)?.id ?? null;

    return {
      id: story.id,
      title: story.title,
      content: story.content,
      isPublic: story.isPublic,
      likeCount: story.likeCount,
      createdAt: story.createdAt,
      user: story.user,
      tags: story.tags,
      isLiked: story.likes.length > 0,
      acceptedCommentId: accepted,
      comments: story.comments.map((c) => ({
        id: c.id,
        content: c.content,
        isBest: c.isBest,
        likeCount: c.likeCount,
        createdAt: c.createdAt,
        user: c.user,
        isLiked: c.likes.length > 0,
      })),
    };
  }

  async update(userId: string, id: string, updateStoryDto: UpdateStoryDto) {
    const story = await this.prisma.story.findUnique({ where: { id } });
    if (!story) throw new NotFoundException('Story not found');
    if (story.userId !== userId) throw new ForbiddenException('No permission');

    // tag 수정까지 필요하면 UpdateStoryDto에 tagNames를 넣고 별도로 처리해야 합니다.
    return this.prisma.story.update({
      where: { id },
      data: updateStoryDto as any,
    });
  }

  async remove(userId: string, id: string) {
    const story = await this.prisma.story.findUnique({ where: { id } });
    if (!story) throw new NotFoundException('Story not found');
    if (story.userId !== userId) throw new ForbiddenException('No permission');

    return this.prisma.story.delete({ where: { id } });
  }

  // -----------------------
  // Private helpers
  // -----------------------
  private _toStoryListItem(story: any, currentUserId: string) {
    const acceptedCommentId =
      (story.comments?.[0]?.id as string | undefined) ?? null;

    return {
      id: story.id,
      title: story.title,
      content: story.content,
      isPublic: story.isPublic,
      likeCount: story.likeCount,
      createdAt: story.createdAt,
      user: story.user
        ? { id: story.user.id, nickname: story.user.nickname, image: story.user.image }
        : null,
      tags: (story.tags ?? []).map((t: any) => t.name ?? t),
      isLiked: Array.isArray(story.likes) ? story.likes.length > 0 : false,
      acceptedCommentId,
    };
  }

  private _vectorLiteral(vector: number[]) {
    return `[${vector.join(',')}]`;
  }

  private async _setStoryEmbedding(storyId: string, vector: number[]) {
    const literal = this._vectorLiteral(vector);
    await this.prisma.$executeRawUnsafe(
      `UPDATE "Story" SET "embedding" = $1::vector WHERE id = $2`,
      literal,
      storyId,
    );
  }

  private async _findSimilarStories(
    vector: number[],
    storyId: string,
    userId: string,
    limit: number,
  ) {
    const literal = this._vectorLiteral(vector);
    const rows = (await this.prisma.$queryRawUnsafe(
      `SELECT id
       FROM "Story"
       WHERE "embedding" IS NOT NULL
         AND "isPublic" = true
         AND id <> $1
       ORDER BY "embedding" <=> $2::vector
       LIMIT $3`,
      storyId,
      literal,
      limit,
    )) as { id: string }[];

    if (rows.length === 0) {
      return [];
    }

    const ids = rows.map((row) => row.id);
    const stories = await this.prisma.story.findMany({
      where: { id: { in: ids } },
      include: {
        user: { select: { nickname: true, image: true, id: true } },
        tags: true,
        likes: { where: { userId }, take: 1 },
        comments: { where: { isBest: true }, select: { id: true }, take: 1 },
      },
    });

    const storyMap = new Map(stories.map((story) => [story.id, story]));
    return ids
      .map((id) => storyMap.get(id))
      .filter((story): story is NonNullable<typeof story> => Boolean(story))
      .map((story) => this._toStoryListItem(story, userId));
  }

  private async _findFallbackStories(storyId: string, userId: string, limit: number) {
    const stories = await this.prisma.story.findMany({
      where: { isPublic: true, id: { not: storyId } },
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: {
        user: { select: { nickname: true, image: true, id: true } },
        tags: true,
        likes: { where: { userId }, take: 1 },
        comments: { where: { isBest: true }, select: { id: true }, take: 1 },
      },
    });

    return stories.map((story) => this._toStoryListItem(story, userId));
  }
}
