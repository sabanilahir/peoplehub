import { Module } from '@nestjs/common';
import { LeaveRuleController } from './leave-rule.controller';
import { LeaveRuleService } from './leave-rule.service';

@Module({
  controllers: [LeaveRuleController],
  providers: [LeaveRuleService],
  exports: [LeaveRuleService],
})
export class LeaveRuleModule {}
