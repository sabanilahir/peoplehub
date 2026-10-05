import { Module } from '@nestjs/common';
import { ProcessMonitorController } from './process-monitor.controller';
import { ProcessMonitorService } from './process-monitor.service';

@Module({
  controllers: [ProcessMonitorController],
  providers: [ProcessMonitorService],
  exports: [ProcessMonitorService],
})
export class ProcessMonitorModule {}
