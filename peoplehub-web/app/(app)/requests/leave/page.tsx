import type { Metadata } from "next";
import { ChevronLeft, ChevronRight } from "lucide-react";
import Link from "next/link";
import { Badge, btnGhost, btnPrimary, Card, EmptyState, inputCls, PageHeader, tdCls, thCls } from "@/components/ui";
import { apiFetch } from "@/lib/api";
import { dateOnly, fmtDate, isDateStr, qs } from "@/lib/format";
import { LEAVE_KIND_LABEL, REQUEST_STATUS_LABEL } from "@/lib/labels";
import type { LeaveItem, Paged, RequestStatus } from "@/lib/types";

export const metadata: Metadata = { title: "Cuti · PeopleHub" };

const TONE: Record<RequestStatus, "green" | "amber" | "red" | "gray"> = {
  APPROVED: "green",
  PENDING: "amber",
  REJECTED: "red",
  CANCELLED: "gray",
};

export default async function LeavePage({ searchParams }: PageProps<"/requests/leave">) {
  const sp = await searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const status = one(sp.status) ?? "";
  const from = isDateStr(one(sp.from)) ? one(sp.from)! : "";
  const to = isDateStr(one(sp.to)) ? one(sp.to)! : "";
  const page = Math.max(1, Number(one(sp.page)) || 1);

  const data = await apiFetch<Paged<LeaveItem>>(`/leave-requests${qs({ status, from, to, page, pageSize: 25 })}`);
  const totalPages = Math.max(1, Math.ceil(data.total / data.pageSize));
  const href = (p: number) => `/requests/leave${qs({ status, from, to, page: p > 1 ? p : undefined })}`;

  return (
    <div className="mx-auto max-w-6xl">
      <PageHeader
        title="Cuti"
        description="Cuti karyawan yang sudah disetujui di Odoo atau sistem sumber. Halaman ini hanya untuk melihat; cuti tidak dibuat atau disetujui di PeopleHub."
      />

      {/* Form GET biasa: bekerja tanpa JavaScript */}
      <form action="/requests/leave" className="mb-4 flex flex-wrap items-end gap-3 rounded-xl border border-border bg-surface p-4">
        <label className="space-y-1 text-xs text-muted">
          Status
          <select name="status" defaultValue={status} className={`${inputCls} block w-40 text-foreground`}>
            <option value="">Semua status</option>
            {Object.entries(REQUEST_STATUS_LABEL).map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className="space-y-1 text-xs text-muted">
          Cuti berakhir sejak
          <input type="date" name="from" defaultValue={from} className={`${inputCls} block w-40 text-foreground`} />
        </label>
        <label className="space-y-1 text-xs text-muted">
          Cuti dimulai sebelum
          <input type="date" name="to" defaultValue={to} className={`${inputCls} block w-40 text-foreground`} />
        </label>
        <button type="submit" className={btnPrimary}>
          Terapkan
        </button>
        {(status || from || to) && (
          <Link href="/requests/leave" className={btnGhost}>
            Reset
          </Link>
        )}
      </form>

      <Card className="overflow-x-auto">
        {data.items.length === 0 ? (
          <EmptyState>
            {status || from || to
              ? "Tidak ada cuti yang cocok dengan filter."
              : "Belum ada data cuti. Cuti masuk lewat jalur inbound dari Odoo atau file sumber."}
          </EmptyState>
        ) : (
          <table className="w-full min-w-[720px]">
            <thead className="border-b border-border">
              <tr>
                <th className={thCls}>Karyawan</th>
                <th className={thCls}>Jenis</th>
                <th className={thCls}>Periode</th>
                <th className={`${thCls} text-right`}>Hari</th>
                <th className={thCls}>Status</th>
                <th className={thCls}>Referensi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {data.items.map((l) => (
                <tr key={l.id}>
                  <td className={tdCls}>
                    <div className="font-medium">{l.employee.name}</div>
                    {l.employee.nik && <div className="text-xs text-muted">{l.employee.nik}</div>}
                  </td>
                  <td className={tdCls}>{LEAVE_KIND_LABEL[l.kind]}</td>
                  <td className={`${tdCls} whitespace-nowrap`}>
                    {dateOnly(l.startDate) === dateOnly(l.endDate)
                      ? fmtDate(l.startDate)
                      : `${fmtDate(l.startDate)} – ${fmtDate(l.endDate)}`}
                  </td>
                  <td className={`${tdCls} text-right`}>{Number(l.days)}</td>
                  <td className={tdCls}>
                    <Badge tone={TONE[l.overallStatus]}>{REQUEST_STATUS_LABEL[l.overallStatus]}</Badge>
                  </td>
                  <td className={`${tdCls} font-mono text-xs text-muted`}>{l.externalRef ?? "–"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>

      <div className="mt-4 flex items-center justify-between text-sm text-muted">
        <span>
          {data.total} cuti · halaman {data.page} dari {totalPages}
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
    </div>
  );
}
