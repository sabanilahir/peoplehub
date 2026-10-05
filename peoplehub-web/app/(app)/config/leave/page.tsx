import type { Metadata } from "next";
import Link from "next/link";
import { LeaveCheckPanel } from "@/components/leave-check-panel";
import { LeaveRuleForm } from "@/components/leave-rule-form";
import { Badge, Card, EmptyState, PageHeader, tdCls, thCls } from "@/components/ui";
import { apiFetch, can } from "@/lib/api";
import { fmtDate, qs, todayStr } from "@/lib/format";
import { ACCRUAL_LABEL, LEAVE_KIND_LABEL } from "@/lib/labels";
import { describeRule, tenureLabel } from "@/lib/leave-rule";
import type { Employee, LeaveKindCode, LeaveRuleItem, Paged } from "@/lib/types";

export const metadata: Metadata = { title: "Aturan Cuti · PeopleHub" };

const KINDS: LeaveKindCode[] = ["ANNUAL", "SICK", "UNPAID", "OTHER"];

export default async function LeaveRulesPage({ searchParams }: PageProps<"/config/leave">) {
  const sp = await searchParams;
  const kindParam = Array.isArray(sp.kind) ? sp.kind[0] : sp.kind;
  const kind = (KINDS as string[]).includes(kindParam ?? "") ? (kindParam as LeaveKindCode) : "ANNUAL";

  const [history, employees, canEdit] = await Promise.all([
    apiFetch<LeaveRuleItem[]>(`/leave-rules${qs({ leaveKind: kind })}`),
    apiFetch<Paged<Employee>>(`/employees${qs({ pageSize: 200 })}`),
    can("leave.rule.edit"),
  ]);
  const today = todayStr();
  const current = history.find((r) => r.effectiveFrom.slice(0, 10) <= today && (!r.effectiveTo || r.effectiveTo.slice(0, 10) >= today));
  const latest = history[0];

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <PageHeader
        title="Aturan Cuti"
        description="Aturan khusus per jenis cuti: syarat masa kerja minimum dan pemberian saldo baru setiap anniversary. Perubahan membuat versi baru; versi lama tetap tersimpan."
      />

      <nav aria-label="Jenis cuti" className="flex flex-wrap gap-2">
        {KINDS.map((k) => (
          <Link
            key={k}
            href={`/config/leave?kind=${k}`}
            aria-current={k === kind ? "page" : undefined}
            className={`rounded-full border px-3.5 py-1.5 text-sm transition ${
              k === kind ? "border-accent bg-accent-soft font-medium text-accent" : "border-border hover:bg-surface"
            }`}
          >
            {LEAVE_KIND_LABEL[k]}
          </Link>
        ))}
      </nav>

      <Card className="p-5">
        <h2 className="mb-3 text-sm font-semibold text-muted">Aturan berlaku saat ini · {LEAVE_KIND_LABEL[kind]}</h2>
        {current ? (
          <ul className="list-disc space-y-1.5 pl-5 text-sm">
            {describeRule(current).map((line) => (
              <li key={line}>{line}</li>
            ))}
          </ul>
        ) : (
          <p className="text-sm text-muted">
            Belum ada aturan untuk cuti {LEAVE_KIND_LABEL[kind].toLowerCase()}: semua karyawan boleh mengambilnya tanpa syarat, dan tidak ada pemberian saldo
            otomatis.
          </p>
        )}
      </Card>

      {canEdit && (
        <Card className="p-5">
          <h2 className="mb-4 text-sm font-semibold text-muted">Buat versi baru</h2>
          <LeaveRuleForm key={kind} kind={kind} defaults={current ?? latest} latestFrom={latest?.effectiveFrom.slice(0, 10)} />
        </Card>
      )}

      <LeaveCheckPanel
        kind={kind}
        employees={employees.items.filter((e) => e.isActive).map((e) => ({ id: e.id, name: e.name, nik: e.nik }))}
        defaultDate={today}
      />

      <Card className="overflow-x-auto">
        <h2 className="border-b border-border px-4 py-3 text-sm font-semibold text-muted">Riwayat versi · {LEAVE_KIND_LABEL[kind]}</h2>
        {history.length === 0 ? (
          <EmptyState>Belum ada riwayat.</EmptyState>
        ) : (
          <table className="w-full min-w-[640px]">
            <thead className="border-b border-border">
              <tr>
                <th className={thCls}>Berlaku</th>
                <th className={thCls}>Masa kerja minimum</th>
                <th className={thCls}>Pemberian saldo</th>
                <th className={thCls} />
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {history.map((r) => (
                <tr key={r.id}>
                  <td className={`${tdCls} whitespace-nowrap`}>
                    {fmtDate(r.effectiveFrom)} – {r.effectiveTo ? fmtDate(r.effectiveTo) : "sekarang"}
                  </td>
                  <td className={tdCls}>{r.minTenureMonths > 0 ? tenureLabel(r.minTenureMonths) : "Tanpa syarat"}</td>
                  <td className={tdCls}>
                    {r.accrualMode === "ANNIVERSARY"
                      ? `${Number(r.entitlementDays)} hari · ${ACCRUAL_LABEL.ANNIVERSARY.toLowerCase()}${r.expiryMonths ? ` · berlaku ${r.expiryMonths} bln` : ""}`
                      : ACCRUAL_LABEL.NONE}
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
