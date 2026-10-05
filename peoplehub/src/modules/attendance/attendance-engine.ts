import { toLocalDate } from '../../common/date.util';

/**
 * Logika murni absensi (tanpa akses DB) agar mudah diuji dan bisa dipakai ulang oleh simulasi.
 * Semua waktu = instan UTC; tanggal kerja (workDate) = 'YYYY-MM-DD' lokal lokasi.
 */

export interface ScheduleSlot {
  workDate: string;
  dayType: 'WORKDAY' | 'OFFDAY';
  shiftStart: Date | null;
  shiftEnd: Date | null;
  preShiftWindowMinutes: number;
  postShiftWindowMinutes: number;
}

export type DayStatus = 'PRESENT' | 'LATE' | 'ABSENT' | 'ON_LEAVE' | 'OFFDAY' | 'HOLIDAY' | 'INCOMPLETE';

export interface DayEvaluation {
  status: DayStatus;
  clockIn: Date | null;
  clockOut: Date | null;
  isLate: boolean;
  lateMinutes: number;
}

const MIN = 60_000;

function distanceToShift(at: number, start: number, end: number) {
  if (at < start) return start - at;
  if (at > end) return at - end;
  return 0;
}

/**
 * Tentukan punch milik shift (workDate) yang mana, berdasarkan JENDELA WAKTU shift, bukan tanggal kalender.
 * Contoh: shift 15 Okt 16:00-00:00, clock out 16 Okt 00:15 tetap milik 15 Okt.
 * Bila jendela dua shift beririsan, dipilih shift dengan jarak terdekat (seri -> shift yang lebih akhir).
 * Punch di luar semua jendela jatuh ke tanggal kalender lokalnya (matchedShift=false).
 */
export function assignPunch(at: Date, slots: ScheduleSlot[], timeZone: string): { workDate: string; matchedShift: boolean } {
  const t = at.getTime();
  const candidates = slots
    .filter((s) => s.dayType === 'WORKDAY' && s.shiftStart && s.shiftEnd)
    .filter((s) => {
      const from = s.shiftStart!.getTime() - s.preShiftWindowMinutes * MIN;
      const to = s.shiftEnd!.getTime() + s.postShiftWindowMinutes * MIN;
      return t >= from && t <= to;
    })
    .map((s) => ({ s, d: distanceToShift(t, s.shiftStart!.getTime(), s.shiftEnd!.getTime()) }))
    .sort((a, b) => a.d - b.d || b.s.shiftStart!.getTime() - a.s.shiftStart!.getTime());

  if (candidates.length > 0) return { workDate: candidates[0].s.workDate, matchedShift: true };
  return { workDate: toLocalDate(at, timeZone), matchedShift: false };
}

export interface DayContext {
  slot?: ScheduleSlot;
  /** Punch yang sudah ter-assign ke hari ini, urut naik. */
  punches: Date[];
  onLeave: boolean;
  holiday: boolean;
  graceMinutes: number;
  now: Date;
}

/**
 * Evaluasi satu hari kerja. Prioritas (bagian 4 dokumen): cuti > calendar event > jadwal.
 * lateMinutes = menit setelah shiftStart; isLate hanya bila melewati grace.
 * Mengembalikan null bila hari belum bisa disimpulkan (mis. shift belum selesai & belum ada punch).
 */
export function evaluateDay(ctx: DayContext): DayEvaluation | null {
  const { slot, punches, graceMinutes, now } = ctx;
  const first = punches[0] ?? null;
  const last = punches.length > 1 ? punches[punches.length - 1] : null;
  const base = { clockIn: first, clockOut: last, isLate: false, lateMinutes: 0 };

  if (ctx.onLeave) return { ...base, status: 'ON_LEAVE' };
  if (ctx.holiday) return { ...base, status: 'HOLIDAY' };
  if (slot?.dayType === 'OFFDAY') return { ...base, status: 'OFFDAY' };

  // Tanpa jadwal: tidak ada acuan terlambat, cukup catat kehadiran bila ada punch
  if (!slot || !slot.shiftStart || !slot.shiftEnd) {
    return first ? { ...base, status: 'PRESENT' } : null;
  }

  const start = slot.shiftStart.getTime();
  const end = slot.shiftEnd.getTime();

  if (punches.length === 0) {
    return now.getTime() > end ? { ...base, status: 'ABSENT' } : null;
  }

  // Satu punch di paruh akhir shift = lupa clock in (hanya ada clock out)
  if (punches.length === 1 && first!.getTime() > start + (end - start) / 2) {
    return { status: 'INCOMPLETE', clockIn: null, clockOut: first, isLate: false, lateMinutes: 0 };
  }

  const lateMinutes = Math.max(0, Math.floor((first!.getTime() - start) / MIN));
  const isLate = lateMinutes > graceMinutes;

  if (!last && now.getTime() > end) {
    return { status: 'INCOMPLETE', clockIn: first, clockOut: null, isLate, lateMinutes };
  }
  return { status: isLate ? 'LATE' : 'PRESENT', clockIn: first, clockOut: last, isLate, lateMinutes };
}
