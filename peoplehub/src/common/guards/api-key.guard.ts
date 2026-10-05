import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, timingSafeEqual } from 'crypto';

/** Autentikasi mesin/sistem eksternal lewat header `x-api-key` (dipakai bersama @Public()). */
@Injectable()
export class PunchApiKeyGuard implements CanActivate {
  constructor(private readonly config: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const expected = this.config.get<string>('PUNCH_API_KEY');
    if (!expected) throw new UnauthorizedException('PUNCH_API_KEY belum dikonfigurasi di server');

    const given = context.switchToHttp().getRequest().headers['x-api-key'];
    if (typeof given !== 'string') throw new UnauthorizedException();

    // Hash dulu agar panjang sama dan perbandingan konstan-waktu
    const a = createHash('sha256').update(given).digest();
    const b = createHash('sha256').update(expected).digest();
    if (!timingSafeEqual(a, b)) throw new UnauthorizedException();
    return true;
  }
}
