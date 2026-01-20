import { Injectable } from '@nestjs/common';
import { CreateStoryDto } from './dto/create-story.dto';
import { UpdateStoryDto } from './dto/update-story.dto';
import { PrismaService } from 'src/prisma/prisma.service';
import { NotFoundException } from '@nestjs/common';

@Injectable()
export class StoriesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, createStoryDto: CreateStoryDto) {
    const { tagNames, ...storyData } = createStoryDto;

    const myStory = await this.prisma.story.create({
      data: {
        ...storyData,
        userId,
        tags: {
          connectOrCreate: tagNames?.map((name) => ({
            where: { name },
            create: { name }
          })),
        }
      }
    });

    // 추후 유사도 기반으로 변경 예정, Limit?
    const similarStories = await this.prisma.$queryRaw`
      SELECT id, title, content, emotion, "createdAt"
      FROM "Story"
      WHERE "isPublic" = true
      AND id != ${myStory.id}
      ORDER BY RANDOM()
      LIMIT 5
    `;

    return {
      myStory,
      similarStories,
    };
  }

  async toggleLike(userId: string, storyId: string) {
    const existingLike = await this.prisma.storyLike.findUnique({
      where: {
        userId_storyId: { userId, storyId }
      }
    });

        if (existingLike) {
      await this.prisma.$transaction([
        this.prisma.storyLike.delete({ where: { id: existingLike.id } }),
        this.prisma.story.update({
          where: { id: storyId },
          data: { likeCount: { decrement: 1 } }
        })
      ]);
      return { liked: false };
    } else {
        await this.prisma.$transaction([
          this.prisma.storyLike.create({ data: { userId, storyId } }),
          this.prisma.story.update({
            where: { id: storyId },
            data: { likeCount: { increment: 1 } }
          })
        ]);
      return { liked: true };
    }
  }

  async findAll(userId?: string) {
    const stories = await this.prisma.story.findMany({ 
      where: { isPublic: true },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { nickname: true } },
        tags: true,
        likes: userId ? { where: { userId }, take: 1 } : false,
      }
    });

    return stories.map(story => {
      const { likes, ...rest } = story;
      return {
        ...rest,
        isLiked: !!(likes && likes.length > 0),
      };
    });
  }

  async findOne(id: string, userId?: string) {
    const story = await this.prisma.story.findUnique({
      where: { id },
      include: {
        user: { select: { nickname: true, image: true } },
        tags: true,
        comments: {
          orderBy: { createdAt: 'desc' },
          include: { user: { select: { nickname: true } } }
        },
        
        likes: userId ? {
          where: { userId },
          take: 1
        } : false,
      },
    });

  if (!story) {
    throw new NotFoundException('Story not found');
  }

  const { likes, ...rest } = story;
  
  return {
    ...rest,
    isLiked: !!(likes && likes.length > 0),
  };
  }

  update(id: string, updateStoryDto: UpdateStoryDto) {
    return this.prisma.story.update({
      where: { id },
      data: updateStoryDto,
    });
  }

  remove(id: string) {
    return this.prisma.story.delete({
      where: { id },
    });
  }
}
