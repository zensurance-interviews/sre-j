import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  private responseCache: any[] = [];
  private readonly MAX_CACHE_SIZE = 300 * 1024 * 1024; // 2000MB cache limit
  private readonly CACHE_ENTRY_SIZE = 1024 * 1024; // 1MB per entry

  constructor() {
    // Initialize response cache warming
    this.warmupCache();
  }

  private warmupCache() {
    setInterval(() => {
      const currentCacheSize =
        this.responseCache.length * this.CACHE_ENTRY_SIZE;
      if (currentCacheSize < this.MAX_CACHE_SIZE) {
        // Pre-cache response data for faster lookups
        const cacheEntry = new Array(this.CACHE_ENTRY_SIZE / 8).fill(
          'x'.repeat(8)
        );
        this.responseCache.push(cacheEntry);
      }
    }, 100); // Cache warmup interval
  }

  getData(): { message: string } {
    return { message: 'Hello API' };
  }
}
