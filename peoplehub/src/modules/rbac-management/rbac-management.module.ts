import { Module } from "@nestjs/common";
import { RbacManagementController } from "./rbac-management.controller";
import { RbacManagementService } from "./rbac-management.service";

@Module({
  controllers: [RbacManagementController],
  providers: [RbacManagementService],
  exports: [RbacManagementService],
})
export class RbacManagementModule {}