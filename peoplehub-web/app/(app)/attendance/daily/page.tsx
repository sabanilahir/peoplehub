import type { Metadata } from "next";
import { DailyFilters } from "@/components/daily-filters";
import { DailyTable } from "@/components/daily-table";
import { PageHeader } from "@/components/ui";
import { apiFetch, can } from "@/lib/api";
import { addDaysStr, isDateStr, qs, todayStr } from "@/lib/format";
import type { DailyItem, Paged, WorkLocation } from "@/lib/types";

export const metadata: Metadata = { title: "Rekap Absensi · PeopleHub" };

export default async function DailyPage({ searchParams }: PageProps<"/attendance/daily">) {
  const sp = await searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);

  const today = todayStr();
  const from = isDateStr(one(sp.from)) ? one(sp.from)! : addDaysStr(today, -6);
  const to = isDateStr(one(sp.to)) ? one(sp.to)! : today;
  const location = one(sp.location) ?? "";
  const status = one(sp.status) ?? "";
  const onlyLate = one(sp.late) === "1";
  const page = Math.max(1, Number(one(sp.page)) || 1);

  const base = { from, to, workLocationId: location };
  const [data, locations, canRecompute, lateCount, absentCount] = await Promise.all([
    apiFetch<Paged<DailyItem>>(`/attendance/daily${qs({ ...base, status, onlyLate: onlyLate || undefined, page, pageSize: 50 })}`),
    apiFetch<WorkLocation[]>("/work-locations"),
    can("attendance.log.edit"),
    apiFetch<Paged<DailyItem>>(`/attendance/daily${qs({ ...base, onlyLate: true, pageSize: 1 })}`),
    apiFetch<Paged<DailyItem>>(`/attendance/daily${qs({ ...base, status: "ABSENT", pageSize: 1 })}`),
  ]);

  return (
    <div className="mx-auto max-w-6xl">
      <PageHeader
        title="Rekap Absensi"
        description="Kehadiran harian per karyawan, termasuk keterlambatan dalam menit dari jam mulai shift."
      />
      <DailyFilters
        values={{ from, to, location, status, late: onlyLate }}
        locations={locations.filter((l) => l.isActive)}
        canRecompute={canRecompute}
        summary={{ late: lateCount.total, absent: absentCount.total }}
      />
      <DailyTable data={data} params={{ from, to, location, status, late: onlyLate }} />
    </div>
  );
}
