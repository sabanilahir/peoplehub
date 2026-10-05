import { Module } from '@nestjs/common';
import { EmployeeController } from './employee.controller';
import { WorkLocationController } from './work-location.controller';

@Module({
  controllers: [WorkLocationController, EmployeeController],
})
export class EmployeeModule {}
