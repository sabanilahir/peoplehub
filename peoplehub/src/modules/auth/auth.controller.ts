import { Body, Controller, Get, Post } from '@nestjs/common';
import { IsString, MinLength } from 'class-validator';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { MenuService } from '../rbac/menu.service';
import { PermissionsService } from '../rbac/permissions.service';
import { AuthService } from './auth.service';

class LoginDto {
  /** Email atau username (disimpan di kolom User.email). */
  @IsString() @MinLength(1) email: string;
  @IsString() @MinLength(1) password: string;
}

@Controller('auth')
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    private readonly menus: MenuService,
    private readonly permissions: PermissionsService,
  ) {}

  @Public()
  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto.email, dto.password);
  }

  @Get('me')
  async me(@CurrentUser() user: AuthUser) {
    return { ...user, permissions: [...(await this.permissions.getEffective(user.id))] };
  }

  @Get('menu')
  menu(@CurrentUser() user: AuthUser) {
    return this.menus.buildTree(user.id);
  }
}
