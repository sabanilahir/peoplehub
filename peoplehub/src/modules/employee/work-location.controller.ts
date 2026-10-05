import { Body, Controller, Delete, Get, NotFoundException, Param, Patch, Post } from '@nestjs/common';
import { RequirePermission } from '../../common/decorators/require-permission.decorator';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateWorkLocationDto, UpdateWorkLocationDto } from './work-location.dto';

@Controller('work-locations')
export class WorkLocationController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @RequirePermission('master.location.read')
  list() {
    return this.prisma.workLocation.findMany({ orderBy: { code: 'asc' } });
  }

  @Get(':id')
  @RequirePermission('master.location.read')
  async get(@Param('id') id: string) {
    const row = await this.prisma.workLocation.findUnique({ where: { id } });
    if (!row) throw new NotFoundException();
    return row;
  }

  @Post()
  @RequirePermission('master.location.edit')
  create(@Body() dto: CreateWorkLocationDto) {
    return this.prisma.workLocation.create({ data: dto });
  }

  @Patch(':id')
  @RequirePermission('master.location.edit')
  async update(@Param('id') id: string, @Body() dto: UpdateWorkLocationDto) {
    await this.get(id);
    return this.prisma.workLocation.update({ where: { id }, data: dto });
  }

  /** Soft delete: lokasi yang sudah dipakai karyawan/rule tidak dihapus fisik. */
  @Delete(':id')
  @RequirePermission('master.location.edit')
  async remove(@Param('id') id: string) {
    await this.get(id);
    return this.prisma.workLocation.update({ where: { id }, data: { isActive: false } });
  }
}
