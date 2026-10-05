import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export const SUPER_ADMIN_ROLE = 'SUPER_ADMIN';

@Injectable()
export class PermissionsService {
  // ASSUMPTION: cache in-memory dengan TTL pendek (tanpa Redis); cukup untuk satu instance.
  private cache = new Map<string, { at: number; perms: Set<string> }>();
  private readonly ttlMs = 30_000;

  constructor(private readonly prisma: PrismaService) {}

  invalidate(userId?: string) {
    if (userId) this.cache.delete(userId);
    else this.cache.clear();
  }

  /** Prioritas: explicit deny > explicit allow > role. Super admin = semua permission. */
  async getEffective(userId: string): Promise<Set<string>> {
    const hit = this.cache.get(userId);
    if (hit && Date.now() - hit.at < this.ttlMs) return hit.perms;

    const now = new Date();
    const [userRoles, overrides] = await Promise.all([
      this.prisma.userRole.findMany({
        where: { userId },
        include: { role: { include: { permissions: { include: { permission: true } } } } },
      }),
      this.prisma.userPermissionOverride.findMany({
        where: { userId, OR: [{ expiresAt: null }, { expiresAt: { gt: now } }] },
        include: { permission: true },
      }),
    ]);

    let perms: Set<string>;
    if (userRoles.some((ur) => ur.role.code === SUPER_ADMIN_ROLE)) {
      perms = new Set((await this.prisma.permission.findMany({ select: { code: true } })).map((p) => p.code));
    } else {
      perms = new Set(
        userRoles.flatMap((ur) => ur.role.permissions.filter((rp) => rp.canRead).map((rp) => rp.permission.code)),
      );
    }
    for (const o of overrides) if (o.isAllowed) perms.add(o.permission.code);
    for (const o of overrides) if (!o.isAllowed) perms.delete(o.permission.code);

    this.cache.set(userId, { at: Date.now(), perms });
    return perms;
  }
}
