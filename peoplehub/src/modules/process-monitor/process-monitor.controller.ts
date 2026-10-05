import { Controller, Get, Param, Query } from '@nestjs/common';
import { ImportFileType, ImportStatus } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, Max, Min } from 'class-validator';
import { RequirePermission } from '../../common/decorators/require-permission.decorator';
import { ProcessMonitorService } from './process-monitor.service';

class ListQuery {
  @IsOptional() @IsEnum(ImportStatus) status?: ImportStatus;
  @IsOptional() @IsEnum(ImportFileType) fileType?: ImportFileType;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100) pageSize?: number;
}

@Controller('process-monitor')
export class ProcessMonitorController {
  constructor(private readonly service: ProcessMonitorService) {}

  @Get()
  @RequirePermission('process.monitor.read')
  list(@Query() q: ListQuery) {
    return this.service.list(q);
  }

  @Get(':id')
  @RequirePermission('process.monitor.read')
  get(@Param('id') id: string) {
    return this.service.get(id);
  }

  @Get(':id/errors')
  @RequirePermission('process.monitor.read')
  errors(@Param('id') id: string) {
    return this.service.errors(id);
  }
}
