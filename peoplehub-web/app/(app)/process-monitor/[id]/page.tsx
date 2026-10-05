import type { Metadata } from "next";
import { ArrowLeft } from "lucide-react";
import Link from "next/link";
import { AutoRefresh } from "@/components/auto-refresh";
import { isActive, ProgressBar, StatusBadge } from "@/components/process-status";
import { Card, PageHeader, tdCls, thCls } from "@/components/ui";
import { apiFetch } from "@/lib/api";
import { fmtClock, fmtDateTime, fmtDuration } from "@/lib/format";
import { PROCESS_TYPE_LABEL } from "@/lib/labels";
import type { ProcessDetail, ProcessRowError } from "@/lib/types";

export const metadata: Metadata = { title: "Detail Proses · PeopleHub" };

const LEVEL_CLS = {
  INFO: "text-muted",
  WARN: "text-amber-700 dark:text-amber-400",
  ERROR: "font-medium text-danger",
} as const;

export default async function ProcessDetailPage({ params }: PageProps<"/process-monitor/[id]">) {
  const { id } = await params;
  const p = await apiFetch<ProcessDetail>(`/process-monitor/${id}`);
  const errors = p.errorRows > 0 && !isActive(p.status) ? await apiFetch<ProcessRowError[]>(`/process-monitor/${id}/errors`) : [];
  const active = isActive(p.status);

  const stats: [string, string][] = [
    ["Total baris", String(p.totalRows)],
    ["Berhasil", String(p.successRows)],
    ["Gagal", String(p.errorRows)],
    ["Durasi", fmtDuration(p.durationSeconds)],
    ["Mulai", fmtDateTime(p.startedAt ?? p.createdAt)],
    ["Selesai", p.finishedAt ? fmtDateTime(p.finishedAt) : "–"],
    ["Diunggah oleh", p.uploadedBy ?? "–"],
  ];

  return (
    <div className="mx-auto max-w-5xl space-y-6">
      <Link href="/process-monitor" className="inline-flex items-center gap-1.5 text-sm text-muted hover:text-foreground">
        <ArrowLeft className="h-4 w-4" aria-hidden /> Semua proses
      </Link>

      <PageHeader
        title={PROCESS_TYPE_LABEL[p.fileType] ?? p.fileType}
        description={p.fileName}
        action={<AutoRefresh active={active} />}
      />

      <Card className="p-5">
        <div className="mb-4 flex flex-wrap items-center gap-4">
          <StatusBadge status={p.status} />
          <ProgressBar value={p.progress} status={p.status} />
        </div>
        <dl className="grid gap-x-6 gap-y-3 sm:grid-cols-3 lg:grid-cols-4">
          {stats.map(([k, v]) => (
            <div key={k}>
              <dt className="text-xs text-muted">{k}</dt>
              <dd className="text-sm font-medium tabular-nums">{v}</dd>
            </div>
          ))}
        </dl>
      </Card>

      <section aria-labelledby="log">
        <h2 id="log" className="mb-3 text-sm font-semibold text-muted">
          Log proses
        </h2>
        <Card className="max-h-96 overflow-auto p-4">
          <ol className="space-y-1.5 font-mono text-xs leading-relaxed">
            {p.logs.map((l) => (
              <li key={l.id} className="flex gap-3">
                <time dateTime={l.createdAt} className="shrink-0 tabular-nums text-muted">
                  {fmtClock(l.createdAt)}
                </time>
                <span className={`w-12 shrink-0 ${LEVEL_CLS[l.level]}`}>{l.level}</span>
                <span className={LEVEL_CLS[l.level]}>{l.message}</span>
              </li>
            ))}
            {active && <li className="text-muted">…menunggu langkah berikutnya</li>}
          </ol>
        </Card>
      </section>

      {errors.length > 0 && (
        <section aria-labelledby="error">
          <h2 id="error" className="mb-3 text-sm font-semibold text-muted">
            Baris yang gagal ({p.errorRows})
          </h2>
          <Card className="overflow-x-auto">
            <table className="w-full min-w-[560px]">
              <thead className="border-b border-border">
                <tr>
                  <th className={thCls}>Baris</th>
                  <th className={thCls}>Masalah</th>
                  <th className={thCls}>Isi baris</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {errors.map((e) => (
                  <tr key={e.rowNumber}>
                    <td className={`${tdCls} font-mono`}>{e.rowNumber}</td>
                    <td className={tdCls}>{e.message}</td>
                    <td className={`${tdCls} max-w-72 truncate font-mono text-xs text-muted`} title={e.rawLine}>
                      {e.rawLine}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Card>
          <p className="mt-2 text-xs text-muted">
            Baris yang valid sudah tersimpan. Perbaiki baris di atas lalu unggah ulang file yang sama; baris yang sudah berhasil diperbarui, bukan digandakan.
          </p>
        </section>
      )}
    </div>
  );
}
