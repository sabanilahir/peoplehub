import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { AttendanceStatus } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsDateString, IsEnum, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { RequirePermission } from '../../common/decorators/require-permission.decorator';
import { parseDate } from '../../common/date.util';
import { PrismaService } from '../../prisma/prisma.service';
import { AttendanceProcessorService } from './attendance-processor.service';

class DailyQuery {
  @IsDateString() from: string;
  @IsDateString() to: string;
  @IsOptional() @IsString() odooEmployeeId?: string;
  @IsOptional() @IsString() workLocationId?: string;
  @IsOptional() @IsEnum(AttendanceStatus) status?: AttendanceStatus;
  @IsOptional() @Transform(({ value }) => value === 'true' || value === true) @IsBoolean() onlyLate?: boolean;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(500) pageSize?: number;
}

class RecomputeDto {
  @IsDateString() from: string;
  @IsDateString() to: string;
  @IsOptional() @IsString() workLocationId?: string;
  @IsOptional() @IsString() odooEmployeeId?: string;
}

@Controller('attendance')
export class AttendanceDailyController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly processor: AttendanceProcessorService,
  ) {}

  /** Rekap harian, termasuk keterlambatan (lateMinutes) per karyawan. */
  @Get('daily')
  @RequirePermission('attendance.log.read')
  async daily(@Query() q: DailyQuery) {
    const page = q.page ?? 1;
    const pageSize = q.pageSize ?? 100;
    const where = {
      workDate: { gte: parseDate(q.from), lte: parseDate(q.to) },
      ...(q.odooEmployeeId && { odooEmployeeId: q.odooEmployeeId }),
      ...(q.workLocationId && { employee: { workLocationId: q.workLocationId } }),
      ...(q.status && { status: q.status }),
      ...(q.onlyLate && { isLate: true }),
    };
    const [items, total] = await Promise.all([
      this.prisma.attendanceDaily.findMany({
        where,
        include: {
          employee: {
            select: { id: true, name: true, nik: true, workLocation: { select: { id: true, name: true, timezone: true } } },
          },
        },
        orderBy: [{ workDate: 'desc' }, { odooEmployeeId: 'asc' }],
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.attendanceDaily.count({ where }),
    ]);
    return { items, total, page, pageSize };
  }

  /** Hitung ulang absensi harian (mis. setelah jadwal, cuti, atau rule berubah; juga untuk mendeteksi ABSENT). */
  @Post('recompute')
  @RequirePermission('attendance.log.edit')
  recompute(@Body() dto: RecomputeDto) {
    return this.processor.recomputeRange(dto.from, dto.to, {
      workLocationId: dto.workLocationId,
      odooEmployeeId: dto.odooEmployeeId,
    });
  }
}
