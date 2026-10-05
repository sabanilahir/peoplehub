"use client";

import { RefreshCw } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { bff } from "@/lib/client-api";
import { qs } from "@/lib/format";
import { STATUS_LABEL } from "@/lib/labels";
import type { WorkLocation } from "@/lib/types";
import { Badge, btnGhost, btnPrimary, ErrorNote, inputCls } from "./ui";

export function DailyFilters({
  values,
  locations,
  canRecompute,
  summary,
}: {
  values: { from: string; to: string; location: string; status: string; late: boolean };
  locations: WorkLocation[];
  canRecompute: boolean;
  summary: { late: number; absent: number };
}) {
  const router = useRouter();
  const [pending, setPending] = useState(false);
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);

  function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const s = (k: string) => String(f.get(k) ?? "");
    router.push(
      `/attendance/daily${qs({ from: s("from"), to: s("to"), location: s("location"), status: s("status"), late: f.get("late") ? 1 : undefined })}`,
    );
  }

  async function recompute() {
    setPending(true);
    setMessage(null);
    try {
      const r = await bff<{ employees: number; days: number }>("POST", "attendance/recompute", {
        from: values.from,
        to: values.to,
        workLocationId: values.location || undefined,
      });
      setMessage({ ok: true, text: `Selesai: ${r.employees} karyawan, ${r.days} hari dihitung ulang.` });
      router.refresh();
    } catch (err) {
      setMessage({ ok: false, text: err instanceof Error ? err.message : "Gagal menghitung ulang." });
    } finally {
      setPending(false);
    }
  }

  return (
    <div className="mb-4 space-y-3">
      <form onSubmit={onSubmit} className="flex flex-wrap items-end gap-3 rounded-xl border border-border bg-surface p-4">
        <label className="space-y-1 text-xs text-muted">
          Dari
          <input name="from" type="date" defaultValue={values.from} required className={`${inputCls} block w-40 text-foreground`} />
        </label>
        <label className="space-y-1 text-xs text-muted">
          Sampai
          <input name="to" type="date" defaultValue={values.to} required className={`${inputCls} block w-40 text-foreground`} />
        </label>
        <label className="space-y-1 text-xs text-muted">
          Lokasi
          <select name="location" defaultValue={values.location} className={`${inputCls} block w-44 text-foreground`}>
            <option value="">Semua lokasi</option>
            {locations.map((l) => (
              <option key={l.id} value={l.id}>
                {l.name}
              </option>
            ))}
          </select>
        </label>
        <label className="space-y-1 text-xs text-muted">
          Status
          <select name="status" defaultValue={values.status} className={`${inputCls} block w-40 text-foreground`}>
            <option value="">Semua status</option>
            {Object.entries(STATUS_LABEL).map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className="flex items-center gap-2 pb-2 text-sm">
          <input type="checkbox" name="late" defaultChecked={values.late} className="h-4 w-4" />
          Hanya terlambat
        </label>
        <button type="submit" className={btnPrimary}>
          Terapkan
        </button>
      </form>

      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2 text-sm">
          <Badge tone="amber">{summary.late} terlambat</Badge>
          <Badge tone="red">{summary.absent} alpa</Badge>
          <span className="text-xs text-muted">pada rentang dan lokasi terpilih</span>
        </div>
        {canRecompute && (
          <button type="button" onClick={recompute} disabled={pending} className={btnGhost} title="Hitung ulang absensi untuk rentang tanggal dan lokasi terpilih">
            <RefreshCw className={`h-4 w-4 ${pending ? "animate-spin" : ""}`} aria-hidden />
            {pending ? "Menghitung…" : "Hitung ulang"}
          </button>
        )}
      </div>
      {message &&
        (message.ok ? (
          <p role="status" className="rounded-lg bg-accent-soft px-3.5 py-2.5 text-sm text-accent">
            {message.text}
          </p>
        ) : (
          <ErrorNote>{message.text}</ErrorNote>
        ))}
    </div>
  );
}
