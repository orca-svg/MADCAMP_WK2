import { Controller, Get, Req, Res, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';
import type { Response } from 'express';
import { ConfigService } from '@nestjs/config';
import { SessionAuthGuard } from './guards/session-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly configService: ConfigService,
  ) {}

  @Get('google')
  @UseGuards(AuthGuard('google'))
  async googleAuth(@Req() req) {}

  @Get('google/callback')
  @UseGuards(AuthGuard('google'))
  async googleAuthRedirect(@Req() req, @Res({ passthrough: true }) res: Response) {
    const { user, sessionToken, expiresAt } = await this.authService.googleLogin(req.user);
    const cookieName = this.configService.get<string>('SESSION_COOKIE_NAME') ?? 'session';
    const isProd = this.configService.get<string>('NODE_ENV') === 'production';
    const sameSite =
      (this.configService.get<string>('SESSION_COOKIE_SAMESITE') as 'lax' | 'none' | 'strict') ??
      (isProd ? 'none' : 'lax');

    res.cookie(cookieName, sessionToken, {
    httpOnly: true,
    secure: isProd,
    sameSite,
    expires: expiresAt,
    path: '/',
  });

  return res.redirect('https://reso-app.cloud');
}
}
