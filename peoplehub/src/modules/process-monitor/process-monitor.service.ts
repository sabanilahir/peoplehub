import { Injectable, Logger, NotFoundException, OnModuleInit } from '@nestjs/common';
import { ImportFileType, ImportStatus, LogLevel, Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

const ACTIVE: ImportStatus[] = ['RECEIVED', 'VALIDATING'];

/**
 * Catatan proses (impor file) untuk halaman Process Monitor: status, progres, dan log.
 * ASSUMPTION: proses berjalan di dalam server API (tanpa antrean). Bila server berhenti di
 * tengah proses, proses itu ditandai GAGAL saat server menyala lagi.
 */
@Injectable()
export class ProcessMonitorService implements OnModuleInit {
  private readonly logger = new Logger(ProcessMonitorService.name);

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit() {
    const stale = await this.prisma.importBatch.findMany({ where: { status: { in: ACTIVE } }, select: { id: true } });
    for (const b of stale) {
      await this.log(b.id, 'ERROR', 'Proses terhenti karena server dimulai ulang. Unggah ulang file untuk mengulang.');
      await this.prisma.importBatch.update({ where: { id: b.id }, data: { status: 'FAILED', finishedAt: new Date() } });
    }
    if (stale.length > 0) this.logger.warn(`${stale.length} proses yang menggantung ditandai gagal.`);
  }

  async log(batchId: string, level: LogLevel, message: string) {
    await this.prisma.processLog.create({ data: { batchId, level, message: message.slice(0, 1000) } });
  }

  async list(q: { status?: ImportStatus; fileType?: ImportFileType; page?: number; pageSize?: number }) {
    const page = q.page ?? 1;
    const pageSize = q.pageSize ?? 25;
    const where: Prisma.ImportBatchWhereInput = {
      ...(q.status && { status: q.status }),
      ...(q.fileType && { fileType: q.fileType }),
    };
    const [rows, total, active] = await Promise.all([
      this.prisma.importBatch.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.importBatch.count({ where }),
      this.prisma.importBatch.count({ where: { status: { in: ACTIVE } } }),
    ]);
    const users = await this.userEmails(rows.map((r) => r.uploadedBy));
    return {
      items: rows.map((r) => this.present(r, users)),
      total,
      page,
      pageSize,
      activeCount: active,
    };
  }

  async get(id: string) {
    const batch = await this.prisma.importBatch.findUnique({ where: { id } });
    if (!batch) throw new NotFoundException('Proses tidak ditemukan.');
    const [logs, users] = await Promise.all([
      this.prisma.processLog.findMany({
        where: { batchId: id },
        orderBy: { seq: 'asc' },
        take: 1000,
        select: { id: true, level: true, message: true, createdAt: true },
      }),
      this.userEmails([batch.uploadedBy]),
    ]);
    return { ...this.present(batch, users), logs };
  }

  async errors(id: string) {
    const exists = await this.prisma.importBatch.count({ where: { id } });
    if (!exists) throw new NotFoundException('Proses tidak ditemukan.');
    return this.prisma.importRowError.findMany({
      where: { batchId: id },
      orderBy: { rowNumber: 'asc' },
      take: 1000,
      select: { rowNumber: true, rawLine: true, message: true },
    });
  }

  private async userEmails(ids: (string | null)[]) {
    const unique = [...new Set(ids.filter((x): x is string => !!x))];
    if (unique.length === 0) return new Map<string, string>();
    const users = await this.prisma.user.findMany({ where: { id: { in: unique } }, select: { id: true, email: true } });
    return new Map(users.map((u) => [u.id, u.email]));
  }

  private present(b: Prisma.ImportBatchGetPayload<object>, users: Map<string, string>) {
    const start = b.startedAt ?? b.createdAt;
    const end = b.finishedAt ?? (ACTIVE.includes(b.status) ? new Date() : null);
    return {
      id: b.id,
      fileType: b.fileType,
      fileName: b.fileName,
      status: b.status,
      progress: b.status === 'APPLIED' || b.status === 'PARTIAL' ? 100 : b.progress,
      totalRows: b.totalRows,
      successRows: b.successRows,
      errorRows: b.errorRows,
      uploadedBy: b.uploadedBy ? (users.get(b.uploadedBy) ?? null) : null,
      createdAt: b.createdAt,
      startedAt: b.startedAt,
      finishedAt: b.finishedAt,
      durationSeconds: end ? Math.max(0, Math.round((end.getTime() - start.getTime()) / 1000)) : null,
    };
  }
}
