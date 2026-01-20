import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { GoogleStrategy } from './strategies/google.strategy';
import { PrismaService } from 'src/prisma/prisma.service';
import { SessionAuthGuard } from './guards/session-auth.guard';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from 'src/prisma/prisma.module';

@Module({
  imports: [
    PassportModule,
    ConfigModule,
    PrismaModule
  ],
  exports: [AuthService],
  controllers: [AuthController],
  providers: [AuthService, GoogleStrategy, SessionAuthGuard],
})
export class AuthModule {}
