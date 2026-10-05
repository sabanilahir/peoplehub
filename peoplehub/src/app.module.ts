import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { RbacGuard } from './common/guards/rbac.guard';
import { RequestModule } from './modules/request/request.module';
import { AttendanceModule } from './modules/attendance/attendance.module';
import { AuthModule } from './modules/auth/auth.module';
import { EmployeeModule } from './modules/employee/employee.module';
import { OvertimeModule } from './modules/overtime/overtime.module';
import { ProcessMonitorModule } from './modules/process-monitor/process-monitor.module';
import { LeaveRuleModule } from './modules/leave-rule/leave-rule.module';
import { TimeEntryModule } from './modules/time-entry/time-entry.module';
import { ScheduleModule } from './modules/schedule/schedule.module';
import { RbacModule } from './modules/rbac/rbac.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    RbacModule,
    AuthModule,
    EmployeeModule,
    AttendanceModule,
    ScheduleModule,
    RequestModule,
    TimeEntryModule,
    LeaveRuleModule,
    ProcessMonitorModule,
    OvertimeModule,
  ],
  providers: [
    // Urutan penting: autentikasi dulu, baru otorisasi
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RbacGuard },
  ],
})
export class AppModule {}
