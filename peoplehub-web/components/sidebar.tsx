"use client";

import {
  Activity,
  AlarmClock,
  CalendarDays,
  ClipboardCheck,
  Circle,
  Clock,
  Database,
  FileSpreadsheet,
  Fingerprint,
  Inbox,
  List,
  MapPin,
  Menu as MenuIcon,
  Moon,
  Plane,
  Settings,
  Shield,
  ShieldCheck,
  Timer,
  Upload,
  UserCog,
  Users,
  X,
  type LucideIcon,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import type { MenuNode } from "@/lib/api";

const ICONS: Record<string, LucideIcon> = {
  database: Database,
  "map-pin": MapPin,
  users: Users,
  upload: Upload,
  calendar: CalendarDays,
  "calendar-days": CalendarDays,
  clock: Clock,
  inbox: Inbox,
  plane: Plane,
  timer: Timer,
  moon: Moon,
  settings: Settings,
  "alarm-clock": AlarmClock,
  "clipboard-check": ClipboardCheck,
  fingerprint: Fingerprint,
  "file-spreadsheet": FileSpreadsheet,
  activity: Activity,
  shield: Shield,
  "shield-check": ShieldCheck,
  "user-cog": UserCog,
  list: List,
};

function Icon({ name }: { name: string | null }) {
  const Cmp = (name && ICONS[name]) || Circle;
  return <Cmp className="h-4 w-4 shrink-0" aria-hidden />;
}

function NavLink({ node, pathname, onNavigate }: { node: MenuNode; pathname: string; onNavigate: () => void }) {
  const active = pathname === node.path || pathname.startsWith(`${node.path}/`);
  return (
    <Link
      href={node.path!}
      onClick={onNavigate}
      aria-current={active ? "page" : undefined}
      className={`flex items-center gap-2.5 rounded-lg px-3 py-2 text-sm transition ${
        active
          ? "bg-accent-soft font-medium text-accent"
          : "text-muted hover:bg-background hover:text-foreground"
      }`}
    >
      <Icon name={node.icon} />
      {node.label}
    </Link>
  );
}

export function Sidebar({ menu }: { menu: MenuNode[] }) {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const close = () => setOpen(false);

  const nav = (
    <nav aria-label="Menu utama" className="flex-1 space-y-5 overflow-y-auto px-3 py-4">
      <NavLink node={{ id: "home", code: "home", label: "Dasbor", path: "/", icon: null, children: [] }} pathname={pathname} onNavigate={close} />
      {menu.map((node) =>
        node.path ? (
          <NavLink key={node.id} node={node} pathname={pathname} onNavigate={close} />
        ) : (
          <div key={node.id}>
            <p className="mb-1.5 flex items-center gap-2 px-3 text-xs font-semibold uppercase tracking-wide text-muted">
              <Icon name={node.icon} />
              {node.label}
            </p>
            <div className="space-y-0.5">
              {node.children.map((child) => (
                <NavLink key={child.id} node={child} pathname={pathname} onNavigate={close} />
              ))}
            </div>
          </div>
        ),
      )}
    </nav>
  );

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        aria-label="Buka menu"
        className="fixed left-3 top-3 z-30 rounded-lg border border-border bg-surface p-2 lg:hidden"
      >
        <MenuIcon className="h-5 w-5" />
      </button>

      {open && <div className="fixed inset-0 z-30 bg-black/40 lg:hidden" onClick={close} aria-hidden />}

      <aside
        className={`fixed inset-y-0 left-0 z-40 flex w-64 flex-col border-r border-border bg-surface transition-transform lg:static lg:translate-x-0 ${
          open ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        <div className="flex h-14 items-center justify-between border-b border-border px-5">
          <span className="flex items-center gap-2.5 font-semibold tracking-tight">
            <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-accent text-sm font-bold text-accent-foreground">
              P
            </span>
            PeopleHub
          </span>
          <button type="button" onClick={close} aria-label="Tutup menu" className="rounded-md p-1 lg:hidden">
            <X className="h-5 w-5" />
          </button>
        </div>
        {nav}
      </aside>
    </>
  );
}