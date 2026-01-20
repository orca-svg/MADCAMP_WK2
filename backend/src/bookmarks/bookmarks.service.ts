import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { CreateBookmarkDto } from './dto/create-bookmark.dto';
import { PrismaService } from 'src/prisma/prisma.service';

@Injectable()
export class BookmarksService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, createBookmarkDto: CreateBookmarkDto) {
    const { adviceId } = createBookmarkDto;

    const [user, advice] = await Promise.all([
      this.prisma.user.findUnique({ where: { id: userId } }),
      this.prisma.advice.findUnique({ where: { id: adviceId } }),
    ]);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (!advice) {
      throw new NotFoundException('Advice not found');
    }

    const existing = await this.prisma.bookmark.findUnique({
      where: {
        userId_adviceId: {
          userId,
          adviceId,
        },
      },
    });

    if (existing) {
      throw new ConflictException('Bookmark already exists');
    }

    return this.prisma.bookmark.create({
      data: {
        userId,
        adviceId,
      },
    });
  }

  async findAll(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.prisma.bookmark.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: {
        advice: true,
      },
    });
  }

  async remove(userId: string, adviceId: string) {
    const existing = await this.prisma.bookmark.findUnique({
      where: {
        userId_adviceId: {
          userId,
          adviceId,
        },
      },
    });

    if (!existing) {
      throw new NotFoundException('Bookmark not found');
    }

    return this.prisma.bookmark.delete({
      where: {
        userId_adviceId: {
          userId,
          adviceId,
        },
      },
    });
  }
}
