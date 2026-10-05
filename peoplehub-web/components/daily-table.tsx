import { ChevronLeft, ChevronRight } from "lucide-react";
import Link from "next/link";
import { fmtDate, fmtTime, qs } from "@/lib/format";
import { STATUS_LABEL } from "@/lib/labels";
import type { AttendanceStatus, DailyItem, Paged } from "@/lib/types";
import { Badge, btnGhost, Card, EmptyState, tdCls, thCls } from "./ui";

const TONE: Record<AttendanceStatus, "green" | "amber" | "red" | "blue" | "gray" | "orange"> = {
  PRESENT: "green",
  LATE: "amber",
  ABSENT: "red",
  ON_LEAVE: "blue",
  OFFDAY: "gray",
  HOLIDAY: "gray",
  INCOMPLETE: "orange",
};

export function DailyTable({
  data,
  params,
}: {
  data: Paged<DailyItem>;
  params: { from: string; to: string; location: string; status: string; late: boolean };
}) {
  const totalPages = Math.max(1, Math.ceil(data.total / data.pageSize));
  const href = (p: number) =>
    `/attendance/daily${qs({ ...params, late: params.late ? 1 : undefined, page: p > 1 ? p : undefined })}`;

  return (
    <>
      <Card className="overflow-x-auto">
        {data.items.length === 0 ? (
          <EmptyState>
            Tidak ada data pada rentang ini. Pastikan jadwal sudah disusun, punch sudah masuk, lalu klik “Hitung ulang”.
          </EmptyState>
        ) : (
          <table className="w-full min-w-[720px]">
            <thead className="border-b border-border">
              <tr>
                <th className={thCls}>Tanggal</th>
                <th className={thCls}>Karyawan</th>
                <th className={thCls}>Lokasi</th>
                <th className={thCls}>Status</th>
                <th className={thCls}>Masuk</th>
                <th className={thCls}>Pulang</th>
                <th className={`${thCls} text-right`}>Terlambat</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {data.items.map((d) => {
                const tz = d.employee.workLocation.timezone;
                return (
                  <tr key={d.id}>
                    <td className={`${tdCls} whitespace-nowrap`}>{fmtDate(d.workDate)}</td>
                    <td className={tdCls}>
                      <div className="font-medium">{d.employee.name}</div>
                      {d.employee.nik && <div className="text-xs text-muted">{d.employee.nik}</div>}
                    </td>
                    <td className={tdCls}>{d.employee.workLocation.name}</td>
                    <td className={tdCls}>
                      <Badge tone={TONE[d.status]}>{STATUS_LABEL[d.status]}</Badge>
                    </td>
                    <td className={`${tdCls} font-mono`}>{fmtTime(d.clockIn, tz)}</td>
                    <td className={`${tdCls} font-mono`}>{fmtTime(d.clockOut, tz)}</td>
                    <td className={`${tdCls} text-right`}>
                      {d.isLate ? (
                        <span className="font-medium text-amber-700 dark:text-amber-400">{d.lateMinutes} menit</span>
                      ) : d.lateMinutes > 0 ? (
                        <span className="text-muted" title="Dalam toleransi">
                          {d.lateMinutes} menit
                        </span>
                      ) : (
                        <span className="text-muted">–</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </Card>

      <div className="mt-4 flex items-center justify-between text-sm text-muted">
        <span>
          {data.total} baris · halaman {data.page} dari {totalPages} · jam ditampilkan dalam zona waktu lokasi
        </span>
        <div className="flex gap-2">
          {data.page > 1 && (
            <Link href={href(data.page - 1)} className={btnGhost}>
              <ChevronLeft className="h-4 w-4" aria-hidden /> Sebelumnya
            </Link>
          )}
          {data.page < totalPages && (
            <Link href={href(data.page + 1)} className={btnGhost}>
              Berikutnya <ChevronRight className="h-4 w-4" aria-hidden />
            </Link>
          )}
        </div>
      </div>
    </>
  );
}
