import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';

@Injectable()
export class AdviceService {
  constructor(private readonly prisma: PrismaService) {}

  findAll() {
    return this.prisma.advice.findMany();
  }

  async funcRandom() {
    const advice = await this.prisma.$queryRaw<
      { id: string; content: string; author: string | null }[]
    >`
      SELECT id, content, author
      FROM "Advice"
      ORDER BY RANDOM()
      LIMIT 1;
    `;

    if (!advice[0]) {
      throw new NotFoundException('Advice not found');
    }

    return advice[0];
  }
}
