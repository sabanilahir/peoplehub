import type { Metadata } from "next";
import Link from "next/link";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { CalendarManager } from "@/components/calendar-manager";
import { btnGhost, PageHeader } from "@/components/ui";
import { apiFetch, can } from "@/lib/api";
import { qs, todayStr } from "@/lib/format";
import type { CalendarEvent, WorkLocation } from "@/lib/types";

export const metadata: Metadata = { title: "Kalender · PeopleHub" };

export default async function CalendarPage({ searchParams }: PageProps<"/schedule/calendar">) {
  const sp = await searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const thisYear = Number(todayStr().slice(0, 4));
  const yearParam = Number(one(sp.year));
  const year = yearParam >= 2000 && yearParam <= 2100 ? yearParam : thisYear;
  const location = one(sp.location) ?? "";

  const [events, locations, canEdit] = await Promise.all([
    apiFetch<CalendarEvent[]>(`/calendar-events${qs({ from: `${year}-01-01`, to: `${year}-12-31`, workLocationId: location })}`),
    apiFetch<WorkLocation[]>("/work-locations"),
    can("schedule.calendar.edit"),
  ]);

  const href = (y: number) => `/schedule/calendar${qs({ year: y, location })}`;

  return (
    <div className="mx-auto max-w-5xl">
      <PageHeader
        title="Kalender"
        description="Libur nasional, cuti bersama, dinas luar, dan acara lain. Event yang membatalkan hari kerja membuat absensi hari itu dicatat sebagai libur."
        action={
          <div className="flex items-center gap-2">
            <Link href={href(year - 1)} className={btnGhost} aria-label="Tahun sebelumnya">
              <ChevronLeft className="h-4 w-4" aria-hidden />
            </Link>
            <span className="w-16 text-center text-sm font-semibold">{year}</span>
            <Link href={href(year + 1)} className={btnGhost} aria-label="Tahun berikutnya">
              <ChevronRight className="h-4 w-4" aria-hidden />
            </Link>
          </div>
        }
      />
      <CalendarManager events={events} locations={locations} canEdit={canEdit} year={year} location={location} />
    </div>
  );
}
