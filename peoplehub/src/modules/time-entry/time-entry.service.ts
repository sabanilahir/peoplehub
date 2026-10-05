import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { createHash } from 'crypto';
import { parseCsv, ParsedCsv, toCsv } from '../../common/csv.util';
import { localToUtc, parseDate, toDateString, toLocalDate, toOffsetIso } from '../../common/date.util';
import { PrismaService } from '../../prisma/prisma.service';
import { ProcessMonitorService } from '../process-monitor/process-monitor.service';

export const TIME_ENTRY_HEADERS = [
  'employee_number',
  'start_datetime',
  'end_datetime',
  'work_schedule',
  'payroll_period',
  'duration', // JAM
] as const;
const REQUIRED = ['employee_number', 'start_datetime', 'end_datetime'];
const MAX_ROWS = 20_000;
const MAX_ERRORS_STORED = 1000;
const MAX_LOGGED_PROBLEMS = 20;
const CHUNK = 500;
const MAX_DURATION_MS = 24 * 3_600_000;
const PERIOD_RE = /^\d{4}-(0[1-9]|1[0-2])$/;
const DURATION_TOLERANCE_HOURS = 0.01;

// 2026-09-15T16:00:00+07:00 | 2026-09-15 16:00 | 2026-09-15T09:00:00Z
const DT_RE = /^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?\s*(Z|[+-]\d{2}:?\d{2})?$/i;

interface RowError {
  rowNumber: number;
  rawLine: string;
  message: string;
}

interface ValidRow {
  odooEmployeeId: string;
  startAt: Date;
  endAt: Date;
  workDate: Date;
  shiftId: string | null;
  workSchedule: string | null;
  payrollPeriod: string;
  durationHours: number;
}

/** Waktu dengan offset dipakai apa adanya; tanpa offset dibaca sebagai waktu lokal lokasi karyawan. */
function parseDateTime(value: string, timeZone: string): Date | string {
  const m = DT_RE.exec(value.trim());
  if (!m) return `format waktu tidak dikenali: "${value}" (gunakan 2026-09-15T16:00:00+07:00 atau 2026-09-15 16:00)`;
  const [, y, mo, d, hh, mi, ss = '00', off] = m;

  const probe = new Date(Date.UTC(+y, +mo - 1, +d));
  if (probe.getUTCFullYear() !== +y || probe.getUTCMonth() !== +mo - 1 || probe.getUTCDate() !== +d) {
    return `tanggal tidak valid: "${value}"`;
  }
  if (+hh > 23 || +mi > 59 || +ss > 59) return `jam tidak valid: "${value}"`;

  if (off) {
    const norm = off.toUpperCase() === 'Z' ? 'Z' : off.length === 5 ? `${off.slice(0, 3)}:${off.slice(3)}` : off;
    const dt = new Date(`${y}-${mo}-${d}T${hh}:${mi}:${ss}${norm}`);
    return Number.isNaN(dt.getTime()) ? `waktu tidak valid: "${value}"` : dt;
  }
  return new Date(localToUtc(`${y}-${mo}-${d}`, `${hh}:${mi}`, timeZone).getTime() + +ss * 1000);
}

/** Durasi dalam JAM; koma desimal (Excel Indonesia) diterima. */
function parseDuration(raw: string): number | string {
  const v = raw.trim().replace(',', '.');
  if (!/^\d+(\.\d+)?$/.test(v)) return `duration "${raw}" harus berupa angka dalam jam (mis. 8 atau 7.5)`;
  const n = Number(v);
  if (n > 24) return `duration ${n} jam melebihi 24 jam`;
  return Math.round(n * 100) / 100;
}

const hours = (ms: number) => Math.round((ms / 3_600_000) * 100) / 100;
const fmtHours = (n: number) => String(Math.round(n * 100) / 100);

function monthRange(period: string): { from: string; to: string } {
  const [y, m] = period.split('-').map(Number);
  const last = new Date(Date.UTC(y, m, 0)).getUTCDate();
  return { from: `${period}-01`, to: `${period}-${String(last).padStart(2, '0')}` };
}

export interface ImportAccepted {
  batchId: string;
  status: 'RECEIVED';
  total: number;
}

@Injectable()
export class TimeEntryService {
  private readonly logger = new Logger(TimeEntryService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly monitor: ProcessMonitorService,
  ) {}

  template(): string {
    return toCsv([
      [...TIME_ENTRY_HEADERS],
      ['EMP-001', '2026-09-15T16:00:00+07:00', '2026-09-16T00:00:00+07:00', 'S16', '2026-09', 8],
    ]);
  }

  // ---------------------------------------------------------------- inbound

  /**
   * Terima file: periksa format file (header, jumlah baris) secara sinkron agar kesalahan fatal langsung
   * terlihat, lalu proses isi file di latar belakang. Kemajuan dan log tampil di Process Monitor.
   */
  async startImport(content: string, fileName: string, uploadedBy?: string): Promise<ImportAccepted> {
    let parsed: ParsedCsv;
    try {
      parsed = parseCsv(content);
    } catch (e) {
      throw new BadRequestException(e instanceof Error ? e.message : 'File CSV tidak dapat dibaca.');
    }

    const missing = REQUIRED.filter((h) => !parsed.headers.includes(h));
    if (missing.length > 0) {
      throw new BadRequestException(`Kolom wajib tidak ditemukan: ${missing.join(', ')}. Kolom yang diharapkan: ${TIME_ENTRY_HEADERS.join(', ')}.`);
    }
    if (parsed.records.length === 0) throw new BadRequestException('File tidak berisi baris data.');
    if (parsed.records.length > MAX_ROWS) throw new BadRequestException(`Maksimal ${MAX_ROWS} baris per file.`);

    const batch = await this.prisma.importBatch.create({
      data: {
        fileType: 'TIME_ENTRY',
        fileName: fileName.slice(0, 200),
        fileHash: createHash('sha256').update(content).digest('hex'),
        status: 'RECEIVED',
        totalRows: parsed.records.length,
        uploadedBy,
      },
    });
    await this.monitor.log(batch.id, 'INFO', `File "${fileName}" diterima: ${parsed.records.length} baris, pemisah "${parsed.delimiter === '\t' ? 'tab' : parsed.delimiter}". Menunggu diproses.`);

    // Lepas dari request: respons segera kembali, proses berjalan di latar belakang
    setImmediate(() => {
      this.runImport(batch.id, parsed).catch((e) => this.logger.error(`Impor ${batch.id} gagal tak terduga`, e instanceof Error ? e.stack : String(e)));
    });

    return { batchId: batch.id, status: 'RECEIVED', total: parsed.records.length };
  }

  private async runImport(batchId: string, parsed: ParsedCsv) {
    const startedAt = Date.now();
    const log = (level: 'INFO' | 'WARN' | 'ERROR', msg: string) => this.monitor.log(batchId, level, msg);
    const setBatch = (data: Prisma.ImportBatchUpdateInput) => this.prisma.importBatch.update({ where: { id: batchId }, data });

    try {
      await setBatch({ status: 'VALIDATING', startedAt: new Date(), progress: 2 });
      await log('INFO', 'Proses dimulai. Memvalidasi baris…');

      const col = (name: string) => parsed.headers.indexOf(name);
      const iEmp = col('employee_number');
      const iStart = col('start_datetime');
      const iEnd = col('end_datetime');
      const iSched = col('work_schedule');
      const iPeriod = col('payroll_period');
      const iDur = col('duration');
      if (iDur < 0) await log('WARN', 'Kolom "duration" tidak ada di file; durasi dihitung dari selisih start dan end (jam).');

      const cell = (cells: string[], i: number) => (i >= 0 ? (cells[i] ?? '').trim() : '');
      const niks = [...new Set(parsed.records.map((r) => cell(r.cells, iEmp)).filter(Boolean))];
      const [employees, shifts] = await Promise.all([
        this.prisma.odooEmployee.findMany({
          where: { nik: { in: niks } },
          select: { id: true, nik: true, isActive: true, workLocation: { select: { timezone: true } } },
        }),
        this.prisma.shift.findMany({ select: { id: true, code: true } }),
      ]);
      const byNik = new Map(employees.map((e) => [e.nik!, e]));
      const byCode = new Map(shifts.map((s) => [s.code, s]));

      const valid: ValidRow[] = [];
      const errors: RowError[] = [];
      const warnings: string[] = [];
      const seen = new Set<string>();

      for (const rec of parsed.records) {
        const raw = rec.cells.join(parsed.delimiter).slice(0, 500);
        const fail = (message: string) => errors.push({ rowNumber: rec.line, rawLine: raw, message });

        const nik = cell(rec.cells, iEmp);
        const startRaw = cell(rec.cells, iStart);
        const endRaw = cell(rec.cells, iEnd);
        const sched = cell(rec.cells, iSched);
        const periodRaw = cell(rec.cells, iPeriod);
        const durRaw = cell(rec.cells, iDur);

        if (!nik) { fail('employee_number kosong'); continue; }
        if (!startRaw || !endRaw) { fail('start_datetime dan end_datetime wajib diisi'); continue; }

        const emp = byNik.get(nik);
        if (!emp) { fail(`karyawan dengan NIK "${nik}" tidak ditemukan`); continue; }
        if (!emp.isActive) { fail(`karyawan "${nik}" nonaktif`); continue; }

        const tz = emp.workLocation.timezone;
        const start = parseDateTime(startRaw, tz);
        if (typeof start === 'string') { fail(`start_datetime: ${start}`); continue; }
        const end = parseDateTime(endRaw, tz);
        if (typeof end === 'string') { fail(`end_datetime: ${end}`); continue; }
        if (end.getTime() <= start.getTime()) { fail('end_datetime harus setelah start_datetime'); continue; }
        if (end.getTime() - start.getTime() > MAX_DURATION_MS) { fail('rentang start sampai end lebih dari 24 jam'); continue; }

        const computed = hours(end.getTime() - start.getTime());
        let durationHours = computed;
        if (durRaw) {
          const d = parseDuration(durRaw);
          if (typeof d === 'string') { fail(d); continue; }
          durationHours = d;
          if (Math.abs(d - computed) > DURATION_TOLERANCE_HOURS) {
            warnings.push(`Baris ${rec.line}: duration ${fmtHours(d)} jam berbeda dari selisih waktu ${fmtHours(computed)} jam (nilai dari file dipakai).`);
          }
        }

        let shiftId: string | null = null;
        if (sched) {
          const shift = byCode.get(sched);
          if (!shift) { fail(`work_schedule "${sched}" tidak dikenal (kode shift belum terdaftar)`); continue; }
          shiftId = shift.id;
        }

        const workDate = toLocalDate(start, tz);
        if (periodRaw && !PERIOD_RE.test(periodRaw)) { fail(`payroll_period "${periodRaw}" harus berformat YYYY-MM`); continue; }
        const payrollPeriod = periodRaw || workDate.slice(0, 7);

        const key = `${emp.id}|${start.getTime()}`;
        if (seen.has(key)) { fail('duplikat dalam file (karyawan dan start_datetime sama)'); continue; }
        seen.add(key);

        valid.push({
          odooEmployeeId: emp.id,
          startAt: start,
          endAt: end,
          workDate: parseDate(workDate),
          shiftId,
          workSchedule: sched || null,
          payrollPeriod,
          durationHours,
        });
      }

      await log(errors.length > 0 ? 'WARN' : 'INFO', `Validasi selesai: ${valid.length} baris valid, ${errors.length} baris gagal.`);
      for (const e of errors.slice(0, MAX_LOGGED_PROBLEMS)) await log('WARN', `Baris ${e.rowNumber}: ${e.message}`);
      if (errors.length > MAX_LOGGED_PROBLEMS) await log('WARN', `…dan ${errors.length - MAX_LOGGED_PROBLEMS} baris gagal lainnya (lihat daftar error).`);
      for (const w of warnings.slice(0, MAX_LOGGED_PROBLEMS)) await log('WARN', w);
      if (warnings.length > MAX_LOGGED_PROBLEMS) await log('WARN', `…dan ${warnings.length - MAX_LOGGED_PROBLEMS} peringatan durasi lainnya.`);

      if (errors.length > 0) {
        await this.prisma.importRowError.createMany({
          data: errors.slice(0, MAX_ERRORS_STORED).map((e) => ({ batchId, ...e })),
        });
      }
      await setBatch({ progress: 30, errorRows: errors.length });

      // Simpan per potongan; progres dihitung dari potongan yang selesai
      let created = 0;
      let updated = 0;
      const chunks = Math.ceil(valid.length / CHUNK);
      for (let i = 0; i < valid.length; i += CHUNK) {
        const chunk = valid.slice(i, i + CHUNK);
        const existing = await this.prisma.timeEntry.findMany({
          where: {
            odooEmployeeId: { in: [...new Set(chunk.map((r) => r.odooEmployeeId))] },
            startAt: { in: chunk.map((r) => r.startAt) },
          },
          select: { id: true, odooEmployeeId: true, startAt: true },
        });
        const existingMap = new Map(existing.map((e) => [`${e.odooEmployeeId}|${e.startAt.getTime()}`, e.id]));

        let chunkCreated = 0;
        let chunkUpdated = 0;
        const toCreate: Prisma.TimeEntryCreateManyInput[] = [];
        for (const r of chunk) {
          const data = {
            endAt: r.endAt,
            workDate: r.workDate,
            shiftId: r.shiftId,
            workSchedule: r.workSchedule,
            payrollPeriod: r.payrollPeriod,
            durationHours: r.durationHours,
            source: 'IMPORT' as const,
            importBatchId: batchId,
          };
          const id = existingMap.get(`${r.odooEmployeeId}|${r.startAt.getTime()}`);
          if (id) {
            await this.prisma.timeEntry.update({ where: { id }, data });
            chunkUpdated++;
          } else {
            toCreate.push({ odooEmployeeId: r.odooEmployeeId, startAt: r.startAt, ...data });
          }
        }
        if (toCreate.length > 0) {
          chunkCreated = (await this.prisma.timeEntry.createMany({ data: toCreate, skipDuplicates: true })).count;
        }
        created += chunkCreated;
        updated += chunkUpdated;

        const n = Math.floor(i / CHUNK) + 1;
        await setBatch({ progress: 30 + Math.round((n / chunks) * 65), successRows: created + updated });
        await log('INFO', `Menyimpan potongan ${n}/${chunks}: ${chunkCreated} baru, ${chunkUpdated} diperbarui.`);
      }

      const success = created + updated;
      const status = errors.length === 0 ? 'APPLIED' : success === 0 ? 'FAILED' : 'PARTIAL';
      const seconds = Math.max(0, Math.round((Date.now() - startedAt) / 1000));
      await setBatch({ status, progress: 100, successRows: success, errorRows: errors.length, finishedAt: new Date() });
      await log(
        status === 'APPLIED' ? 'INFO' : status === 'FAILED' ? 'ERROR' : 'WARN',
        status === 'FAILED'
          ? `Proses gagal: tidak ada baris yang tersimpan (${errors.length} baris gagal). Selesai dalam ${seconds} detik.`
          : `Proses selesai${errors.length > 0 ? ' dengan error' : ''}: ${created} baru, ${updated} diperbarui, ${errors.length} gagal. Selesai dalam ${seconds} detik.`,
      );
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      this.logger.error(`Impor ${batchId} gagal: ${message}`);
      await this.monitor.log(batchId, 'ERROR', `Proses berhenti karena kesalahan tak terduga: ${message}`).catch(() => undefined);
      await this.prisma.importBatch
        .update({ where: { id: batchId }, data: { status: 'FAILED', finishedAt: new Date() } })
        .catch(() => undefined);
    }
  }

  // --------------------------------------------------------------- listing

  async list(q: { payrollPeriod?: string; workLocationId?: string; page?: number; pageSize?: number }) {
    const page = q.page ?? 1;
    const pageSize = q.pageSize ?? 50;
    const where: Prisma.TimeEntryWhereInput = {
      ...(q.payrollPeriod && { payrollPeriod: q.payrollPeriod }),
      ...(q.workLocationId && { employee: { workLocationId: q.workLocationId } }),
    };
    const [items, total] = await Promise.all([
      this.prisma.timeEntry.findMany({
        where,
        include: {
          employee: { select: { id: true, name: true, nik: true, workLocation: { select: { timezone: true } } } },
          shift: { select: { code: true } },
        },
        orderBy: [{ startAt: 'desc' }],
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.timeEntry.count({ where }),
    ]);
    return { items, total, page, pageSize };
  }

  // --------------------------------------------------------------- outbound

  /**
   * source=attendance: dibentuk dari absensi harian PeopleHub (hanya hari dengan jam masuk DAN pulang);
   * duration = selisih jam pulang dan masuk, dalam jam.
   * source=imported: entri hasil unggahan yang tersimpan (duration sesuai yang tersimpan).
   * Karyawan tanpa NIK dilewati karena employee_number memakai NIK.
   */
  async exportCsv(q: {
    source: 'attendance' | 'imported';
    payrollPeriod?: string;
    from?: string;
    to?: string;
    workLocationId?: string;
  }): Promise<{ csv: string; filename: string; rows: number }> {
    let from: string;
    let to: string;
    if (q.payrollPeriod) {
      ({ from, to } = monthRange(q.payrollPeriod));
    } else if (q.from && q.to) {
      from = q.from.slice(0, 10);
      to = q.to.slice(0, 10);
    } else {
      throw new BadRequestException('Isi payrollPeriod (YYYY-MM) atau from dan to.');
    }
    if (to < from) throw new BadRequestException('to tidak boleh sebelum from.');
    if ((parseDate(to).getTime() - parseDate(from).getTime()) / 86_400_000 > 366) {
      throw new BadRequestException('Rentang maksimal 366 hari.');
    }

    const body: (string | number)[][] = [];
    const fromD = parseDate(from);
    const toD = parseDate(to);
    const locFilter = q.workLocationId ? { workLocationId: q.workLocationId } : {};

    if (q.source === 'imported') {
      const rows = await this.prisma.timeEntry.findMany({
        where: {
          workDate: { gte: fromD, lte: toD },
          employee: { nik: { not: null }, ...locFilter },
          ...(q.payrollPeriod && { payrollPeriod: q.payrollPeriod }),
        },
        include: {
          employee: { select: { nik: true, workLocation: { select: { timezone: true } } } },
          shift: { select: { code: true } },
        },
        orderBy: [{ startAt: 'asc' }, { odooEmployeeId: 'asc' }],
      });
      for (const r of rows) {
        const tz = r.employee.workLocation.timezone;
        body.push([
          r.employee.nik!,
          toOffsetIso(r.startAt, tz),
          toOffsetIso(r.endAt, tz),
          r.shift?.code ?? r.workSchedule ?? '',
          r.payrollPeriod,
          fmtHours(Number(r.durationHours)),
        ]);
      }
    } else {
      const days = await this.prisma.attendanceDaily.findMany({
        where: {
          workDate: { gte: fromD, lte: toD },
          clockIn: { not: null },
          clockOut: { not: null },
          employee: { nik: { not: null }, ...locFilter },
        },
        include: { employee: { select: { nik: true, workLocation: { select: { timezone: true } } } } },
        orderBy: [{ workDate: 'asc' }, { odooEmployeeId: 'asc' }],
      });
      const schedules = await this.prisma.employeeSchedule.findMany({
        where: { workDate: { gte: fromD, lte: toD }, odooEmployeeId: { in: [...new Set(days.map((d) => d.odooEmployeeId))] } },
        select: { odooEmployeeId: true, workDate: true, shift: { select: { code: true } } },
      });
      const code = new Map(schedules.map((s) => [`${s.odooEmployeeId}|${toDateString(s.workDate)}`, s.shift?.code ?? '']));

      for (const d of days) {
        const tz = d.employee.workLocation.timezone;
        const date = toDateString(d.workDate);
        body.push([
          d.employee.nik!,
          toOffsetIso(d.clockIn!, tz),
          toOffsetIso(d.clockOut!, tz),
          code.get(`${d.odooEmployeeId}|${date}`) ?? '',
          q.payrollPeriod ?? date.slice(0, 7),
          fmtHours(hours(d.clockOut!.getTime() - d.clockIn!.getTime())),
        ]);
      }
    }

    const label = q.payrollPeriod ?? `${from}_${to}`;
    return {
      csv: toCsv([[...TIME_ENTRY_HEADERS], ...body]),
      filename: `time-entries-${q.source === 'imported' ? 'impor' : 'absensi'}-${label}.csv`,
      rows: body.length,
    };
  }
}
