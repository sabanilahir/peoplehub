import type { Metadata } from "next";
import Link from "next/link";
import { AttendanceRuleForm } from "@/components/attendance-rule-form";
import { Badge, Card, EmptyState, PageHeader, tdCls, thCls } from "@/components/ui";
import { apiFetch, can } from "@/lib/api";
import { fmtDate, todayStr } from "@/lib/format";
import type { AttendanceRule, WorkLocation } from "@/lib/types";

export const metadata: Metadata = { title: "Aturan Absensi · PeopleHub" };

export default async function AttendanceConfigPage({ searchParams }: PageProps<"/config/attendance">) {
  const sp = await searchParams;
  const locParam = Array.isArray(sp.location) ? sp.location[0] : sp.location;

  const [locations, canEdit] = await Promise.all([
    apiFetch<WorkLocation[]>("/work-locations"),
    can("config.attendance.edit"),
  ]);
  const active = locations.filter((l) => l.isActive);
  const selected = active.find((l) => l.id === locParam) ?? active[0];

  if (!selected) {
    return (
      <div className="mx-auto max-w-4xl">
        <PageHeader title="Aturan Absensi & Keterlambatan" />
        <Card>
          <EmptyState>Buat lokasi kerja dulu di menu Master Data.</EmptyState>
        </Card>
      </div>
    );
  }

  const history = await apiFetch<AttendanceRule[]>(`/attendance-rules?workLocationId=${selected.id}`);
  const today = todayStr();
  const current = history.find((r) => r.effectiveFrom.slice(0, 10) <= today && (!r.effectiveTo || r.effectiveTo.slice(0, 10) >= today));
  const latest = history[0];

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <PageHeader
        title="Aturan Absensi & Keterlambatan"
        description="Karyawan dianggap terlambat bila masuk melewati jam mulai shift ditambah toleransi. Perubahan membuat versi baru; versi lama tetap tersimpan."
      />

      <nav aria-label="Pilih lokasi" className="flex flex-wrap gap-2">
        {active.map((l) => (
          <Link
            key={l.id}
            href={`/config/attendance?location=${l.id}`}
            aria-current={l.id === selected.id ? "page" : undefined}
            className={`rounded-full border px-3.5 py-1.5 text-sm transition ${
              l.id === selected.id ? "border-accent bg-accent-soft font-medium text-accent" : "border-border hover:bg-surface"
            }`}
          >
            {l.name}
          </Link>
        ))}
      </nav>

      <Card className="p-5">
        <h2 className="mb-3 text-sm font-semibold text-muted">Aturan berlaku saat ini</h2>
        {current ? (
          <dl className="grid gap-4 sm:grid-cols-3">
            <div>
              <dt className="text-xs text-muted">Toleransi terlambat</dt>
              <dd className="text-lg font-semibold">{current.gracePeriodMinutes} menit</dd>
            </div>
            <div>
              <dt className="text-xs text-muted">Punch diterima sebelum shift</dt>
              <dd className="text-lg font-semibold">{current.preShiftWindowMinutes} menit</dd>
            </div>
            <div>
              <dt className="text-xs text-muted">Punch diterima setelah shift</dt>
              <dd className="text-lg font-semibold">{current.postShiftWindowMinutes} menit</dd>
            </div>
          </dl>
        ) : (
          <p className="text-sm text-muted">
            Belum ada aturan untuk {selected.name}. Tanpa aturan, toleransi 0 menit dan jendela punch bawaan (240/360 menit) dipakai.
          </p>
        )}
      </Card>

      {canEdit && (
        <Card className="p-5">
          <h2 className="mb-4 text-sm font-semibold text-muted">Buat versi baru</h2>
          <AttendanceRuleForm
            key={selected.id + (latest?.id ?? "")}
            workLocationId={selected.id}
            defaults={current ?? latest}
            latestFrom={latest?.effectiveFrom.slice(0, 10)}
          />
        </Card>
      )}

      <Card className="overflow-x-auto">
        <h2 className="border-b border-border px-4 py-3 text-sm font-semibold text-muted">Riwayat versi</h2>
        {history.length === 0 ? (
          <EmptyState>Belum ada riwayat.</EmptyState>
        ) : (
          <table className="w-full min-w-[520px]">
            <thead className="border-b border-border">
              <tr>
                <th className={thCls}>Berlaku</th>
                <th className={thCls}>Toleransi</th>
                <th className={thCls}>Jendela punch</th>
                <th className={thCls} />
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {history.map((r) => (
                <tr key={r.id}>
                  <td className={tdCls}>
                    {fmtDate(r.effectiveFrom)} – {r.effectiveTo ? fmtDate(r.effectiveTo) : "sekarang"}
                  </td>
                  <td className={tdCls}>{r.gracePeriodMinutes} menit</td>
                  <td className={tdCls}>
                    −{r.preShiftWindowMinutes} / +{r.postShiftWindowMinutes} menit
                  </td>
                  <td className={tdCls}>{r.id === current?.id && <Badge tone="green">Aktif</Badge>}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>
    </div>
  );
}
