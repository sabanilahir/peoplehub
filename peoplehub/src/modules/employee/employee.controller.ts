import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  NotFoundException,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { parseDate } from '../../common/date.util';
import { RequirePermission } from '../../common/decorators/require-permission.decorator';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateEmployeeDto, ListEmployeeQuery, UpdateEmployeeDto } from './employee.dto';

@Controller('employees')
export class EmployeeController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @RequirePermission('master.employee.read')
  async list(@Query() query: ListEmployeeQuery) {
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? 50;
    const where: Prisma.OdooEmployeeWhereInput = {
      ...(query.workLocationId && { workLocationId: query.workLocationId }),
      ...(query.q && {
        OR: [
          { name: { contains: query.q, mode: 'insensitive' } },
          { nik: { contains: query.q, mode: 'insensitive' } },
          { email: { contains: query.q, mode: 'insensitive' } },
        ],
      }),
    };
    const [items, total] = await Promise.all([
      this.prisma.odooEmployee.findMany({
        where,
        include: { workLocation: { select: { id: true, code: true, name: true } } },
        orderBy: { name: 'asc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.odooEmployee.count({ where }),
    ]);
    return { items, total, page, pageSize };
  }

  @Get(':id')
  @RequirePermission('master.employee.read')
  async get(@Param('id') id: string) {
    const row = await this.prisma.odooEmployee.findUnique({
      where: { id },
      include: { workLocation: true, manager: { select: { id: true, name: true, odooId: true } } },
    });
    if (!row) throw new NotFoundException();
    return row;
  }

  // ASSUMPTION: master karyawan ada di Odoo; CRUD manual disediakan untuk seed/koreksi
  // sampai sync inbound dari Odoo berjalan.
  @Post()
  @RequirePermission('master.employee.edit')
  async create(@Body() dto: CreateEmployeeDto) {
    await this.assertManagerValid(dto.odooId, dto.parentOdooId);
    return this.prisma.odooEmployee.create({ data: { ...dto, hireDate: dto.hireDate ? parseDate(dto.hireDate) : undefined } });
  }

  @Patch(':id')
  @RequirePermission('master.employee.edit')
  async update(@Param('id') id: string, @Body() dto: UpdateEmployeeDto) {
    const current = await this.get(id);
    if (dto.parentOdooId !== undefined) await this.assertManagerValid(current.odooId, dto.parentOdooId);
    const { hireDate, ...rest } = dto;
    return this.prisma.odooEmployee.update({
      where: { id },
      data: { ...rest, ...(hireDate !== undefined && { hireDate: hireDate ? parseDate(hireDate) : null }) },
    });
  }

  /** Soft delete: karyawan nonaktif, riwayat absensi tetap utuh. */
  @Delete(':id')
  @RequirePermission('master.employee.edit')
  async remove(@Param('id') id: string) {
    await this.get(id);
    return this.prisma.odooEmployee.update({ where: { id }, data: { isActive: false } });
  }

  /** Manager harus ada dan tidak boleh membentuk siklus (A -> B -> ... -> A). */
  private async assertManagerValid(odooId: number, parentOdooId?: number) {
    if (parentOdooId === undefined || parentOdooId === null) return;
    if (parentOdooId === odooId) throw new BadRequestException('Karyawan tidak boleh menjadi manager dirinya sendiri');

    const seen = new Set<number>([odooId]);
    let cursor: number | null = parentOdooId;
    while (cursor !== null) {
      if (seen.has(cursor)) throw new BadRequestException('Relasi manager membentuk siklus');
      seen.add(cursor);
      const node: { parentOdooId: number | null } | null = await this.prisma.odooEmployee.findUnique({
        where: { odooId: cursor },
        select: { parentOdooId: true },
      });
      if (!node) throw new BadRequestException(`Manager dengan odooId ${cursor} tidak ditemukan`);
      cursor = node.parentOdooId;
    }
  }
}
