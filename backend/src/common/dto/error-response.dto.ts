import { ApiProperty } from "@nestjs/swagger";

export class ErrorResponseDto {
    @ApiProperty({ description: '성공 여부', example: false })
    success: boolean;

    @ApiProperty({ description: '에러 메시지', example: '서버 내부에 오류가 발생했습니다.'})
    message: string;

    @ApiProperty({ description: '데이터', example: null, nullable: true})
    data: any;
}   