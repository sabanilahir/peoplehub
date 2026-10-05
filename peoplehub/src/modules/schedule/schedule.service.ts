import { BadRequestException, Injectable } from '@nestjs/common';
import { DataSource } from '@prisma/client';
import { localToUtc, parseDate } from '../../common/date.util';
import { PrismaService } from '../../prisma/prisma.service';
import { UpsertScheduleDto } from './schedule.dto';

@Injectable()
export class ScheduleService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Upsert satu hari jadwal. shiftStart/shiftEnd dihitung dari template shift + timezone
   * lokasi karyawan lalu DISIMPAN (bukan dihitung ulang), sehingga shift lintas hari
   * (mis. 16:00 + 480 menit -> 00:00 hari berikutnya) tetap akurat.
   */
  async upsert(dto: UpsertScheduleDto, source: DataSource = 'MANUAL', importBatchId?: string) {
    const employee = await this.prisma.odooEmployee.findUnique({
      where: { id: dto.odooEmployeeId },
      include: { workLocation: true },
    });
    if (!employee) throw new BadRequestException(`Karyawan ${dto.odooEmployeeId} tidak ditemukan`);

    let shiftId: string | null = null;
    let shiftStart: Date | null = null;
    let shiftEnd: Date | null = null;

    if (dto.dayType === 'WORKDAY') {
      if (!dto.shiftId) throw new BadRequestException('WORKDAY wajib menyertakan shiftId');
      const shift = await this.prisma.shift.findUnique({ where: { id: dto.shiftId } });
      if (!shift || !shift.isActive) throw new BadRequestException('Shift tidak ditemukan atau nonaktif');
      shiftId = shift.id;
      shiftStart = localToUtc(dto.workDate, shift.startTime, employee.workLocation.timezone);
      shiftEnd = new Date(shiftStart.getTime() + shift.durationMinutes * 60_000);
    } else if (dto.shiftId) {
      throw new BadRequestException('OFFDAY tidak boleh memiliki shiftId');
    }

    const workDate = parseDate(dto.workDate);
    const data = { dayType: dto.dayType, shiftId, shiftStart, shiftEnd, source, importBatchId: importBatchId ?? null };
    return this.prisma.employeeSchedule.upsert({
      where: { odooEmployeeId_workDate: { odooEmployeeId: dto.odooEmployeeId, workDate } },
      update: data,
      create: { odooEmployeeId: dto.odooEmployeeId, workDate, ...data },
    });
  }
}
