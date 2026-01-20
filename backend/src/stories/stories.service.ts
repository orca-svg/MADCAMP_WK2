import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';

import { CreateStoryDto } from './dto/create-story.dto';
import { UpdateStoryDto } from './dto/update-story.dto';

@Injectable()
export class StoriesService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * B 방식:
   * - create는 myStory + similarStories를 반환
   * - similarStories는 public 중에서 랜덤 5개 (스키마에 없는 컬럼 emotion 제거)
   */
  async create(userId: string, createStoryDto: CreateStoryDto) {
    const { tagNames, ...storyData } = createStoryDto;

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
    const similarStories = await this.prisma.story.findMany({
      where: { isPublic: true, id: { not: myStory.id } },
      orderBy: { createdAt: 'desc' }, // 랜덤 대신 일단 최신 (원하시면 RANDOM() raw로 바꿔드릴게요)
      take: 5,
      include: {
        tags: true,
        user: { select: { nickname: true, image: true } },
      },
    });

    return {
      myStory: this._toStoryListItem(myStory, userId),
      similarStories: similarStories.map((s) => this._toStoryListItem(s, userId)),
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
  async findAll(userId: string) {
    const stories = await this.prisma.story.findMany({
      where: { isPublic: true },
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
}
