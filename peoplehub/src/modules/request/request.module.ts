import { Module } from '@nestjs/common';
import { LeaveRuleModule } from '../leave-rule/leave-rule.module';
import { LeaveInboundController } from './leave-inbound.controller';
import { LeaveInboundService } from './leave-inbound.service';
import { LeaveController } from './leave.controller';

@Module({
  imports: [LeaveRuleModule],
  controllers: [LeaveController, LeaveInboundController],
  providers: [LeaveInboundService],
  exports: [LeaveInboundService],
})
export class RequestModule {}
