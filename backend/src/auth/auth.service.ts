import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import { createHash, randomBytes } from 'crypto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  async googleLogin(reqUser: any) {
    if (!reqUser?.email) {
      throw new UnauthorizedException('No user from Google');
    }

    let user = await this.prisma.user.findUnique({
      where: { email: reqUser.email },
    });

    if (!user) {
      const nickname = reqUser.name ?? reqUser.email.split('@')[0];
      user = await this.prisma.user.create({
        data: {
          email: reqUser.email,
          nickname,
          name: reqUser.name ?? null,
          image: reqUser.picture ?? null,
        },
      });
    }

    const { sessionToken, expiresAt } = await this.createSession(user.id);

    return {
      user,
      sessionToken,
      expiresAt,
    };
  }

  async logout(sessionToken: string) {
    try {
      await this.prisma.session.delete({
        where: {sessionToken}
      });
    } catch (error) {
      return;
    }
  }

  async validateSession(sessionToken: string) {
    if (!sessionToken) {
      return null;
    }

    const hashedToken = this.hashSessionToken(sessionToken);
    return this.prisma.session.findFirst({
      where: {
        sessionToken: hashedToken,
        expires: { gt: new Date() },
      },
      include: {
        user: true,
      },
    });
  }

  async createSession(userId: string) {
    const token = randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + this.getSessionTtlMs());

    await this.prisma.session.create({
      data: {
        userId,
        sessionToken: this.hashSessionToken(token),
        expires: expiresAt,
      },
    });

    return { sessionToken: token, expiresAt };
  }

  private getSessionTtlMs() {
    const ttlDays = Number(this.configService.get('SESSION_TTL_DAYS') ?? 7);
    return ttlDays * 24 * 60 * 60 * 1000;
  }

  private hashSessionToken(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }
}
