import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { StoriesModule } from './stories/stories.module';
import { UsersModule } from './users/users.module';
import { CommentsModule } from './comments/comments.module';
import { AdviceModule } from './advice/advice.module';
import { BookmarksModule } from './bookmarks/bookmarks.module';

@Module({
  imports: [PrismaModule, StoriesModule, UsersModule, CommentsModule, AdviceModule, BookmarksModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
