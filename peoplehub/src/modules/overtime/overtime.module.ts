import { Module } from '@nestjs/common';
import { OvertimeRequestController } from './overtime-request.controller';
import { OvertimeRuleController } from './overtime-rule.controller';

@Module({
  controllers: [OvertimeRuleController, OvertimeRequestController],
})
export class OvertimeModule {}
