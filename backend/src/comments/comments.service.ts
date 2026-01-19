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

  async findAll(storyId: string) {
    const story = await this.prisma.story.findUnique({ where: { id: storyId } });
    if (!story) {
      throw new NotFoundException('Story not found');
    }

    return this.prisma.comment.findMany({
      where: { storyId },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { nickname: true } },
      },
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
