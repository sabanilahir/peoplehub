import { BadRequestException, Body, Controller, Get, NotFoundException, Post, Query } from '@nestjs/common';
import { AccrualMode, LeaveKind, Prisma } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsDateString, IsEnum, IsInt, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermission } from '../../common/decorators/require-permission.decorator';
import { addDays, parseDate, toDateString } from '../../common/date.util';
import { PrismaService } from '../../prisma/prisma.service';
import { LeaveRuleService } from './leave-rule.service';

class CreateLeaveRuleDto {
  @IsEnum(LeaveKind) leaveKind: LeaveKind;
  @IsDateString() effectiveFrom: string;
  /** Minimal masa kerja (bulan) untuk boleh mengambil jenis cuti ini. 0 = tanpa syarat. */
  @IsInt() @Min(0) @Max(240) minTenureMonths: number;
  @IsEnum(AccrualMode) accrualMode: AccrualMode;
  @IsOptional() @IsNumber({ maxDecimalPlaces: 2 }) @Min(0.5) @Max(365) entitlementDays?: number;
  @IsOptional() @IsInt() @Min(1) @Max(50) firstGrantAnniversary?: number;
  @IsOptional() @IsInt() @Min(1) @Max(120) expiryMonths?: number;
}

class KindQuery {
  @IsOptional() @IsEnum(LeaveKind) leaveKind?: LeaveKind;
  @IsOptional() @IsDateString() date?: string;
}

class CheckQuery {
  @IsString() employeeId: string;
  @IsEnum(LeaveKind) leaveKind: LeaveKind;
  @IsOptional() @IsDateString() startDate?: string;
  @IsOptional() @Type(() => String) @IsDateString() asOf?: string;
}

@Controller('leave-rules')
export class LeaveRuleController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly service: LeaveRuleService,
  ) {}

  /** Riwayat versi aturan, terbaru dulu. */
  @Get()
  @RequirePermission('leave.rule.read')
  list(@Query() q: KindQuery) {
    return this.prisma.leaveRule.findMany({
      where: q.leaveKind ? { leaveKind: q.leaveKind } : {},
      orderBy: [{ leaveKind: 'asc' }, { effectiveFrom: 'desc' }],
    });
  }

  @Get('active')
  @RequirePermission('leave.rule.read')
  async active(@Query() q: KindQuery) {
    if (!q.leaveKind) throw new BadRequestException('leaveKind wajib diisi.');
    const rule = await this.service.ruleOn(q.leaveKind, parseDate(q.date ?? new Date().toISOString()));
    if (!rule) throw new NotFoundException('Belum ada aturan untuk jenis cuti ini.');
    return rule;
  }

  /**
   * Cek kelayakan dan saldo seorang karyawan untuk satu jenis cuti.
   * Dipakai halaman Aturan Cuti dan bisa dipanggil sistem lain (mis. Odoo) sebelum cuti diajukan.
   */
  @Get('check')
  @RequirePermission('leave.rule.read')
  async check(@Query() q: CheckQuery) {
    const emp = await this.prisma.odooEmployee.findUnique({
      where: { id: q.employeeId },
      select: { id: true, name: true, nik: true, hireDate: true },
    });
    if (!emp) throw new NotFoundException('Karyawan tidak ditemukan.');

    const startDate = parseDate(q.startDate ?? new Date().toISOString());
    const asOf = parseDate(q.asOf ?? q.startDate ?? new Date().toISOString());
    const [eligibility, balance, rule] = await Promise.all([
      this.service.checkEligibility(emp, q.leaveKind, startDate),
      this.service.balance(emp, q.leaveKind, asOf),
      this.service.ruleOn(q.leaveKind, startDate),
    ]);
    return {
      employee: { id: emp.id, name: emp.name, nik: emp.nik, hireDate: emp.hireDate ? toDateString(emp.hireDate) : null },
      leaveKind: q.leaveKind,
      startDate: toDateString(startDate),
      rule,
      ...eligibility,
      balance,
    };
  }

  /** Perubahan aturan = versi baru. Versi sebelumnya ditutup sehari sebelum effectiveFrom. */
  @Post()
  @RequirePermission('leave.rule.edit')
  async createVersion(@Body() dto: CreateLeaveRuleDto, @CurrentUser() user: AuthUser) {
    const from = parseDate(dto.effectiveFrom);
    const anniversary = dto.accrualMode === 'ANNIVERSARY';
    if (anniversary && !dto.entitlementDays) {
      throw new BadRequestException('Jatah saldo (hari) wajib diisi bila saldo diberikan setiap anniversary.');
    }

    return this.prisma.$transaction(async (tx) => {
      const latest = await tx.leaveRule.findFirst({ where: { leaveKind: dto.leaveKind }, orderBy: { effectiveFrom: 'desc' } });
      if (latest && latest.effectiveFrom >= from) {
        throw new BadRequestException('effectiveFrom harus setelah versi terakhir yang ada.');
      }
      if (latest) await tx.leaveRule.update({ where: { id: latest.id }, data: { effectiveTo: addDays(from, -1) } });

      const created = await tx.leaveRule.create({
        data: {
          leaveKind: dto.leaveKind,
          effectiveFrom: from,
          minTenureMonths: dto.minTenureMonths,
          accrualMode: dto.accrualMode,
          entitlementDays: anniversary ? dto.entitlementDays : null,
          firstGrantAnniversary: anniversary ? (dto.firstGrantAnniversary ?? 1) : 1,
          expiryMonths: anniversary ? (dto.expiryMonths ?? null) : null,
          updatedBy: user.id,
        },
      });
      await tx.auditLog.create({
        data: {
          actorId: user.id,
          action: 'LEAVE_RULE_VERSION_CREATED',
          entityType: 'LeaveRule',
          entityId: created.id,
          beforeJson: latest ? (latest as unknown as Prisma.InputJsonValue) : undefined,
          afterJson: created as unknown as Prisma.InputJsonValue,
        },
      });
      return created;
    });
  }
}
