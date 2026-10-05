import { Controller, Get, NotFoundException, Param, Query } from '@nestjs/common';
import { RequirePermission } from '../../common/decorators/require-permission.decorator';
import { parseDate } from '../../common/date.util';
import { PrismaService } from '../../prisma/prisma.service';
import { ListRequestQuery } from './request.dto';

@Controller('leave-requests')
export class LeaveController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @RequirePermission('leave.request.read')
  async list(@Query() q: ListRequestQuery) {
    const page = q.page ?? 1;
    const pageSize = q.pageSize ?? 50;
    const where = {
      ...(q.odooEmployeeId && { odooEmployeeId: q.odooEmployeeId }),
      ...(q.status && { overallStatus: q.status }),
      ...(q.from && { endDate: { gte: parseDate(q.from) } }),
      ...(q.to && { startDate: { lte: parseDate(q.to) } }),
    };
    const [items, total] = await Promise.all([
      this.prisma.leaveRequest.findMany({
        where,
        include: { employee: { select: { id: true, name: true, nik: true } } },
        orderBy: { startDate: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.leaveRequest.count({ where }),
    ]);
    return { items, total, page, pageSize };
  }

  @Get(':id')
  @RequirePermission('leave.request.read')
  async get(@Param('id') id: string) {
    const row = await this.prisma.leaveRequest.findUnique({ where: { id } });
    if (!row) throw new NotFoundException();
    return row;
  }
}
