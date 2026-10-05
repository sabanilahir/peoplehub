import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { PermissionsService } from './permissions.service';

export interface MenuNode {
  id: string;
  code: string;
  label: string;
  path: string | null;
  icon: string | null;
  children: MenuNode[];
}

@Injectable()
export class MenuService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly permissions: PermissionsService,
  ) {}

  /** Menu tree yang boleh dilihat user. Parent tanpa anak yang lolos dan tanpa path dibuang. */
  async buildTree(userId: string): Promise<MenuNode[]> {
    const [menus, effective] = await Promise.all([
      this.prisma.menu.findMany({
        where: { isActive: true },
        include: { requiredPermission: true },
        orderBy: { sortOrder: 'asc' },
      }),
      this.permissions.getEffective(userId),
    ]);

    const allowed = menus.filter((m) => !m.requiredPermission || effective.has(m.requiredPermission.code));
    const nodes = new Map<string, MenuNode>(
      allowed.map((m) => [m.id, { id: m.id, code: m.code, label: m.label, path: m.path, icon: m.icon, children: [] }]),
    );
    const roots: MenuNode[] = [];
    for (const m of allowed) {
      const node = nodes.get(m.id)!;
      const parent = m.parentId ? nodes.get(m.parentId) : undefined;
      if (parent) parent.children.push(node);
      else if (!m.parentId) roots.push(node);
    }
    const prune = (list: MenuNode[]): MenuNode[] =>
      list
        .map((n) => ({ ...n, children: prune(n.children) }))
        .filter((n) => n.path || n.children.length > 0);
    return prune(roots);
  }
}
