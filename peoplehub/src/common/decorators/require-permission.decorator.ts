import { SetMetadata } from '@nestjs/common';

export const PERMISSION_KEY = 'requiredPermission';
export const RequirePermission = (code: string) => SetMetadata(PERMISSION_KEY, code);
