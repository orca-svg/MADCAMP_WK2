import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { AuthService } from '../auth.service';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class SessionAuthGuard implements CanActivate {
  constructor(
    private readonly authService: AuthService,
    private readonly configService: ConfigService,
  ) {}

  async canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest();
    const cookieName = this.configService.get<string>('SESSION_COOKIE_NAME') ?? 'session';
    const sessionToken = request.cookies?.[cookieName];

    if (!sessionToken) {
      throw new UnauthorizedException('Session cookie missing');
    }

    const session = await this.authService.validateSession(sessionToken);
    if (!session) {
      throw new UnauthorizedException('Invalid or expired session');
    }

    request.user = session.user;
    request.session = session;
    return true;
  }
}
