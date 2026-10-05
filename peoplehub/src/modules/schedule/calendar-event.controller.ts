import { BadRequestException, Body, Controller, Delete, Get, NotFoundException, Param, Post, Query } from '@nestjs/common';
import { RequirePermission } from '../../common/decorators/require-permission.decorator';
import { parseDate } from '../../common/date.util';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateCalendarEventDto, ListCalendarQuery } from './schedule.dto';

@Controller('calendar-events')
export class CalendarEventController {
  constructor(private readonly prisma: PrismaService) {}

  /** Event yang beririsan dengan rentang tanggal; event GLOBAL selalu ikut. */
  @Get()
  @RequirePermission('schedule.calendar.read')
  list(@Query() q: ListCalendarQuery) {
    return this.prisma.calendarEvent.findMany({
      where: {
        startDate: { lte: parseDate(q.to) },
        endDate: { gte: parseDate(q.from) },
        ...(q.workLocationId && { OR: [{ scope: 'GLOBAL' }, { workLocationId: q.workLocationId }] }),
      },
      include: { workLocation: { select: { id: true, name: true } } },
      orderBy: { startDate: 'asc' },
    });
  }

  @Post()
  @RequirePermission('schedule.calendar.edit')
  async create(@Body() dto: CreateCalendarEventDto) {
    const start = parseDate(dto.startDate);
    const end = parseDate(dto.endDate);
    if (end < start) throw new BadRequestException('endDate tidak boleh sebelum startDate');
    if (dto.scope === 'LOCATION' && !dto.workLocationId) throw new BadRequestException('scope LOCATION wajib workLocationId');
    if (dto.scope === 'EMPLOYEE' && !dto.odooEmployeeId) throw new BadRequestException('scope EMPLOYEE wajib odooEmployeeId');
    if (dto.scope === 'GLOBAL' && (dto.workLocationId || dto.odooEmployeeId)) {
      throw new BadRequestException('scope GLOBAL tidak boleh menyertakan lokasi/karyawan');
    }
    return this.prisma.calendarEvent.create({ data: { ...dto, startDate: start, endDate: end } });
  }

  @Delete(':id')
  @RequirePermission('schedule.calendar.edit')
  async remove(@Param('id') id: string) {
    const row = await this.prisma.calendarEvent.findUnique({ where: { id } });
    if (!row) throw new NotFoundException();
    await this.prisma.calendarEvent.delete({ where: { id } });
    return { deleted: true };
  }
}
