import { Injectable } from '@nestjs/common';
import { CreateStoryDto } from './dto/create-story.dto';
import { UpdateStoryDto } from './dto/update-story.dto';
import { PrismaService } from 'src/prisma/prisma.service';

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

  findAll() {
    return this.prisma.story.findMany({ 
      where: { isPublic: true },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { nickname: true } },
        tags: true
      }
    });
  }

  findOne(id: string) {
    return this.prisma.story.findUnique({ 
      where: { id },
      include: {
        comments: true,
        tags: true
      },
    });
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
