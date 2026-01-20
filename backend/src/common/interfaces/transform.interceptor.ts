import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { Observable } from "rxjs";
import { map } from "rxjs/operators";
import { ApiResponse } from "../interfaces/api-response.interface";
import { RESPONSE_MESSAGE_KEY } from "../decorators/response-message.decorator";

@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<T, ApiResponse<T>> {
    constructor(private reflector: Reflector) {}

    intercept(context: ExecutionContext, next: CallHandler): Observable<ApiResponse<T>> {
        return next.handle().pipe(
            map(data => {
                const message = this.reflector.get<string>(
                    RESPONSE_MESSAGE_KEY,
                    context.getHandler(),
                ) || 'Request successful';

                return {
                    success: true,
                    message: message,
                    data: data,
                } 
            }),
        );
    }
}