import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService) {}

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
          name: reqUser.name || null,
          image: reqUser.picture || null,
        },
      });
    }

    return {
      message: 'Google Login Success!',
      user: user,
    };
  }
}
