import { Body, Controller, Delete, Get, NotFoundException, Param, Post, Put, Query } from '@nestjs/common';
import { RequirePermission } from '../../common/decorators/require-permission.decorator';
import { parseDate } from '../../common/date.util';
import { PrismaService } from '../../prisma/prisma.service';
import { BulkScheduleDto, ListScheduleQuery, UpsertScheduleDto } from './schedule.dto';
import { ScheduleService } from './schedule.service';

@Controller('schedules')
export class ScheduleController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly service: ScheduleService,
  ) {}

  @Get()
  @RequirePermission('schedule.roster.read')
  list(@Query() q: ListScheduleQuery) {
    return this.prisma.employeeSchedule.findMany({
      where: {
        workDate: { gte: parseDate(q.from), lte: parseDate(q.to) },
        ...(q.odooEmployeeId && { odooEmployeeId: q.odooEmployeeId }),
        ...(q.workLocationId && { employee: { workLocationId: q.workLocationId } }),
      },
      include: { shift: { select: { code: true, name: true } } },
      orderBy: [{ workDate: 'asc' }, { odooEmployeeId: 'asc' }],
      take: 5000,
    });
  }

  @Put()
  @RequirePermission('schedule.roster.edit')
  upsert(@Body() dto: UpsertScheduleDto) {
    return this.service.upsert(dto);
  }

  /** Bulk: baris yang gagal dilaporkan per item, tidak menggagalkan seluruh request. */
  @Post('bulk')
  @RequirePermission('schedule.roster.edit')
  async bulk(@Body() dto: BulkScheduleDto) {
    const errors: { index: number; message: string }[] = [];
    let ok = 0;
    for (const [index, item] of dto.items.entries()) {
      try {
        await this.service.upsert(item);
        ok++;
      } catch (e) {
        errors.push({ index, message: e instanceof Error ? e.message : String(e) });
      }
    }
    return { total: dto.items.length, success: ok, failed: errors.length, errors };
  }

  @Delete(':id')
  @RequirePermission('schedule.roster.edit')
  async remove(@Param('id') id: string) {
    const row = await this.prisma.employeeSchedule.findUnique({ where: { id } });
    if (!row) throw new NotFoundException();
    await this.prisma.employeeSchedule.delete({ where: { id } });
    return { deleted: true };
  }
}
