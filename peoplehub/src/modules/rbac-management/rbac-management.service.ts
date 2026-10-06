import { Injectable, NotFoundException, ConflictException } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import * as bcrypt from "bcryptjs";

@Injectable()
export class RbacManagementService {
  constructor(private readonly prisma: PrismaService) {}

  async findAllRoles() {
    return this.prisma.role.findMany({
      include: { _count: { select: { users: true, permissions: true } } },
      orderBy: { name: "asc" }
    });
  }

  async findRoleById(id: string) {
    const role = await this.prisma.role.findUnique({
      where: { id },
      include: {
        permissions: { include: { permission: true } },
        users: { select: { user: { select: { id: true, email: true, name: true } } } }
      }
    });
    if (!role) throw new NotFoundException("Role not found");
    return role;
  }

  async createRole(code: string, name: string, description?: string) {
    const existing = await this.prisma.role.findUnique({ where: { code } });
    if (existing) throw new ConflictException("Role code already exists");
    return this.prisma.role.create({ data: { code, name, description } });
  }

  async updateRole(id: string, name: string, description?: string) {
    const role = await this.prisma.role.findUnique({ where: { id } });
    if (!role) throw new NotFoundException("Role not found");
    return this.prisma.role.update({ where: { id }, data: { name, description } });
  }

  async deleteRole(id: string) {
    const role = await this.prisma.role.findUnique({
      where: { id },
      include: { _count: { select: { users: true } } }
    });
    if (!role) throw new NotFoundException("Role not found");
    if (role._count.users > 0) throw new ConflictException("Cannot delete role with users");
    await this.prisma.rolePermission.deleteMany({ where: { roleId: id } });
    return this.prisma.role.delete({ where: { id } });
  }

  async setRolePermissions(id: string, permissionIds: string[]) {
    const role = await this.prisma.role.findUnique({ where: { id } });
    if (!role) throw new NotFoundException("Role not found");
    await this.prisma.rolePermission.deleteMany({ where: { roleId: id } });
    if (permissionIds.length > 0) {
      await this.prisma.rolePermission.createMany({
        data: permissionIds.map((permissionId) => ({ roleId: id, permissionId, canRead: true }))
      });
    }
    return this.findRoleById(id);
  }

  async findAllPermissions() {
    const permissions = await this.prisma.permission.findMany({
      include: { _count: { select: { rolePermissions: true } } },
      orderBy: [{ module: "asc" }, { code: "asc" }]
    });
    const grouped = permissions.reduce((acc, p) => {
      if (!acc[p.module]) acc[p.module] = [];
      acc[p.module].push(p);
      return acc;
    }, {} as Record<string, typeof permissions>);
    return { permissions, grouped };
  }

  async createPermission(code: string, name: string, module: string, description?: string) {
    const existing = await this.prisma.permission.findUnique({ where: { code } });
    if (existing) throw new ConflictException("Permission code already exists");
    return this.prisma.permission.create({ data: { code, name, module, description } });
  }

  async deletePermission(id: string) {
    const permission = await this.prisma.permission.findUnique({
      where: { id },
      include: { _count: { select: { rolePermissions: true } } }
    });
    if (!permission) throw new NotFoundException("Permission not found");
    if (permission._count.rolePermissions > 0) throw new ConflictException("Cannot delete permission assigned to roles");
    return this.prisma.permission.delete({ where: { id } });
  }

  async findAllUsers(search?: string) {
    const where = search ? {
      OR: [
        { email: { contains: search } },
        { name: { contains: search } }
      ]
    } : {};
    return this.prisma.user.findMany({
      where,
      select: {
        id: true, email: true, isActive: true, createdAt: true, lastLoginAt: true,
        roles: { select: { role: { select: { id: true, code: true, name: true } } } }
      },
      orderBy: { createdAt: "desc" }
    });
  }

  async findUserById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true, email: true, isActive: true, createdAt: true, lastLoginAt: true,
        roles: { select: { role: { select: { id: true, code: true, name: true } } } }
      }
    });
    if (!user) throw new NotFoundException("User not found");
    return user;
  }

  async createUser(email: string, password: string, name: string) {
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictException("Email already exists");
    const passwordHash = await bcrypt.hash(password, 10);
    return this.prisma.user.create({
      data: { email, passwordHash, name },
      select: { id: true, email: true, isActive: true, createdAt: true }
    });
  }

  async updateUser(id: string, name: string, password?: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException("User not found");
    const data: { name: string; passwordHash?: string } = { name };
    if (password) data.passwordHash = await bcrypt.hash(password, 10);
    return this.prisma.user.update({
      where: { id },
      data,
      select: { id: true, email: true, isActive: true, updatedAt: true }
    });
  }

  async deleteUser(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException("User not found");
    return this.prisma.user.delete({ where: { id } });
  }

  async assignRoles(userId: string, roleIds: string[]) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException("User not found");
    await this.prisma.userRole.deleteMany({ where: { userId } });
    if (roleIds.length > 0) {
      await this.prisma.userRole.createMany({
        data: roleIds.map((roleId) => ({ userId, roleId }))
      });
    }
    return this.findUserById(userId);
  }

  async findAllMenus() {
    return this.prisma.menu.findMany({
      include: { requiredPermission: { select: { id: true, code: true, name: true } } },
      orderBy: [{ parentId: "asc" }, { sortOrder: "asc" }]
    });
  }

  async getMenuTree() {
    const menus = await this.prisma.menu.findMany({
      include: { requiredPermission: { select: { id: true, code: true, name: true } } },
      orderBy: { sortOrder: "asc" }
    });
    const nodes = new Map(menus.map((m) => [m.id, { ...m, children: [] as typeof menus }]));
    const roots: typeof menus = [];
    for (const m of menus) {
      const node = nodes.get(m.id)!;
      if (m.parentId && nodes.has(m.parentId)) {
        nodes.get(m.parentId)!.children.push(node as never);
      } else if (!m.parentId) {
        roots.push(node as never);
      }
    }
    return roots;
  }

  async createMenu(code: string, label: string, path?: string, icon?: string, sortOrder?: number, parentId?: string, requiredPermissionId?: string) {
    const existing = await this.prisma.menu.findUnique({ where: { code } });
    if (existing) throw new ConflictException("Menu code already exists");
    return this.prisma.menu.create({
      data: { code, label, path, icon, sortOrder: sortOrder ?? 0, parentId, requiredPermissionId }
    });
  }

  async updateMenu(id: string, label: string, path?: string, icon?: string, sortOrder?: number, isActive?: boolean, parentId?: string, requiredPermissionId?: string) {
    const menu = await this.prisma.menu.findUnique({ where: { id } });
    if (!menu) throw new NotFoundException("Menu not found");
    return this.prisma.menu.update({
      where: { id },
      data: { label, path, icon, sortOrder, isActive, parentId, requiredPermissionId }
    });
  }

  async deleteMenu(id: string) {
    const menu = await this.prisma.menu.findUnique({
      where: { id },
      include: { _count: { select: { children: true } } }
    });
    if (!menu) throw new NotFoundException("Menu not found");
    if (menu._count.children > 0) throw new ConflictException("Cannot delete menu with children");
    return this.prisma.menu.delete({ where: { id } });
  }
}