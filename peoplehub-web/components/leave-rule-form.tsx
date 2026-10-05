"use client";

import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { bff } from "@/lib/client-api";
import { addDaysStr, todayStr } from "@/lib/format";
import { describeRule } from "@/lib/leave-rule";
import type { LeaveKindCode, LeaveRuleItem } from "@/lib/types";
import { btnPrimary, ErrorNote, Field, inputCls } from "./ui";

export function LeaveRuleForm({
  kind,
  defaults,
  latestFrom,
}: {
  kind: LeaveKindCode;
  defaults?: LeaveRuleItem;
  latestFrom?: string;
}) {
  const router = useRouter();
  const [minTenure, setMinTenure] = useState(String(defaults?.minTenureMonths ?? 0));
  const [mode, setMode] = useState<"NONE" | "ANNIVERSARY">(defaults?.accrualMode ?? "NONE");
  const [days, setDays] = useState(defaults?.entitlementDays ? String(Number(defaults.entitlementDays)) : "12");
  const [firstGrant, setFirstGrant] = useState(String(defaults?.firstGrantAnniversary ?? 1));
  const [expiry, setExpiry] = useState(defaults?.expiryMonths ? String(defaults.expiryMonths) : "");
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);
  const [pending, setPending] = useState(false);

  // Versi baru harus setelah versi terakhir; default: besok
  const tomorrow = addDaysStr(todayStr(), 1);
  const minDate = latestFrom ? addDaysStr(latestFrom, 1) : undefined;
  const defaultFrom = minDate && minDate > tomorrow ? minDate : tomorrow;

  const preview = describeRule({
    minTenureMonths: Number(minTenure) || 0,
    accrualMode: mode,
    entitlementDays: Number(days) || 0,
    firstGrantAnniversary: Number(firstGrant) || 1,
    expiryMonths: expiry ? Number(expiry) : null,
  });

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    setPending(true);
    setError(null);
    setSaved(false);
    try {
      await bff("POST", "leave-rules", {
        leaveKind: kind,
        effectiveFrom: String(f.get("effectiveFrom")),
        minTenureMonths: Number(minTenure) || 0,
        accrualMode: mode,
        ...(mode === "ANNIVERSARY" && {
          entitlementDays: Number(days),
          firstGrantAnniversary: Number(firstGrant) || 1,
          expiryMonths: expiry ? Number(expiry) : undefined,
        }),
      });
      setSaved(true);
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Gagal menyimpan.");
    } finally {
      setPending(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Berlaku mulai" htmlFor="effectiveFrom">
          <input id="effectiveFrom" name="effectiveFrom" type="date" required min={minDate} defaultValue={defaultFrom} className={inputCls} />
        </Field>
        <Field
          label="Masa kerja minimum (bulan)"
          htmlFor="minTenureMonths"
          hint="0 = tanpa syarat. 12 = harus sudah bekerja 1 tahun; sebelum itu pengajuan ditolak."
        >
          <input id="minTenureMonths" type="number" min={0} max={240} required value={minTenure} onChange={(e) => setMinTenure(e.target.value)} className={inputCls} />
        </Field>
      </div>

      <Field label="Pemberian saldo" htmlFor="accrualMode">
        <select id="accrualMode" value={mode} onChange={(e) => setMode(e.target.value as "NONE" | "ANNIVERSARY")} className={inputCls}>
          <option value="NONE">Tidak ada pemberian otomatis</option>
          <option value="ANNIVERSARY">Saldo baru setiap anniversary masa kerja</option>
        </select>
      </Field>

      {mode === "ANNIVERSARY" && (
        <div className="grid gap-4 sm:grid-cols-3">
          <Field label="Jatah per anniversary (hari)" htmlFor="entitlementDays">
            <input id="entitlementDays" type="number" min={0.5} max={365} step="0.5" required value={days} onChange={(e) => setDays(e.target.value)} className={inputCls} />
          </Field>
          <Field label="Mulai anniversary ke-" htmlFor="firstGrantAnniversary" hint="1 = saat genap 1 tahun bekerja">
            <input id="firstGrantAnniversary" type="number" min={1} max={50} required value={firstGrant} onChange={(e) => setFirstGrant(e.target.value)} className={inputCls} />
          </Field>
          <Field label="Masa berlaku saldo (bulan)" htmlFor="expiryMonths" hint="Kosong = tidak kedaluwarsa">
            <input id="expiryMonths" type="number" min={1} max={120} value={expiry} onChange={(e) => setExpiry(e.target.value)} className={inputCls} />
          </Field>
        </div>
      )}

      <div className="rounded-lg bg-background p-4">
        <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-muted">Pratinjau aturan</p>
        <ul className="list-disc space-y-1 pl-5 text-sm">
          {preview.map((line) => (
            <li key={line}>{line}</li>
          ))}
        </ul>
      </div>

      {error && <ErrorNote>{error}</ErrorNote>}
      {saved && (
        <p role="status" className="rounded-lg bg-accent-soft px-3.5 py-2.5 text-sm text-accent">
          Versi baru tersimpan dan berlaku mulai tanggal yang dipilih. Cuti yang sudah tercatat tidak divalidasi ulang.
        </p>
      )}
      <button type="submit" className={btnPrimary} disabled={pending}>
        {pending ? "Menyimpan…" : "Simpan sebagai versi baru"}
      </button>
    </form>
  );
}
