import { Module } from '@nestjs/common';
import { PunchApiKeyGuard } from '../../common/guards/api-key.guard';
import { AttendanceDailyController } from './attendance-daily.controller';
import { AttendanceProcessorService } from './attendance-processor.service';
import { AttendanceRuleController } from './attendance-rule.controller';
import { DeviceController } from './device.controller';
import { PunchInboundController } from './punch-inbound.controller';
import { PunchIngestService } from './punch-ingest.service';

@Module({
  controllers: [AttendanceRuleController, AttendanceDailyController, DeviceController, PunchInboundController],
  providers: [AttendanceProcessorService, PunchIngestService, PunchApiKeyGuard],
  exports: [AttendanceProcessorService],
})
export class AttendanceModule {}
