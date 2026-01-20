import { Controller, Get, Req, Res, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';
import type { Response, Request } from 'express';
import { ConfigService } from '@nestjs/config';
import { SessionAuthGuard } from './guards/session-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly configService: ConfigService,
  ) {}

  // ✅ Google OAuth 시작 (passport가 redirect 처리)
  @Get('google')
  @UseGuards(AuthGuard('google'))
  async googleAuth(@Req() _req) {}

  // ✅ Google OAuth callback
  @Get('google/callback')
  @UseGuards(AuthGuard('google'))
  async googleAuthRedirect(@Req() req, @Res() res: Response) {
    const { user, sessionToken, expiresAt } = await this.authService.googleLogin(req.user);

    const cookieName = this.configService.get<string>('SESSION_COOKIE_NAME') ?? 'session';
    const isProd = this.configService.get<string>('NODE_ENV') === 'production';
    const sameSite =
      (this.configService.get<string>('SESSION_COOKIE_SAMESITE') as 'lax' | 'none' | 'strict') ??
      (isProd ? 'none' : 'lax');

    // ✅ 브라우저 쿠키도 유지(웹 대응)
    res.cookie(cookieName, sessionToken, {
      httpOnly: true,
      secure: isProd,
      sameSite,
      expires: expiresAt,
      path: '/',
    });

    // ✅ 모바일 딥링크 redirect (핵심)
    // 예: MOBILE_REDIRECT_URI=madcamp2://auth
    const mobileRedirect =
      this.configService.get<string>('MOBILE_REDIRECT_URI') ?? 'madcamp2://auth';

    const redirectUrl =
      `${mobileRedirect}?sessionToken=${encodeURIComponent(sessionToken)}`;

    return res.redirect(redirectUrl);
  }

  @Get('logout')
  async logout(@Req() req: Request, @Res() res: Response) {
    const cookieName = this.configService.get<string>('SESSION_COOKIE_NAME') ?? 'session';
    const sessionToken = req.cookies?.[cookieName];

    if (sessionToken) {
      await this.authService.logout(sessionToken);
    }

    res.clearCookie(cookieName, {
      path: '/',
      secure: this.configService.get('NODE_ENV') === 'production',
      sameSite: this.configService.get('NODE_ENV') === 'production' ? 'none' : 'lax',
    });

    const mobileRedirect =
      this.configService.get<string>('MOBILE_REDIRECT_URI') ?? 'madcamp2://auth';

    return res.redirect(`${mobileRedirect}?loggedOut=true`);
  }

  // ✅ 앱이 로그인 여부 확인할 API
  // Flutter는 Cookie 헤더로 session을 실어 보냄
  @UseGuards(SessionAuthGuard)
  @Get('me')
  getMe(@Req() req: Request) {
    return {
      success: true,
      user: (req as any).user,
    };
  }
}
