import { Controller, Get, NotFoundException, Param, Query } from '@nestjs/common';
import { RequirePermission } from '../../common/decorators/require-permission.decorator';
import { parseDate } from '../../common/date.util';
import { PrismaService } from '../../prisma/prisma.service';
import { ListRequestQuery } from '../request/request.dto';

@Controller('overtime-requests')
export class OvertimeRequestController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @RequirePermission('overtime.request.read')
  async list(@Query() q: ListRequestQuery) {
    const page = q.page ?? 1;
    const pageSize = q.pageSize ?? 50;
    const where = {
      ...(q.odooEmployeeId && { odooEmployeeId: q.odooEmployeeId }),
      ...(q.status && { overallStatus: q.status }),
      ...((q.from || q.to) && {
        workDate: { ...(q.from && { gte: parseDate(q.from) }), ...(q.to && { lte: parseDate(q.to) }) },
      }),
    };
    const [items, total] = await Promise.all([
      this.prisma.overtimeRequest.findMany({
        where,
        orderBy: { workDate: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.overtimeRequest.count({ where }),
    ]);
    return { items, total, page, pageSize };
  }

  @Get(':id')
  @RequirePermission('overtime.request.read')
  async get(@Param('id') id: string) {
    const row = await this.prisma.overtimeRequest.findUnique({ where: { id }, include: { realizations: true } });
    if (!row) throw new NotFoundException();
    return row;
  }
}
