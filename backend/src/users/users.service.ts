import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { PrismaService } from 'src/prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor (private readonly prisma: PrismaService) {}

  async create(createUserDto: CreateUserDto) {
    const { email, nickname, name, image } = createUserDto;
    
    const existingUser = await this.prisma.user.findUnique({
      where: { email },
    });
    if (existingUser) {
      throw new Error('Email already in use');
    }

const newUser = await this.prisma.user.create({
      data: {
        email,
        nickname,
        name,
        image,
      },
    });
    
    return newUser;
  }

  async findAll() {
    const users = await this.prisma.user.findMany();

    return users.map((user) => {
      return user;
    });
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: id }
    })

    if (!user) {
      throw new NotFoundException(`Id가 ${id}인 유저를 찾을 수 없습니다.`);
    }

    return user;
  }

  async update(id: string, updateUserDto: UpdateUserDto) {
    await this.findOne(id);

    const updatedUser = await this.prisma.user.update({
        where: { id },
        data: updateUserDto,
      });

      return updatedUser;
  }

  async remove(id: string) {
    await this.findOne(id);

    return this.prisma.user.delete({
      where: { id: id}
    });
  }
}
