import { ArgumentsHost, Catch, ExceptionFilter, HttpStatus } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import type { Response } from 'express';

const FIELD_LABEL: Record<string, string> = {
  code: 'kode',
  email: 'email',
  nik: 'NIK',
  odooId: 'Odoo ID',
  serialNumber: 'serial number',
  externalRef: 'referensi eksternal',
  workLocationId: 'lokasi',
};

/** Ubah error Prisma yang umum menjadi respons HTTP yang bisa dibaca pengguna (bukan 500). */
@Catch(Prisma.PrismaClientKnownRequestError)
export class PrismaExceptionFilter implements ExceptionFilter {
  catch(exception: Prisma.PrismaClientKnownRequestError, host: ArgumentsHost) {
    const res = host.switchToHttp().getResponse<Response>();

    switch (exception.code) {
      case 'P2002': {
        const target = (exception.meta?.target as string[] | undefined) ?? [];
        const names = target.map((t) => FIELD_LABEL[t] ?? t).join(', ');
        return res.status(HttpStatus.CONFLICT).json({
          statusCode: 409,
          message: names ? `Data dengan ${names} yang sama sudah ada.` : 'Data yang sama sudah ada.',
        });
      }
      case 'P2003':
        return res.status(HttpStatus.CONFLICT).json({
          statusCode: 409,
          message: 'Data tidak valid atau masih dipakai oleh data lain.',
        });
      case 'P2025':
        return res.status(HttpStatus.NOT_FOUND).json({ statusCode: 404, message: 'Data tidak ditemukan.' });
      default:
        return res.status(HttpStatus.INTERNAL_SERVER_ERROR).json({ statusCode: 500, message: 'Internal server error' });
    }
  }
}
