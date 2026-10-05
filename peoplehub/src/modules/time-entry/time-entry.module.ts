import { Module } from '@nestjs/common';
import { ProcessMonitorModule } from '../process-monitor/process-monitor.module';
import { TimeEntryController } from './time-entry.controller';
import { TimeEntryService } from './time-entry.service';

@Module({
  imports: [ProcessMonitorModule],
  controllers: [TimeEntryController],
  providers: [TimeEntryService],
  exports: [TimeEntryService],
})
export class TimeEntryModule {}
