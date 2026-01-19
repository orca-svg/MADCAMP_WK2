import { IsString, IsNotEmpty, IsEmail, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateUserDto {
  @ApiProperty({
    description: 'User 이메일',
    example: 'test@example.com'
  })
  @IsEmail()
  @IsNotEmpty()
  email!: string;

  @ApiProperty({
    description: 'User 이름 (구글 프로필 이름)',
    example: '홍길동',
    required: false
  })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiProperty({
    description: 'User 프로필 사진 URL',
    example: 'https://lh3.googleusercontent.com/...',
    required: false
  })
  @IsString()
  @IsOptional()
  image?: string;

  @ApiProperty({
    description: 'User 닉네임',
    example: '길동이',
    required: false
  })
  @IsString()
  @IsOptional()
  nickname?: string;
}