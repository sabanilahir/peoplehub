import { Module } from '@nestjs/common';
import { CalendarEventController } from './calendar-event.controller';
import { ScheduleController } from './schedule.controller';
import { ScheduleService } from './schedule.service';
import { ShiftController } from './shift.controller';

@Module({
  controllers: [ShiftController, ScheduleController, CalendarEventController],
  providers: [ScheduleService],
  exports: [ScheduleService],
})
export class ScheduleModule {}
