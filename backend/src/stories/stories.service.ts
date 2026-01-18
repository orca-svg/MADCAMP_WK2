import { Injectable } from '@nestjs/common';
import { CreateStoryDto } from './dto/create-story.dto';
import { UpdateStoryDto } from './dto/update-story.dto';
import { Emotion } from '@prisma/client';
import { PrismaService } from 'src/prisma/prisma.service';

@Injectable()
export class StoriesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, createStoryDto: CreateStoryDto) {
    const { title, content, isPublic, emotion } = createStoryDto;

    let finalEmotion = emotion;
    if (!finalEmotion) {
      const emotions = Object.values(Emotion);
      finalEmotion = emotions[Math.floor(Math.random() * emotions.length)];
    }

    const myStory = await this.prisma.story.create({
      data: {
        userId: userId,
        title: title,
        content: content,
        isPublic: isPublic ?? false,
        emotion: finalEmotion,
      }
    });

    // 추후 유사도 기반으로 변경 예정, Limit?
    const similarStories = await this.prisma.$queryRaw`
      SELECT id, title, content, emotion, "createdAt"
      FROM "Story"
      WHERE emotion = ${finalEmotion}::"Emotion"
      AND "isPublic" = true
      AND id != ${myStory.id}
      ORDER BY RANDOM()
      LIMIT 5
    `;

    return {
      message: '사연이 송신되었습니다.',
      myStory,
      similarStories,
    };
  }

  findAll() {
    return this.prisma.story.findMany({ 
      where: { isPublic: true },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { nickname: true } }
      }
    });
  }

  findOne(id: string) {
    return this.prisma.story.findUnique({ 
      where: { id },
      include: {
        comments: true,
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
