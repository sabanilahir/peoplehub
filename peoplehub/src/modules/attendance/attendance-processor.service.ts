import { Injectable } from '@nestjs/common';
import { addDays, parseDate, toDateString } from '../../common/date.util';
import { PrismaService } from '../../prisma/prisma.service';
import { assignPunch, evaluateDay, ScheduleSlot } from './attendance-engine';

const DEFAULT_PRE = 240;
const DEFAULT_POST = 360;

/**
 * Mengolah punch mentah -> AttendanceLog (assignment ke workDate) -> AttendanceDaily.
 * Idempoten: aman dijalankan ulang untuk rentang yang sama (mis. setelah jadwal/cuti berubah).
 * ASSUMPTION: dijalankan sinkron (tanpa antrean).
 */
@Injectable()
export class AttendanceProcessorService {
  constructor(private readonly prisma: PrismaService) {}

  /** Hitung ulang satu karyawan untuk workDate dari..sampai (inklusif, 'YYYY-MM-DD'). */
  async recompute(odooEmployeeId: string, from: string, to: string, now = new Date()) {
    const employee = await this.prisma.odooEmployee.findUnique({
      where: { id: odooEmployeeId },
      include: { workLocation: true },
    });
    if (!employee) return { days: 0 };
    const tz = employee.workLocation.timezone;
    const fromD = parseDate(from);
    const toD = parseDate(to);

    // Ambil sedikit lebih lebar: shift lintas hari bisa menarik punch dari hari tetangga
    const [schedules, rules, leaves, events] = await Promise.all([
      this.prisma.employeeSchedule.findMany({
        where: { odooEmployeeId, workDate: { gte: addDays(fromD, -1), lte: addDays(toD, 1) } },
      }),
      this.prisma.attendanceRule.findMany({
        where: {
          workLocationId: employee.workLocationId,
          effectiveFrom: { lte: toD },
          OR: [{ effectiveTo: null }, { effectiveTo: { gte: fromD } }],
        },
      }),
      this.prisma.leaveRequest.findMany({
        where: { odooEmployeeId, overallStatus: 'APPROVED', startDate: { lte: toD }, endDate: { gte: fromD } },
      }),
      this.prisma.calendarEvent.findMany({
        where: {
          cancelsWorkday: true,
          startDate: { lte: toD },
          endDate: { gte: fromD },
          OR: [
            { scope: 'GLOBAL' },
            { scope: 'LOCATION', workLocationId: employee.workLocationId },
            { scope: 'EMPLOYEE', odooEmployeeId },
          ],
        },
      }),
    ]);

    const ruleFor = (date: string) => {
      const d = parseDate(date);
      return rules.find((r) => r.effectiveFrom <= d && (!r.effectiveTo || r.effectiveTo >= d));
    };

    const slots: ScheduleSlot[] = schedules.map((s) => {
      const date = toDateString(s.workDate);
      const rule = ruleFor(date);
      return {
        workDate: date,
        dayType: s.dayType,
        shiftStart: s.shiftStart,
        shiftEnd: s.shiftEnd,
        preShiftWindowMinutes: rule?.preShiftWindowMinutes ?? DEFAULT_PRE,
        postShiftWindowMinutes: rule?.postShiftWindowMinutes ?? DEFAULT_POST,
      };
    });

    const punches = await this.prisma.attendanceRawPunch.findMany({
      where: { odooEmployeeId, punchAt: { gte: addDays(fromD, -2), lte: addDays(toD, 3) } },
      orderBy: { punchAt: 'asc' },
    });

    // 1) Assign tiap punch ke workDate; simpan sebagai AttendanceLog
    const byDate = new Map<string, Date[]>();
    for (const p of punches) {
      const { workDate, matchedShift } = assignPunch(p.punchAt, slots, tz);
      if (workDate < from || workDate > to) continue; // milik rentang lain
      const list = byDate.get(workDate) ?? [];
      list.push(p.punchAt);
      byDate.set(workDate, list);

      const data = {
        odooEmployeeId,
        workDate: parseDate(workDate),
        direction: p.direction,
        punchAt: p.punchAt,
        isValid: true,
        invalidReason: matchedShift ? null : 'NO_MATCHING_SHIFT',
      };
      await this.prisma.attendanceLog.upsert({
        where: { rawPunchId: p.id },
        update: data,
        create: { rawPunchId: p.id, ...data },
      });
    }

    // 2) Evaluasi tiap hari yang punya jadwal atau punch dalam rentang
    const dates = new Set<string>(byDate.keys());
    for (const s of slots) if (s.workDate >= from && s.workDate <= to) dates.add(s.workDate);

    let written = 0;
    for (const date of [...dates].sort()) {
      const d = parseDate(date);
      const evaluation = evaluateDay({
        slot: slots.find((s) => s.workDate === date),
        punches: byDate.get(date) ?? [],
        onLeave: leaves.some((l) => l.startDate <= d && l.endDate >= d),
        holiday: events.some((e) => e.startDate <= d && e.endDate >= d),
        graceMinutes: ruleFor(date)?.gracePeriodMinutes ?? 0,
        now,
      });
      if (!evaluation) continue;

      const data = { ...evaluation, appliedRuleId: ruleFor(date)?.id ?? null, computedAt: now };
      await this.prisma.attendanceDaily.upsert({
        where: { odooEmployeeId_workDate: { odooEmployeeId, workDate: d } },
        update: data,
        create: { odooEmployeeId, workDate: d, ...data },
      });
      written++;
    }
    return { days: written };
  }

  /** Hitung ulang banyak karyawan (semua yang punya jadwal/punch dalam rentang). */
  async recomputeRange(from: string, to: string, filter: { workLocationId?: string; odooEmployeeId?: string } = {}) {
    const fromD = parseDate(from);
    const toD = parseDate(to);
    const employeeFilter = {
      ...(filter.odooEmployeeId && { id: filter.odooEmployeeId }),
      ...(filter.workLocationId && { workLocationId: filter.workLocationId }),
      isActive: true,
    };
    const employees = await this.prisma.odooEmployee.findMany({
      where: {
        ...employeeFilter,
        OR: [
          { schedules: { some: { workDate: { gte: fromD, lte: toD } } } },
          { rawPunches: { some: { punchAt: { gte: addDays(fromD, -1), lte: addDays(toD, 2) } } } },
        ],
      },
      select: { id: true },
    });

    let days = 0;
    for (const e of employees) days += (await this.recompute(e.id, from, to)).days;
    return { employees: employees.length, days };
  }
}
