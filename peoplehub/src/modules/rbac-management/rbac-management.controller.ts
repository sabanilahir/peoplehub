import { Controller, Get, Post, Patch, Delete, Body, Param, Query, ParseUUIDPipe } from "@nestjs/common";
import { RbacManagementService } from "./rbac-management.service";

@Controller("rbac")
export class RbacManagementController {
  constructor(private readonly service: RbacManagementService) {}

  @Get("roles")
  findAllRoles() { return this.service.findAllRoles(); }

  @Get("roles/:id")
  findRoleById(@Param("id", ParseUUIDPipe) id: string) { return this.service.findRoleById(id); }

  @Post("roles")
  createRole(@Body() body: { code: string; name: string; description?: string }) {
    return this.service.createRole(body.code, body.name, body.description);
  }

  @Patch("roles/:id")
  updateRole(@Param("id", ParseUUIDPipe) id: string, @Body() body: { name: string; description?: string }) {
    return this.service.updateRole(id, body.name, body.description);
  }

  @Delete("roles/:id")
  async deleteRole(@Param("id", ParseUUIDPipe) id: string) {
    await this.service.deleteRole(id);
    return { success: true };
  }

  @Post("roles/:id/permissions")
  setRolePermissions(@Param("id", ParseUUIDPipe) id: string, @Body() body: { permissionIds: string[] }) {
    return this.service.setRolePermissions(id, body.permissionIds);
  }

  @Get("permissions")
  findAllPermissions() { return this.service.findAllPermissions(); }

  @Post("permissions")
  createPermission(@Body() body: { code: string; name: string; module: string; description?: string }) {
    return this.service.createPermission(body.code, body.name, body.module, body.description);
  }

  @Delete("permissions/:id")
  async deletePermission(@Param("id", ParseUUIDPipe) id: string) {
    await this.service.deletePermission(id);
    return { success: true };
  }

  @Get("users")
  findAllUsers(@Query("search") search?: string) { return this.service.findAllUsers(search); }

  @Get("users/:id")
  findUserById(@Param("id", ParseUUIDPipe) id: string) { return this.service.findUserById(id); }

  @Post("users")
  createUser(@Body() body: { email: string; password: string; name: string }) {
    return this.service.createUser(body.email, body.password, body.name);
  }

  @Patch("users/:id")
  updateUser(@Param("id", ParseUUIDPipe) id: string, @Body() body: { name: string; password?: string }) {
    return this.service.updateUser(id, body.name, body.password);
  }

  @Delete("users/:id")
  async deleteUser(@Param("id", ParseUUIDPipe) id: string) {
    await this.service.deleteUser(id);
    return { success: true };
  }

  @Post("users/:id/roles")
  assignRoles(@Param("id", ParseUUIDPipe) id: string, @Body() body: { roleIds: string[] }) {
    return this.service.assignRoles(id, body.roleIds);
  }

  @Get("menus")
  findAllMenus() { return this.service.findAllMenus(); }

  @Get("menus/tree")
  getMenuTree() { return this.service.getMenuTree(); }

  @Post("menus")
  createMenu(@Body() body: { code: string; label: string; path?: string; icon?: string; sortOrder?: number; parentId?: string; requiredPermissionId?: string }) {
    return this.service.createMenu(body.code, body.label, body.path, body.icon, body.sortOrder, body.parentId, body.requiredPermissionId);
  }

  @Patch("menus/:id")
  updateMenu(@Param("id", ParseUUIDPipe) id: string, @Body() body: { label?: string; path?: string; icon?: string; sortOrder?: number; isActive?: boolean; parentId?: string; requiredPermissionId?: string }) {
    return this.service.updateMenu(id, body.label!, body.path, body.icon, body.sortOrder, body.isActive, body.parentId, body.requiredPermissionId);
  }

  @Delete("menus/:id")
  async deleteMenu(@Param("id", ParseUUIDPipe) id: string) {
    await this.service.deleteMenu(id);
    return { success: true };
  }
}