import { Body, Controller, Get, HttpCode, Param, Post, Query, Res } from '@nestjs/common';
import { Type } from 'class-transformer';
import { IsDateString, IsIn, IsInt, IsOptional, IsString, Matches, Max, MaxLength, Min } from 'class-validator';
import type { Response } from 'express';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermission } from '../../common/decorators/require-permission.decorator';
import { TimeEntryService } from './time-entry.service';

const PERIOD = /^\d{4}-(0[1-9]|1[0-2])$/;

class UploadDto {
  @IsString() @MaxLength(200) fileName: string;
  /** Isi file CSV sebagai teks (UTF-8). */
  @IsString() content: string;
}

class ListQuery {
  @IsOptional() @Matches(PERIOD, { message: 'payrollPeriod harus berformat YYYY-MM' }) payrollPeriod?: string;
  @IsOptional() @IsString() workLocationId?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(200) pageSize?: number;
}

class ExportQuery {
  @IsOptional() @IsIn(['attendance', 'imported']) source?: 'attendance' | 'imported';
  @IsOptional() @Matches(PERIOD, { message: 'payrollPeriod harus berformat YYYY-MM' }) payrollPeriod?: string;
  @IsOptional() @IsDateString() from?: string;
  @IsOptional() @IsDateString() to?: string;
  @IsOptional() @IsString() workLocationId?: string;
}

@Controller()
export class TimeEntryController {
  constructor(private readonly service: TimeEntryService) {}

  /**
   * Unggah CSV time entries. Kesalahan format file (header/kosong/terlalu besar) langsung 400.
   * Selebihnya diproses di latar belakang (202): pantau status dan log di Process Monitor.
   */
  @Post('inbound/time-entries')
  @HttpCode(202)
  @RequirePermission('inbound.time.create')
  upload(@Body() dto: UploadDto, @CurrentUser() user: AuthUser) {
    return this.service.startImport(dto.content, dto.fileName, user.id);
  }

  @Get('time-entries')
  @RequirePermission('time.entry.read')
  list(@Query() q: ListQuery) {
    return this.service.list(q);
  }

  @Get('time-entries/template')
  @RequirePermission('time.entry.read')
  template(@Res({ passthrough: true }) res: Response) {
    res.set({
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': 'attachment; filename="time-entries-template.csv"',
    });
    return this.service.template();
  }

  /** Unduh CSV. source=attendance (default) dari absensi PeopleHub, source=imported dari hasil unggahan. */
  @Get('time-entries/export')
  @RequirePermission('time.entry.read')
  async export(@Query() q: ExportQuery, @Res({ passthrough: true }) res: Response) {
    const out = await this.service.exportCsv({ ...q, source: q.source ?? 'attendance' });
    res.set({
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="${out.filename}"`,
      'X-Exported-Rows': String(out.rows),
    });
    return out.csv;
  }

}
