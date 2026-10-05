import { Body, Controller, Delete, Get, NotFoundException, Param, Patch, Post } from '@nestjs/common';
import { IsBoolean, IsOptional, IsString } from 'class-validator';
import { RequirePermission } from '../../common/decorators/require-permission.decorator';
import { PrismaService } from '../../prisma/prisma.service';
import { PunchIngestService } from './punch-ingest.service';

class CreateDeviceDto {
  @IsString() serialNumber: string;
  @IsString() name: string;
  @IsOptional() @IsString() vendor?: string;
  @IsString() workLocationId: string;
}

class UpdateDeviceDto {
  @IsOptional() @IsString() name?: string;
  @IsOptional() @IsString() vendor?: string;
  @IsOptional() @IsString() workLocationId?: string;
  @IsOptional() @IsBoolean() isActive?: boolean;
}

class CreateMappingDto {
  @IsString() enrollId: string;
  @IsString() odooEmployeeId: string;
}

@Controller('devices')
export class DeviceController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ingest: PunchIngestService,
  ) {}

  @Get()
  @RequirePermission('attendance.device.read')
  list() {
    return this.prisma.device.findMany({ orderBy: { name: 'asc' }, include: { _count: { select: { mappings: true } } } });
  }

  @Get(':id')
  @RequirePermission('attendance.device.read')
  async get(@Param('id') id: string) {
    const row = await this.prisma.device.findUnique({ where: { id }, include: { workLocation: true } });
    if (!row) throw new NotFoundException();
    return row;
  }

  @Post()
  @RequirePermission('attendance.device.edit')
  create(@Body() dto: CreateDeviceDto) {
    return this.prisma.device.create({ data: dto });
  }

  @Patch(':id')
  @RequirePermission('attendance.device.edit')
  async update(@Param('id') id: string, @Body() dto: UpdateDeviceDto) {
    await this.get(id);
    return this.prisma.device.update({ where: { id }, data: dto });
  }

  @Get(':id/mappings')
  @RequirePermission('attendance.device.read')
  mappings(@Param('id') id: string) {
    return this.prisma.employeeDeviceMap.findMany({
      where: { deviceId: id },
      include: { employee: { select: { id: true, name: true, nik: true } } },
      orderBy: { enrollId: 'asc' },
    });
  }

  /** Petakan PIN mesin ke karyawan; punch lama dari PIN itu otomatis ditautkan. */
  @Post(':id/mappings')
  @RequirePermission('attendance.device.edit')
  async addMapping(@Param('id') id: string, @Body() dto: CreateMappingDto) {
    await this.get(id);
    const mapping = await this.prisma.employeeDeviceMap.create({
      data: { deviceId: id, enrollId: dto.enrollId, odooEmployeeId: dto.odooEmployeeId },
    });
    const relink = await this.ingest.relinkUnmapped(id, dto.enrollId, dto.odooEmployeeId);
    return { ...mapping, ...relink };
  }

  @Delete(':id/mappings/:mappingId')
  @RequirePermission('attendance.device.edit')
  async removeMapping(@Param('id') id: string, @Param('mappingId') mappingId: string) {
    const m = await this.prisma.employeeDeviceMap.findFirst({ where: { id: mappingId, deviceId: id } });
    if (!m) throw new NotFoundException();
    await this.prisma.employeeDeviceMap.delete({ where: { id: mappingId } });
    return { deleted: true };
  }
}
