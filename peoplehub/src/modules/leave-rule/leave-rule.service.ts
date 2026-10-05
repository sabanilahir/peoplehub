import { Injectable } from '@nestjs/common';
import { LeaveKind, LeaveRule } from '@prisma/client';
import { addMonths, monthsBetween, toDateString } from '../../common/date.util';
import { PrismaService } from '../../prisma/prisma.service';

const MAX_YEARS = 60;

export interface EmployeeRef {
  id: string;
  hireDate: Date | null;
}

export interface Grant {
  anniversary: number;
  date: string;
  days: number;
  expiresAt: string | null;
  expired: boolean;
}

export interface Eligibility {
  eligible: boolean;
  reasons: string[];
  tenureMonths: number | null;
  eligibleFrom: string | null;
  minTenureMonths: number;
}

export interface Balance {
  asOf: string;
  grants: Grant[];
  grantedActive: number;
  used: number;
  remaining: number;
  nextAnniversary: { date: string; days: number | null } | null;
}

const tenureLabel = (months: number) => {
  const y = Math.floor(months / 12);
  const m = months % 12;
  return [y ? `${y} tahun` : '', m ? `${m} bulan` : ''].filter(Boolean).join(' ') || '0 bulan';
};

@Injectable()
export class LeaveRuleService {
  constructor(private readonly prisma: PrismaService) {}

  /** Aturan yang berlaku pada tanggal tertentu untuk satu jenis cuti (null bila belum ada). */
  ruleOn(kind: LeaveKind, date: Date) {
    return this.prisma.leaveRule.findFirst({
      where: { leaveKind: kind, effectiveFrom: { lte: date }, OR: [{ effectiveTo: null }, { effectiveTo: { gte: date } }] },
      orderBy: { effectiveFrom: 'desc' },
    });
  }

  /**
   * Validasi pengajuan: masa kerja pada tanggal mulai cuti harus memenuhi minimum aturan.
   * Tanpa aturan atau minimum 0 bulan, selalu layak.
   */
  async checkEligibility(emp: EmployeeRef, kind: LeaveKind, startDate: Date): Promise<Eligibility> {
    const rule = await this.ruleOn(kind, startDate);
    const min = rule?.minTenureMonths ?? 0;
    const tenure = emp.hireDate ? monthsBetween(emp.hireDate, startDate) : null;

    if (min === 0) return { eligible: true, reasons: [], tenureMonths: tenure, eligibleFrom: null, minTenureMonths: 0 };

    if (!emp.hireDate) {
      return {
        eligible: false,
        reasons: [`Tanggal mulai kerja karyawan belum diisi, sehingga masa kerja (minimum ${tenureLabel(min)}) tidak dapat divalidasi.`],
        tenureMonths: null,
        eligibleFrom: null,
        minTenureMonths: min,
      };
    }

    const eligibleFrom = addMonths(emp.hireDate, min);
    if ((tenure ?? 0) < min) {
      return {
        eligible: false,
        reasons: [
          `Masa kerja ${tenureLabel(tenure ?? 0)} pada ${toDateString(startDate)} belum memenuhi minimum ${tenureLabel(min)}. Baru dapat mengajukan cuti ini mulai ${toDateString(eligibleFrom)}.`,
        ],
        tenureMonths: tenure,
        eligibleFrom: toDateString(eligibleFrom),
        minTenureMonths: min,
      };
    }
    return { eligible: true, reasons: [], tenureMonths: tenure, eligibleFrom: toDateString(eligibleFrom), minTenureMonths: min };
  }

  /**
   * Saldo pada tanggal `asOf`. Saldo baru dibentuk di setiap anniversary masa kerja memakai aturan yang berlaku
   * PADA tanggal anniversary itu. Pemakaian dihitung dari cuti disetujui sejak saldo aktif tertua.
   * ASSUMPTION: pemakaian dikurangkan dari total saldo aktif (bukan per-pemberian/FIFO).
   */
  async balance(emp: EmployeeRef, kind: LeaveKind, asOf: Date): Promise<Balance> {
    const empty: Balance = { asOf: toDateString(asOf), grants: [], grantedActive: 0, used: 0, remaining: 0, nextAnniversary: null };
    if (!emp.hireDate) return empty;

    const rules = await this.prisma.leaveRule.findMany({ where: { leaveKind: kind }, orderBy: { effectiveFrom: 'asc' } });
    const ruleAt = (d: Date): LeaveRule | undefined =>
      [...rules].reverse().find((r) => r.effectiveFrom <= d && (!r.effectiveTo || r.effectiveTo >= d));

    const grants: Grant[] = [];
    let nextAnniversary: Balance['nextAnniversary'] = null;
    for (let k = 1; k <= MAX_YEARS; k++) {
      const date = addMonths(emp.hireDate, 12 * k);
      const rule = ruleAt(date);
      const grants_ = rule?.accrualMode === 'ANNIVERSARY' && k >= rule.firstGrantAnniversary && Number(rule.entitlementDays) > 0;
      if (date > asOf) {
        nextAnniversary = { date: toDateString(date), days: grants_ ? Number(rule!.entitlementDays) : null };
        break;
      }
      if (!grants_) continue;
      const expires = rule!.expiryMonths ? addMonths(date, rule!.expiryMonths) : null;
      grants.push({
        anniversary: k,
        date: toDateString(date),
        days: Number(rule!.entitlementDays),
        expiresAt: expires ? toDateString(expires) : null,
        expired: !!expires && asOf >= expires,
      });
    }

    const active = grants.filter((g) => !g.expired);
    const grantedActive = active.reduce((s, g) => s + g.days, 0);
    let used = 0;
    if (active.length > 0) {
      const since = new Date(`${active[0].date}T00:00:00Z`);
      const leaves = await this.prisma.leaveRequest.findMany({
        where: { odooEmployeeId: emp.id, kind, overallStatus: 'APPROVED', startDate: { gte: since } },
        select: { days: true },
      });
      used = leaves.reduce((s, l) => s + Number(l.days), 0);
    }

    return {
      asOf: toDateString(asOf),
      grants,
      grantedActive,
      used,
      remaining: Math.round((grantedActive - used) * 100) / 100,
      nextAnniversary,
    };
  }
}
