import { BadRequestException, Body, Controller, Get, NotFoundException, Param, Post, Query } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermission } from '../../common/decorators/require-permission.decorator';
import { addDays, parseDate } from '../../common/date.util';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateOvertimeRuleDto, MultiplierTierDto } from './overtime-rule.dto';

/** Tier jam berurutan tanpa overlap/celah, mulai dari jam ke-1. */
function validateTiers(name: string, tiers: MultiplierTierDto[]) {
  if (tiers.length === 0) throw new BadRequestException(`${name}: minimal satu tier`);
  const sorted = [...tiers].sort((a, b) => a.fromHour - b.fromHour);
  if (sorted[0].fromHour !== 1) throw new BadRequestException(`${name}: tier pertama harus mulai dari jam ke-1`);
  sorted.forEach((t, i) => {
    if (t.toHour < t.fromHour) throw new BadRequestException(`${name}: tier ${i + 1} toHour < fromHour`);
    const next = sorted[i + 1];
    if (next && next.fromHour !== t.toHour + 1) {
      throw new BadRequestException(`${name}: tier ${i + 1} dan ${i + 2} overlap atau ada celah`);
    }
  });
  return sorted;
}

@Controller('overtime-rules')
export class OvertimeRuleController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @RequirePermission('config.overtime.read')
  list(@Query('workLocationId') workLocationId?: string) {
    return this.prisma.overtimeRule.findMany({
      where: workLocationId ? { workLocationId } : {},
      orderBy: [{ workLocationId: 'asc' }, { effectiveFrom: 'desc' }],
    });
  }

  @Get('active')
  @RequirePermission('config.overtime.read')
  async active(@Query('workLocationId') workLocationId: string, @Query('date') date?: string) {
    const d = date ? parseDate(date) : parseDate(new Date().toISOString());
    const rule = await this.prisma.overtimeRule.findFirst({
      where: { workLocationId, effectiveFrom: { lte: d }, OR: [{ effectiveTo: null }, { effectiveTo: { gte: d } }] },
      orderBy: { effectiveFrom: 'desc' },
    });
    if (!rule) throw new NotFoundException('Tidak ada rule lembur aktif pada tanggal tersebut');
    return rule;
  }

  @Get(':id')
  @RequirePermission('config.overtime.read')
  async get(@Param('id') id: string) {
    const rule = await this.prisma.overtimeRule.findUnique({ where: { id } });
    if (!rule) throw new NotFoundException();
    return rule;
  }

  @Post()
  @RequirePermission('config.overtime.edit')
  async createVersion(@Body() dto: CreateOvertimeRuleDto, @CurrentUser() user: AuthUser) {
    const from = parseDate(dto.effectiveFrom);
    const tiers = {
      WORKDAY: validateTiers('WORKDAY', dto.multiplierTiers.WORKDAY),
      OFFDAY_HOLIDAY: validateTiers('OFFDAY_HOLIDAY', dto.multiplierTiers.OFFDAY_HOLIDAY),
    };
    const { multiplierTiers: _ignored, ...rest } = dto;

    return this.prisma.$transaction(async (tx) => {
      const latest = await tx.overtimeRule.findFirst({
        where: { workLocationId: dto.workLocationId },
        orderBy: { effectiveFrom: 'desc' },
      });
      if (latest && latest.effectiveFrom >= from) {
        throw new BadRequestException('effectiveFrom harus setelah versi terakhir yang ada');
      }
      if (latest) {
        await tx.overtimeRule.update({ where: { id: latest.id }, data: { effectiveTo: addDays(from, -1) } });
      }
      const created = await tx.overtimeRule.create({
        data: {
          ...rest,
          effectiveFrom: from,
          multiplierTiersJson: tiers as unknown as Prisma.InputJsonValue,
          excludedJobGrades: dto.excludedJobGrades ?? [],
          updatedBy: user.id,
        },
      });
      await tx.auditLog.create({
        data: {
          actorId: user.id,
          action: 'OVERTIME_RULE_VERSION_CREATED',
          entityType: 'OvertimeRule',
          entityId: created.id,
          beforeJson: latest ? (latest as unknown as Prisma.InputJsonValue) : undefined,
          afterJson: created as unknown as Prisma.InputJsonValue,
        },
      });
      return created;
    });
  }
}
