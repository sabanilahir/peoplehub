import { BadRequestException, Body, Controller, Get, NotFoundException, Param, Post, Query } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermission } from '../../common/decorators/require-permission.decorator';
import { addDays, parseDate } from '../../common/date.util';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateAttendanceRuleDto } from './attendance-rule.dto';

@Controller('attendance-rules')
export class AttendanceRuleController {
  constructor(private readonly prisma: PrismaService) {}

  /** Riwayat versi rule, terbaru dulu. */
  @Get()
  @RequirePermission('config.attendance.read')
  list(@Query('workLocationId') workLocationId?: string) {
    return this.prisma.attendanceRule.findMany({
      where: workLocationId ? { workLocationId } : {},
      orderBy: [{ workLocationId: 'asc' }, { effectiveFrom: 'desc' }],
    });
  }

  /** Rule yang berlaku pada tanggal tertentu (default hari ini). */
  @Get('active')
  @RequirePermission('config.attendance.read')
  async active(@Query('workLocationId') workLocationId: string, @Query('date') date?: string) {
    const d = date ? parseDate(date) : parseDate(new Date().toISOString());
    const rule = await this.prisma.attendanceRule.findFirst({
      where: {
        workLocationId,
        effectiveFrom: { lte: d },
        OR: [{ effectiveTo: null }, { effectiveTo: { gte: d } }],
      },
      orderBy: { effectiveFrom: 'desc' },
    });
    if (!rule) throw new NotFoundException('Tidak ada rule aktif pada tanggal tersebut');
    return rule;
  }

  @Get(':id')
  @RequirePermission('config.attendance.read')
  async get(@Param('id') id: string) {
    const rule = await this.prisma.attendanceRule.findUnique({ where: { id } });
    if (!rule) throw new NotFoundException();
    return rule;
  }

  /** Perubahan rule = versi baru. Versi sebelumnya otomatis ditutup sehari sebelum effectiveFrom. */
  @Post()
  @RequirePermission('config.attendance.edit')
  async createVersion(@Body() dto: CreateAttendanceRuleDto, @CurrentUser() user: AuthUser) {
    const from = parseDate(dto.effectiveFrom);

    return this.prisma.$transaction(async (tx) => {
      const latest = await tx.attendanceRule.findFirst({
        where: { workLocationId: dto.workLocationId },
        orderBy: { effectiveFrom: 'desc' },
      });
      if (latest && latest.effectiveFrom >= from) {
        throw new BadRequestException('effectiveFrom harus setelah versi terakhir yang ada');
      }
      if (latest) {
        await tx.attendanceRule.update({ where: { id: latest.id }, data: { effectiveTo: addDays(from, -1) } });
      }
      const created = await tx.attendanceRule.create({
        data: { ...dto, effectiveFrom: from, updatedBy: user.id },
      });
      await tx.auditLog.create({
        data: {
          actorId: user.id,
          action: 'ATTENDANCE_RULE_VERSION_CREATED',
          entityType: 'AttendanceRule',
          entityId: created.id,
          beforeJson: latest ? (latest as unknown as Prisma.InputJsonValue) : undefined,
          afterJson: created as unknown as Prisma.InputJsonValue,
        },
      });
      return created;
    });
  }
}
