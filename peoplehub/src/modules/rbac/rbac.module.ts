import { Global, Module } from '@nestjs/common';
import { MenuService } from './menu.service';
import { PermissionsService } from './permissions.service';

@Global()
@Module({
  providers: [PermissionsService, MenuService],
  exports: [PermissionsService, MenuService],
})
export class RbacModule {}
