import type { Metadata } from "next";
import { ChevronLeft, ChevronRight } from "lucide-react";
import Link from "next/link";
import { AutoRefresh } from "@/components/auto-refresh";
import { ProgressBar, StatusBadge } from "@/components/process-status";
import { btnGhost, btnPrimary, Card, EmptyState, inputCls, PageHeader, tdCls, thCls } from "@/components/ui";
import { apiFetch } from "@/lib/api";
import { fmtDateTime, fmtDuration, qs } from "@/lib/format";
import { PROCESS_STATUS_LABEL, PROCESS_TYPE_LABEL } from "@/lib/labels";
import type { Paged, ProcessItem } from "@/lib/types";

export const metadata: Metadata = { title: "Process Monitor · PeopleHub" };

export default async function ProcessMonitorPage({ searchParams }: PageProps<"/process-monitor">) {
  const sp = await searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const status = one(sp.status) ?? "";
  const page = Math.max(1, Number(one(sp.page)) || 1);

  const data = await apiFetch<Paged<ProcessItem> & { activeCount: number }>(`/process-monitor${qs({ status, page, pageSize: 25 })}`);
  const totalPages = Math.max(1, Math.ceil(data.total / data.pageSize));
  const href = (p: number) => `/process-monitor${qs({ status, page: p > 1 ? p : undefined })}`;

  return (
    <div className="mx-auto max-w-6xl">
      <PageHeader
        title="Process Monitor"
        description="Pantau proses impor file: status, kemajuan, durasi, dan log setiap proses."
        action={<AutoRefresh active={data.activeCount > 0} />}
      />

      <form action="/process-monitor" className="mb-4 flex flex-wrap items-end gap-3">
        <label className="space-y-1 text-xs text-muted">
          Status
          <select name="status" defaultValue={status} className={`${inputCls} block w-48 text-foreground`}>
            <option value="">Semua status</option>
            {Object.entries(PROCESS_STATUS_LABEL).map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <button type="submit" className={btnPrimary}>
          Terapkan
        </button>
        {status && (
          <Link href="/process-monitor" className={btnGhost}>
            Reset
          </Link>
        )}
      </form>

      <Card className="overflow-x-auto">
        {data.items.length === 0 ? (
          <EmptyState>
            {status ? "Tidak ada proses dengan status itu." : "Belum ada proses. Unggah file dari halaman Time Entries untuk memulai."}
          </EmptyState>
        ) : (
          <table className="w-full min-w-[880px]">
            <thead className="border-b border-border">
              <tr>
                <th className={thCls}>Mulai</th>
                <th className={thCls}>Proses</th>
                <th className={thCls}>File</th>
                <th className={thCls}>Status</th>
                <th className={thCls}>Kemajuan</th>
                <th className={`${thCls} text-right`}>Berhasil / Gagal</th>
                <th className={`${thCls} text-right`}>Durasi</th>
                <th className={thCls}>Oleh</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {data.items.map((p) => (
                <tr key={p.id} className="transition hover:bg-background">
                  <td className={`${tdCls} whitespace-nowrap`}>
                    <Link href={`/process-monitor/${p.id}`} className="font-medium text-accent hover:underline">
                      {fmtDateTime(p.startedAt ?? p.createdAt)}
                    </Link>
                  </td>
                  <td className={tdCls}>{PROCESS_TYPE_LABEL[p.fileType] ?? p.fileType}</td>
                  <td className={`${tdCls} max-w-52 truncate`} title={p.fileName}>
                    {p.fileName}
                  </td>
                  <td className={tdCls}>
                    <StatusBadge status={p.status} />
                  </td>
                  <td className={tdCls}>
                    <ProgressBar value={p.progress} status={p.status} />
                  </td>
                  <td className={`${tdCls} whitespace-nowrap text-right tabular-nums`}>
                    {p.successRows} / <span className={p.errorRows > 0 ? "font-medium text-danger" : ""}>{p.errorRows}</span>
                    <span className="text-muted"> dari {p.totalRows}</span>
                  </td>
                  <td className={`${tdCls} whitespace-nowrap text-right tabular-nums`}>{fmtDuration(p.durationSeconds)}</td>
                  <td className={`${tdCls} text-muted`}>{p.uploadedBy ?? "–"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>

      <div className="mt-4 flex items-center justify-between text-sm text-muted">
        <span>
          {data.total} proses · halaman {data.page} dari {totalPages}
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
