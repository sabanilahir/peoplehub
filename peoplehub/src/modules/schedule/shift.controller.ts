import { Body, Controller, Delete, Get, NotFoundException, Param, Patch, Post } from '@nestjs/common';
import { RequirePermission } from '../../common/decorators/require-permission.decorator';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateShiftDto, UpdateShiftDto } from './schedule.dto';

@Controller('shifts')
export class ShiftController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @RequirePermission('schedule.shift.read')
  list() {
    return this.prisma.shift.findMany({ orderBy: { code: 'asc' } });
  }

  @Get(':id')
  @RequirePermission('schedule.shift.read')
  async get(@Param('id') id: string) {
    const row = await this.prisma.shift.findUnique({ where: { id } });
    if (!row) throw new NotFoundException();
    return row;
  }

  @Post()
  @RequirePermission('schedule.shift.edit')
  create(@Body() dto: CreateShiftDto) {
    return this.prisma.shift.create({ data: dto });
  }

  /** Ubah template tidak mengubah jadwal lampau: shiftStart/shiftEnd sudah tersimpan per hari. */
  @Patch(':id')
  @RequirePermission('schedule.shift.edit')
  async update(@Param('id') id: string, @Body() dto: UpdateShiftDto) {
    await this.get(id);
    return this.prisma.shift.update({ where: { id }, data: dto });
  }

  @Delete(':id')
  @RequirePermission('schedule.shift.edit')
  async remove(@Param('id') id: string) {
    await this.get(id);
    return this.prisma.shift.update({ where: { id }, data: { isActive: false } });
  }
}
