"use client";

import { useState, type FormEvent } from "react";
import { bff } from "@/lib/client-api";
import { fmtDate } from "@/lib/format";
import { LEAVE_KIND_LABEL } from "@/lib/labels";
import { tenureLabel } from "@/lib/leave-rule";
import type { LeaveCheck, LeaveKindCode } from "@/lib/types";
import { Badge, btnPrimary, Card, ErrorNote, Field, inputCls, tdCls, thCls } from "./ui";

export function LeaveCheckPanel({
  kind,
  employees,
  defaultDate,
}: {
  kind: LeaveKindCode;
  employees: { id: string; name: string; nik: string | null }[];
  defaultDate: string;
}) {
  const [result, setResult] = useState<LeaveCheck | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    setPending(true);
    setError(null);
    try {
      const q = new URLSearchParams({
        employeeId: String(f.get("employeeId")),
        leaveKind: kind,
        startDate: String(f.get("startDate")),
      });
      setResult(await bff<LeaveCheck>("GET", `leave-rules/check?${q}`));
    } catch (err) {
      setResult(null);
      setError(err instanceof Error ? err.message : "Gagal memeriksa.");
    } finally {
      setPending(false);
    }
  }

  const b = result?.balance;

  return (
    <Card className="p-5">
      <h2 className="mb-1 text-sm font-semibold text-muted">Cek karyawan · {LEAVE_KIND_LABEL[kind]}</h2>
      <p className="mb-4 text-xs text-muted">
        Uji aturan pada satu karyawan: apakah boleh mengambil cuti ini pada tanggal tertentu, serta saldo dan anniversary berikutnya. Pemeriksaan yang sama
        dipakai saat cuti masuk dari Odoo.
      </p>

      <form onSubmit={onSubmit} className="flex flex-wrap items-end gap-3">
        <div className="min-w-56 flex-1">
          <Field label="Karyawan" htmlFor="employeeId">
            <select id="employeeId" name="employeeId" required defaultValue="" className={inputCls}>
              <option value="">Pilih karyawan…</option>
              {employees.map((e) => (
                <option key={e.id} value={e.id}>
                  {e.name}
                  {e.nik ? ` (${e.nik})` : ""}
                </option>
              ))}
            </select>
          </Field>
        </div>
        <Field label="Tanggal mulai cuti" htmlFor="startDate">
          <input id="startDate" name="startDate" type="date" required defaultValue={defaultDate} className={`${inputCls} w-44`} />
        </Field>
        <button type="submit" className={btnPrimary} disabled={pending}>
          {pending ? "Memeriksa…" : "Periksa"}
        </button>
      </form>

      {error && (
        <div className="mt-4">
          <ErrorNote>{error}</ErrorNote>
        </div>
      )}

      {result && b && (
        <div className="mt-5 space-y-4" aria-live="polite">
          <div className="flex flex-wrap items-center gap-3">
            <span className="font-medium">{result.employee.name}</span>
            <Badge tone={result.eligible ? "green" : "red"}>{result.eligible ? "Boleh mengajukan" : "Tidak boleh mengajukan"}</Badge>
          </div>

          <dl className="grid gap-4 sm:grid-cols-4">
            <div>
              <dt className="text-xs text-muted">Mulai kerja</dt>
              <dd className="text-sm font-medium">{result.employee.hireDate ? fmtDate(result.employee.hireDate) : "belum diisi"}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted">Masa kerja pada {fmtDate(result.startDate)}</dt>
              <dd className="text-sm font-medium">{result.tenureMonths === null ? "–" : tenureLabel(result.tenureMonths)}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted">Syarat minimum</dt>
              <dd className="text-sm font-medium">{result.minTenureMonths > 0 ? tenureLabel(result.minTenureMonths) : "Tanpa syarat"}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted">Anniversary berikutnya</dt>
              <dd className="text-sm font-medium">
                {b.nextAnniversary ? `${fmtDate(b.nextAnniversary.date)}${b.nextAnniversary.days ? ` (+${b.nextAnniversary.days} hari)` : ""}` : "–"}
              </dd>
            </div>
          </dl>

          {result.reasons.map((r) => (
            <ErrorNote key={r}>{r}</ErrorNote>
          ))}

          {b.grants.length > 0 ? (
            <div>
              <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-muted">Saldo per {fmtDate(b.asOf)}</p>
              <div className="mb-3 flex flex-wrap gap-2">
                <Badge tone="blue">Saldo aktif {b.grantedActive} hari</Badge>
                <Badge tone="amber">Terpakai {b.used} hari</Badge>
                <Badge tone={b.remaining > 0 ? "green" : "red"}>Sisa {b.remaining} hari</Badge>
              </div>
              <div className="overflow-x-auto rounded-lg border border-border">
                <table className="w-full min-w-[480px]">
                  <thead className="border-b border-border">
                    <tr>
                      <th className={thCls}>Anniversary ke-</th>
                      <th className={thCls}>Tanggal diberikan</th>
                      <th className={`${thCls} text-right`}>Jatah (hari)</th>
                      <th className={thCls}>Berlaku sampai</th>
                      <th className={thCls}>Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {b.grants.map((g) => (
                      <tr key={g.date} className={g.expired ? "text-muted" : ""}>
                        <td className={tdCls}>{g.anniversary}</td>
                        <td className={`${tdCls} whitespace-nowrap`}>{fmtDate(g.date)}</td>
                        <td className={`${tdCls} text-right tabular-nums`}>{g.days}</td>
                        <td className={`${tdCls} whitespace-nowrap`}>{g.expiresAt ? fmtDate(g.expiresAt) : "tanpa batas"}</td>
                        <td className={tdCls}>
                          <Badge tone={g.expired ? "gray" : "green"}>{g.expired ? "Kedaluwarsa" : "Aktif"}</Badge>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              <p className="mt-2 text-xs text-muted">Pemakaian dihitung dari cuti disetujui sejak saldo aktif tertua dan dikurangkan dari total saldo aktif.</p>
            </div>
          ) : (
            <p className="text-sm text-muted">Belum ada saldo yang diberikan oleh aturan pada tanggal ini.</p>
          )}
        </div>
      )}
    </Card>
  );
}
