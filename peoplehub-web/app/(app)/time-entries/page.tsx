import type { Metadata } from "next";
import { ChevronLeft, ChevronRight } from "lucide-react";
import Link from "next/link";
import { TimeEntriesActions } from "@/components/time-entries-actions";
import { Badge, btnGhost, btnPrimary, Card, EmptyState, inputCls, PageHeader, tdCls, thCls } from "@/components/ui";
import { apiFetch, can } from "@/lib/api";
import { dateOnly, fmtDate, fmtHours, fmtTime, qs } from "@/lib/format";
import type { Paged, TimeEntryItem, WorkLocation } from "@/lib/types";

export const metadata: Metadata = { title: "Time Entries · PeopleHub" };

export default async function TimeEntriesPage({ searchParams }: PageProps<"/time-entries">) {
  const sp = await searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const periodParam = one(sp.period) ?? "";
  const period = /^\d{4}-(0[1-9]|1[0-2])$/.test(periodParam) ? periodParam : "";
  const page = Math.max(1, Number(one(sp.page)) || 1);

  const [data, locations, canUpload] = await Promise.all([
    apiFetch<Paged<TimeEntryItem>>(`/time-entries${qs({ payrollPeriod: period, page, pageSize: 50 })}`),
    apiFetch<WorkLocation[]>("/work-locations"),
    can("inbound.time.create"),
  ]);
  const totalPages = Math.max(1, Math.ceil(data.total / data.pageSize));
  const href = (p: number) => `/time-entries${qs({ period, page: p > 1 ? p : undefined })}`;

  return (
    <div className="mx-auto max-w-6xl space-y-6">
      <PageHeader
        title="Time Entries"
        description="Unggah time entries dari file CSV, atau unduh dalam format yang sama untuk sistem lain."
        action={<TimeEntriesActions canUpload={canUpload} locations={locations.filter((l) => l.isActive)} defaultPeriod={period} />}
      />

      <Card className="p-5 text-sm">
        <h2 className="mb-2 font-semibold">Format CSV</h2>
        <p className="mb-3 text-muted">
          Baris pertama adalah header. Pemisah koma atau titik koma. Karyawan dicocokkan lewat <b>NIK</b>; karyawan tanpa NIK dilewati.
        </p>
        <dl className="grid gap-x-6 gap-y-2 sm:grid-cols-2">
          {[
            ["employee_number", "NIK karyawan (wajib)"],
            ["start_datetime", "Waktu mulai (wajib), mis. 2026-09-15T16:00:00+07:00"],
            ["end_datetime", "Waktu selesai (wajib), harus setelah mulai, maks. 24 jam"],
            ["work_schedule", "Kode shift yang sudah terdaftar (opsional)"],
            ["payroll_period", "Periode payroll YYYY-MM (opsional; kosong = bulan tanggal mulai)"],
            ["duration", "Lama kerja dalam JAM, mis. 8 atau 7.5 (opsional; kosong = selisih start dan end)"],
          ].map(([k, v]) => (
            <div key={k} className="flex gap-2">
              <dt className="shrink-0 font-mono text-xs leading-5">{k}</dt>
              <dd className="text-muted">{v}</dd>
            </div>
          ))}
        </dl>
        <p className="mt-3 text-xs text-muted">
          Waktu tanpa zona (mis. <span className="font-mono">2026-09-15 16:00</span>) dibaca sebagai waktu lokal lokasi karyawan. Mengunggah baris dengan
          karyawan dan waktu mulai yang sama memperbarui baris itu, bukan menggandakan. Duration yang berbeda dari selisih start dan end tetap dipakai, dengan
          peringatan di log.
        </p>
        <p className="mt-2 text-xs text-muted">
          Setelah file diunggah, prosesnya dipantau di{" "}
          <Link href="/process-monitor" className="text-accent hover:underline">
            Process Monitor
          </Link>{" "}
          (status, kemajuan, durasi, dan log).
        </p>
      </Card>

      <section aria-labelledby="entri">
        <div className="mb-3 flex flex-wrap items-end justify-between gap-3">
          <h2 id="entri" className="text-sm font-semibold text-muted">
            Entri hasil unggahan
          </h2>
          <form action="/time-entries" className="flex items-end gap-2">
            <label className="space-y-1 text-xs text-muted">
              Periode payroll
              <input type="month" name="period" defaultValue={period} className={`${inputCls} block w-44 text-foreground`} />
            </label>
            <button type="submit" className={btnPrimary}>
              Terapkan
            </button>
            {period && (
              <Link href="/time-entries" className={btnGhost}>
                Reset
              </Link>
            )}
          </form>
        </div>

        <Card className="overflow-x-auto">
          {data.items.length === 0 ? (
            <EmptyState>{period ? `Tidak ada entri untuk periode ${period}.` : "Belum ada entri. Unggah file CSV untuk memulai."}</EmptyState>
          ) : (
            <table className="w-full min-w-[760px]">
              <thead className="border-b border-border">
                <tr>
                  <th className={thCls}>Karyawan</th>
                  <th className={thCls}>Tanggal</th>
                  <th className={thCls}>Mulai</th>
                  <th className={thCls}>Selesai</th>
                  <th className={`${thCls} text-right`}>Durasi (jam)</th>
                  <th className={thCls}>Shift</th>
                  <th className={thCls}>Periode</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {data.items.map((t) => {
                  const tz = t.employee.workLocation.timezone;
                  const crossDay = dateOnly(new Date(t.endAt).toLocaleDateString("en-CA", { timeZone: tz })) !== dateOnly(t.workDate);
                  return (
                    <tr key={t.id}>
                      <td className={tdCls}>
                        <div className="font-medium">{t.employee.name}</div>
                        <div className="text-xs text-muted">{t.employee.nik}</div>
                      </td>
                      <td className={`${tdCls} whitespace-nowrap`}>{fmtDate(t.workDate)}</td>
                      <td className={`${tdCls} font-mono`}>{fmtTime(t.startAt, tz)}</td>
                      <td className={`${tdCls} font-mono`}>
                        {fmtTime(t.endAt, tz)}
                        {crossDay && <span className="ml-1 text-xs text-muted">(+1)</span>}
                      </td>
                      <td className={`${tdCls} text-right tabular-nums`}>{fmtHours(t.durationHours)}</td>
                      <td className={tdCls}>{t.shift?.code ?? t.workSchedule ?? "–"}</td>
                      <td className={tdCls}>
                        <Badge>{t.payrollPeriod}</Badge>
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
            {data.total} entri · halaman {data.page} dari {totalPages} · jam dalam zona waktu lokasi
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
      </section>
    </div>
  );
}
