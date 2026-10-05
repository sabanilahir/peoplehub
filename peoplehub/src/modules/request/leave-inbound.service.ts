import { Injectable } from '@nestjs/common';
import { DataSource } from '@prisma/client';
import { parseDate } from '../../common/date.util';
import { PrismaService } from '../../prisma/prisma.service';
import { LeaveRuleService } from '../leave-rule/leave-rule.service';
import { InboundLeaveItemDto } from './leave-inbound.dto';

export interface InboundResult {
  total: number;
  created: number;
  updated: number;
  failed: number;
  errors: { index: number; externalRef?: string; message: string }[];
}

/**
 * Jalur masuk cuti dari sistem asal (Odoo / file). Approval terjadi di sistem asal,
 * jadi cuti masuk dengan status final (default APPROVED). Idempoten lewat externalRef:
 * kiriman ulang memperbarui baris yang sama.
 * Dipakai oleh endpoint inbound, parser file, dan sync Odoo.
 */
@Injectable()
export class LeaveInboundService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly rules: LeaveRuleService,
  ) {}

  async upsertMany(items: InboundLeaveItemDto[], source: DataSource, importBatchId?: string): Promise<InboundResult> {
    const result: InboundResult = { total: items.length, created: 0, updated: 0, failed: 0, errors: [] };

    for (const [index, item] of items.entries()) {
      try {
        const outcome = await this.upsertOne(item, source, importBatchId);
        result[outcome]++;
      } catch (e) {
        result.failed++;
        result.errors.push({ index, externalRef: item.externalRef, message: e instanceof Error ? e.message : String(e) });
      }
    }
    return result;
  }

  private async upsertOne(item: InboundLeaveItemDto, source: DataSource, importBatchId?: string) {
    const employee = await this.findEmployee(item);
    const start = parseDate(item.startDate);
    const end = parseDate(item.endDate);
    if (end < start) throw new Error('endDate sebelum startDate');

    // Aturan cuti: cuti aktif (disetujui/menunggu) harus memenuhi syarat masa kerja pada tanggal mulai
    const status = item.status ?? 'APPROVED';
    const kind = item.kind ?? 'ANNUAL';
    if (status === 'APPROVED' || status === 'PENDING') {
      const eligibility = await this.rules.checkEligibility(employee, kind, start);
      if (!eligibility.eligible) throw new Error(eligibility.reasons[0]);
    }

    const calendarDays = Math.round((end.getTime() - start.getTime()) / 86_400_000) + 1;
    const data = {
      odooEmployeeId: employee.id,
      kind,
      odooLeaveTypeId: item.odooLeaveTypeId ?? null,
      startDate: start,
      endDate: end,
      days: item.days ?? calendarDays,
      reason: item.reason ?? null,
      source,
      overallStatus: status,
      importBatchId: importBatchId ?? null,
    };

    const existing = await this.prisma.leaveRequest.findUnique({ where: { externalRef: item.externalRef } });
    if (existing) {
      await this.prisma.leaveRequest.update({ where: { id: existing.id }, data });
      return 'updated' as const;
    }
    await this.prisma.leaveRequest.create({ data: { externalRef: item.externalRef, ...data } });
    return 'created' as const;
  }

  private async findEmployee(item: InboundLeaveItemDto) {
    if (item.odooId === undefined && !item.nik) throw new Error('odooId atau nik wajib diisi');
    const employee =
      item.odooId !== undefined
        ? await this.prisma.odooEmployee.findUnique({ where: { odooId: item.odooId } })
        : await this.prisma.odooEmployee.findUnique({ where: { nik: item.nik! } });
    if (!employee) throw new Error(`Karyawan tidak ditemukan (${item.odooId !== undefined ? `odooId ${item.odooId}` : `nik ${item.nik}`})`);
    return employee;
  }
}
