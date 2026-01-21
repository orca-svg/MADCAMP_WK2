import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

type EmbedResponse = {
  embeddings?: number[][];
};

@Injectable()
export class EmbeddingService {
  private readonly logger = new Logger(EmbeddingService.name);
  private readonly baseUrl: string;
  private readonly timeoutMs: number;

  constructor(private readonly config: ConfigService) {
    const rawUrl = this.config.get<string>('EMBEDDING_SERVICE_URL') ?? '';
    this.baseUrl = rawUrl.replace(/\/+$/, '');
    this.timeoutMs = Number(this.config.get<string>('EMBEDDING_TIMEOUT_MS') ?? 8000);
  }

  async embedOne(text: string): Promise<number[]> {
    const embeddings = await this.embedMany([text]);
    return embeddings[0];
  }

  async embedMany(texts: string[]): Promise<number[][]> {
    if (!this.baseUrl) {
      throw new ServiceUnavailableException('Embedding service URL is not set');
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs);

    try {
      const res = await fetch(`${this.baseUrl}/embed`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ texts }),
        signal: controller.signal,
      });

      if (!res.ok) {
        const body = await res.text();
        throw new ServiceUnavailableException(
          `Embedding service error: ${res.status} ${body}`,
        );
      }

      const payload = (await res.json()) as EmbedResponse;
      if (!payload.embeddings || payload.embeddings.length === 0) {
        throw new ServiceUnavailableException('Embedding service returned no vectors');
      }

      return payload.embeddings;
    } catch (error) {
      if (error instanceof ServiceUnavailableException) {
        throw error;
      }

      if (error instanceof Error && error.name === 'AbortError') {
        throw new ServiceUnavailableException('Embedding service request timed out');
      }

      this.logger.error('Embedding service request failed', error as Error);
      throw new ServiceUnavailableException('Embedding service request failed');
    } finally {
      clearTimeout(timeout);
    }
  }
}
