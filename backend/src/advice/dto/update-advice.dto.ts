import { PartialType } from '@nestjs/swagger';
import { CreateAdviceDto } from './create-advice.dto';

export class UpdateAdviceDto extends PartialType(CreateAdviceDto) {}
