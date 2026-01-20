import { applyDecorators, Type } from '@nestjs/common';
import { ApiCreatedResponse, ApiOkResponse, ApiOperation, ApiInternalServerErrorResponse, ApiBadRequestResponse } from '@nestjs/swagger';
import { ErrorResponseDto } from '../dto/error-response.dto';

export function ApiPostResponse<T extends Type<any>>(dataModel: T, summary: string) {
    return applyDecorators(
        ApiOperation({ summary }),

        ApiCreatedResponse({
            description: '성공적으로 생성되었습니다.',
            type: dataModel,
        }),

        ApiBadRequestResponse({ description: '잘못된 요청입니다', type: () => ErrorResponseDto}),
        ApiInternalServerErrorResponse({ description: '서버 에러', type: () => ErrorResponseDto}),
    );
}

export function ApiGetResponse<T extends Type<any>> (dataModel: T, summary: string) {
    return applyDecorators(
        ApiOperation({ summary }),
        ApiOkResponse({ description: '성공', type: dataModel}),
        ApiInternalServerErrorResponse({ description: '서버 에러', type: () => ErrorResponseDto }),
    );
}