import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import * as bcrypt from 'bcrypt';
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
      const hashedPassword = await bcrypt.hash('GOOGLE_LOGIN_USER', 10);
      user = await this.prisma.user.create({
        data: {
          email: reqUser.email,
          nickname,
          password: hashedPassword,
        },
      });
    }
    const { password, ...safeUser } = user;

    return {
      message: 'Google Login Success!',
      user: safeUser,
    };
  }
}
