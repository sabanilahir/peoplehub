import type { Metadata } from "next";
import Link from "next/link";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { RosterGrid } from "@/components/roster-grid";
import { btnGhost, Card, EmptyState, PageHeader } from "@/components/ui";
import { apiFetch, can } from "@/lib/api";
import { addDaysStr, fmtDate, isDateStr, mondayOf, qs, todayStr } from "@/lib/format";
import type { Employee, Paged, Schedule, Shift, WorkLocation } from "@/lib/types";

export const metadata: Metadata = { title: "Jadwal Karyawan · PeopleHub" };

export default async function RosterPage({ searchParams }: PageProps<"/schedule/roster">) {
  const sp = await searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const weekParam = one(sp.week);
  const week = mondayOf(isDateStr(weekParam) ? weekParam : todayStr());
  const weekEnd = addDaysStr(week, 6);

  const [locations, shifts, canEdit] = await Promise.all([
    apiFetch<WorkLocation[]>("/work-locations"),
    apiFetch<Shift[]>("/shifts"),
    can("schedule.roster.edit"),
  ]);
  const active = locations.filter((l) => l.isActive);
  const selected = active.find((l) => l.id === one(sp.location)) ?? active[0];

  const header = (
    <PageHeader
      title="Jadwal Karyawan"
      description="Atur shift per karyawan per hari. Perubahan langsung tersimpan; hitung ulang absensi agar berlaku pada rekap."
    />
  );

  if (!selected) {
    return (
      <div className="mx-auto max-w-5xl">
        {header}
        <Card>
          <EmptyState>Buat lokasi kerja dan karyawan dulu di menu Master Data.</EmptyState>
        </Card>
      </div>
    );
  }

  const [employees, schedules] = await Promise.all([
    apiFetch<Paged<Employee>>(`/employees${qs({ workLocationId: selected.id, pageSize: 200 })}`),
    apiFetch<Schedule[]>(`/schedules${qs({ from: week, to: weekEnd, workLocationId: selected.id })}`),
  ]);
  const people = employees.items.filter((e) => e.isActive);

  const href = (w: string, loc = selected.id) => `/schedule/roster${qs({ location: loc, week: w })}`;

  return (
    <div className="mx-auto max-w-7xl">
      {header}

      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <nav aria-label="Pilih lokasi" className="flex flex-wrap gap-2">
          {active.map((l) => (
            <Link
              key={l.id}
              href={href(week, l.id)}
              aria-current={l.id === selected.id ? "page" : undefined}
              className={`rounded-full border px-3.5 py-1.5 text-sm transition ${
                l.id === selected.id ? "border-accent bg-accent-soft font-medium text-accent" : "border-border hover:bg-surface"
              }`}
            >
              {l.name}
            </Link>
          ))}
        </nav>
        <div className="flex items-center gap-2">
          <Link href={href(addDaysStr(week, -7))} className={btnGhost} aria-label="Minggu sebelumnya">
            <ChevronLeft className="h-4 w-4" aria-hidden />
          </Link>
          <span className="min-w-52 text-center text-sm font-medium">
            {fmtDate(week)} – {fmtDate(weekEnd)}
          </span>
          <Link href={href(addDaysStr(week, 7))} className={btnGhost} aria-label="Minggu berikutnya">
            <ChevronRight className="h-4 w-4" aria-hidden />
          </Link>
          <Link href={href(mondayOf(todayStr()))} className={btnGhost}>
            Minggu ini
          </Link>
        </div>
      </div>

      <RosterGrid
        key={`${selected.id}-${week}`}
        week={week}
        employees={people.map((e) => ({ id: e.id, name: e.name, nik: e.nik }))}
        shifts={shifts.filter((s) => s.isActive).map((s) => ({ id: s.id, code: s.code, name: s.name, startTime: s.startTime }))}
        schedules={schedules}
        canEdit={canEdit}
      />
    </div>
  );
}
