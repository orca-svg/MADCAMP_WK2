import { PartialType } from '@nestjs/swagger';
import { CreateUserDto } from './create-user.dto';
import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class UpdateUserDto extends PartialType(CreateUserDto) {
    @ApiProperty({
        description: '변경할 닉네임',
        example: '새로운 길동이',
        required: false,
    })
    @IsOptional()
    @IsString()
    nickname?: string;

    @ApiProperty({
        description: '변경할 비밀번호',
        example: 'newstrongpassword123',
        required: false,
    })
    @IsOptional()
    @IsString()
    password?: string;
    
    @ApiProperty({
        description: '변경할 이메일',
        example: 'newemail@example.com',
        required: false,
    })
    @IsOptional()
    @IsString()
    email?: string;
}