import { PartialType } from '@nestjs/swagger';
import { CreateStoryDto } from './create-story.dto';

// PartialType: Creates a type with all the properties of CreateStoryDto set to optional
export class UpdateStoryDto extends PartialType(CreateStoryDto) {}