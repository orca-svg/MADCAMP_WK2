import { IsString, IsNotEmpty, IsEmail } from 'class-validator';
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
        description: 'User 비밀번호',
        example: 'strongpassword123'
    })
    @IsString()
    @IsNotEmpty()
    password!: string;

    @ApiProperty({
        description: 'User 닉네임',
        example: '길동이'
    })
    @IsString()
    @IsNotEmpty()
    nickname!: string;
}
