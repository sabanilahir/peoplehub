import Link from "next/link";
import { apiFetch, getMe, type MenuNode } from "@/lib/api";

export default async function DashboardPage() {
  const [me, menu] = await Promise.all([
    getMe(),
    apiFetch<MenuNode[]>("/auth/menu"),
  ]);
  const links = menu.flatMap((n) =>
    n.path ? [{ ...n, group: null as string | null }] : n.children.map((c) => ({ ...c, group: n.label })),
  );

  return (
    <div className="mx-auto max-w-4xl space-y-8">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Selamat datang</h1>
        <p className="mt-1 text-sm text-muted">
          Masuk sebagai {me.email} · {me.permissions.length} hak akses aktif
        </p>
      </div>

      <section aria-labelledby="pintasan">
        <h2 id="pintasan" className="mb-3 text-sm font-semibold text-muted">
          Pintasan
        </h2>
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {links.map((l) => (
            <Link
              key={l.id}
              href={l.path!}
              className="rounded-xl border border-border bg-surface px-4 py-3.5 transition hover:border-accent"
            >
              {l.group && <span className="block text-xs text-muted">{l.group}</span>}
              <span className="text-sm font-medium">{l.label}</span>
            </Link>
          ))}
        </div>
      </section>
    </div>
  );
}
