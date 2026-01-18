import { Controller, Get, Post, Body, Patch, Param, Delete, Res } from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { ApiPostResponse } from 'src/common/decorators/swagger.decorator';
import { UserEntity } from './entities/user.entity';
import { ResponseMessage } from 'src/common/decorators/response-message.decorator';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @ApiPostResponse(UserEntity, '유저 생성하기')
  @ResponseMessage('유저가 성공적으로 생성되었습니다.')
  create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @Get()
  @ApiPostResponse(UserEntity, '모든 유저 조회하기')
  @ResponseMessage('모든 유저를 성공적으로 조회했습니다.')
  findAll() {
    return this.usersService.findAll();
  }

  @Get(':id')
  @ApiPostResponse(UserEntity, '유저 상세 조회하기')
  @ResponseMessage('유저 상세 정보를 성공적으로 조회했습니다.')
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Patch(':id')
  @ApiPostResponse(UserEntity, '유저 정보 수정하기')
  @ResponseMessage('유저 정보가 성공적으로 수정되었습니다.')
  update(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
    return this.usersService.update(id, updateUserDto);
  }

  @Delete(':id')
  @ApiPostResponse(UserEntity, '유저 삭제하기')
  @ResponseMessage('유저가 성공적으로 삭제되었습니다.')
  remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }
}
