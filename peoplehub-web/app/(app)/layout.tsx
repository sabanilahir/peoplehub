import { LogOut } from "lucide-react";
import { Sidebar } from "@/components/sidebar";
import { apiFetch, getMe, type MenuNode } from "@/lib/api";
import { logout } from "./actions";

export default async function AppLayout({ children }: LayoutProps<"/">) {
  const [me, menu] = await Promise.all([
    getMe(),
    apiFetch<MenuNode[]>("/auth/menu"),
  ]);

  return (
    <div className="flex min-h-screen flex-1">
      <Sidebar menu={menu} />
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex h-14 items-center justify-end gap-4 border-b border-border bg-surface px-4 pl-14 sm:px-6 lg:pl-6">
          <span className="truncate text-sm text-muted" title={me.email}>
            {me.email}
          </span>
          <form action={logout}>
            <button
              type="submit"
              className="flex items-center gap-1.5 rounded-lg border border-border px-3 py-1.5 text-sm transition hover:bg-background"
            >
              <LogOut className="h-4 w-4" aria-hidden />
              Keluar
            </button>
          </form>
        </header>
        <main className="flex-1 p-4 sm:p-6">{children}</main>
      </div>
    </div>
  );
}
