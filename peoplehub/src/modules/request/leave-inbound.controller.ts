import { Body, Controller, Post } from '@nestjs/common';
import { RequirePermission } from '../../common/decorators/require-permission.decorator';
import { InboundLeaveDto } from './leave-inbound.dto';
import { LeaveInboundService } from './leave-inbound.service';

@Controller('inbound/leave-requests')
export class LeaveInboundController {
  constructor(private readonly inbound: LeaveInboundService) {}

  /** Terima cuti (approved) dari sistem asal. Baris gagal dilaporkan tanpa menggagalkan batch. */
  @Post()
  @RequirePermission('inbound.leave.create')
  receive(@Body() dto: InboundLeaveDto) {
    return this.inbound.upsertMany(dto.items, 'IMPORT');
  }
}
