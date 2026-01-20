import { PartialType } from '@nestjs/swagger';
import { CreateUserDto } from './create-user.dto';
import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class UpdateUserDto {
    @ApiProperty({
        description: '변경할 닉네임',
        example: '새로운 길동이',
        required: false,
    })
    @IsOptional()
    @IsString()
    nickname?: string;
}