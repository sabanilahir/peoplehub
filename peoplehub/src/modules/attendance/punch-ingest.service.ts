import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { createHash } from 'crypto';
import { addDays, parseDate, toDateString, toLocalDate } from '../../common/date.util';
import { PrismaService } from '../../prisma/prisma.service';
import { AttendanceProcessorService } from './attendance-processor.service';
import { PunchBatchDto } from './punch-ingest.dto';

const MAX_FUTURE_MS = 24 * 3_600_000;

@Injectable()
export class PunchIngestService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly processor: AttendanceProcessorService,
  ) {}

  /**
   * Terima batch punch dari mesin. Punch mentah immutable dan idempoten:
   * fingerprint = sha256(serial|enrollId|punchAt) sehingga kiriman ulang tidak menggandakan.
   * Punch dari enrollId yang belum dipetakan tetap disimpan (odooEmployeeId null) dan
   * otomatis ditautkan begitu mapping dibuat.
   */
  async ingest(dto: PunchBatchDto) {
    const device = await this.prisma.device.findUnique({ where: { serialNumber: dto.deviceSerial } });
    if (!device || !device.isActive) throw new BadRequestException('Mesin tidak terdaftar atau nonaktif');

    const mappings = await this.prisma.employeeDeviceMap.findMany({
      where: { deviceId: device.id },
      include: { employee: { include: { workLocation: true } } },
    });
    const byEnroll = new Map(mappings.map((m) => [m.enrollId, m.employee]));

    const result = { received: dto.punches.length, inserted: 0, duplicates: 0, unmapped: 0, rejected: [] as { index: number; message: string }[] };
    const affected = new Map<string, { from: string; to: string }>();
    const now = Date.now();

    for (const [index, item] of dto.punches.entries()) {
      const at = new Date(item.punchAt);
      if (at.getTime() > now + MAX_FUTURE_MS) {
        result.rejected.push({ index, message: 'punchAt terlalu jauh di masa depan (cek jam mesin)' });
        continue;
      }
      const employee = byEnroll.get(item.enrollId);
      const fingerprint = createHash('sha256').update(`${dto.deviceSerial}|${item.enrollId}|${at.toISOString()}`).digest('hex');

      try {
        await this.prisma.attendanceRawPunch.create({
          data: {
            odooEmployeeId: employee?.id ?? null,
            deviceId: device.id,
            enrollId: item.enrollId,
            punchAt: at,
            direction: item.direction ?? 'UNKNOWN',
            source: 'FINGERPRINT',
            fingerprint,
            payloadJson: item as unknown as Prisma.InputJsonValue,
          },
        });
      } catch (e) {
        if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
          result.duplicates++;
          continue;
        }
        throw e;
      }
      result.inserted++;

      if (!employee) {
        result.unmapped++;
        continue;
      }
      // Shift lintas hari: punch bisa milik hari sebelumnya, jadi hitung ulang [d-1, d]
      const local = toLocalDate(at, employee.workLocation.timezone);
      const range = affected.get(employee.id);
      const lo = toDateString(addDays(parseDate(local), -1));
      affected.set(employee.id, { from: range && range.from < lo ? range.from : lo, to: range && range.to > local ? range.to : local });
    }

    for (const [employeeId, r] of affected) await this.processor.recompute(employeeId, r.from, r.to);
    return { ...result, recomputedEmployees: affected.size };
  }

  /** Tautkan punch lama yang belum punya karyawan setelah mapping dibuat, lalu hitung ulang. */
  async relinkUnmapped(deviceId: string, enrollId: string, odooEmployeeId: string) {
    const punches = await this.prisma.attendanceRawPunch.findMany({
      where: { deviceId, enrollId, odooEmployeeId: null },
      select: { id: true, punchAt: true },
    });
    if (punches.length === 0) return { relinked: 0 };

    await this.prisma.attendanceRawPunch.updateMany({
      where: { id: { in: punches.map((p) => p.id) } },
      data: { odooEmployeeId },
    });
    const times = punches.map((p) => p.punchAt.getTime());
    const from = toDateString(addDays(new Date(Math.min(...times)), -1));
    const to = toDateString(addDays(new Date(Math.max(...times)), 1)); // timezone lokal bisa maju satu hari dari UTC
    await this.processor.recompute(odooEmployeeId, from, to);
    return { relinked: punches.length };
  }
}
