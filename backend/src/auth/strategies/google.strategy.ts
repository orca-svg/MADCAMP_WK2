import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy, Profile } from 'passport-google-oauth20';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  constructor(configService: ConfigService) {
    super({
      clientID: configService.getOrThrow<string>('GOOGLE_CLIENT_ID'),
      clientSecret: configService.getOrThrow<string>('GOOGLE_CLIENT_SECRET'),
      callbackURL: configService.getOrThrow<string>('GOOGLE_CALLBACK_URL'),
      scope: ['email', 'profile'],
      // passReqToCallback: false, // 필요하면 추가
    });
  }

  async validate(accessToken: string, refreshToken: string, profile: Profile) {
    const { id, emails, displayName, photos } = profile;

    return {
      provider: 'google',
      providerId: id,
      email: emails?.[0]?.value,
      name: displayName,
      picture: photos?.[0]?.value,
    };
  }
}
