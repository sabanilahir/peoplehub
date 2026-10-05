"use client";

import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { bff } from "@/lib/client-api";
import { addDaysStr, todayStr } from "@/lib/format";
import type { AttendanceRule } from "@/lib/types";
import { btnPrimary, ErrorNote, Field, inputCls } from "./ui";

export function AttendanceRuleForm({
  workLocationId,
  defaults,
  latestFrom,
}: {
  workLocationId: string;
  defaults?: AttendanceRule;
  latestFrom?: string;
}) {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);
  const [saved, setSaved] = useState(false);

  // Versi baru harus setelah versi terakhir; default: besok
  const tomorrow = addDaysStr(todayStr(), 1);
  const minDate = latestFrom ? addDaysStr(latestFrom, 1) : undefined;
  const defaultFrom = minDate && minDate > tomorrow ? minDate : tomorrow;

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const num = (k: string) => Number(String(f.get(k) ?? "0"));
    setPending(true);
    setError(null);
    setSaved(false);
    try {
      await bff("POST", "attendance-rules", {
        workLocationId,
        effectiveFrom: String(f.get("effectiveFrom")),
        gracePeriodMinutes: num("gracePeriodMinutes"),
        preShiftWindowMinutes: num("preShiftWindowMinutes"),
        postShiftWindowMinutes: num("postShiftWindowMinutes"),
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
      <div className="grid gap-4 sm:grid-cols-4">
        <Field label="Berlaku mulai" htmlFor="effectiveFrom">
          <input id="effectiveFrom" name="effectiveFrom" type="date" required min={minDate} defaultValue={defaultFrom} className={inputCls} />
        </Field>
        <Field label="Toleransi (menit)" htmlFor="gracePeriodMinutes">
          <input id="gracePeriodMinutes" name="gracePeriodMinutes" type="number" min={0} required defaultValue={defaults?.gracePeriodMinutes ?? 0} className={inputCls} />
        </Field>
        <Field label="Punch sebelum shift (menit)" htmlFor="preShiftWindowMinutes">
          <input id="preShiftWindowMinutes" name="preShiftWindowMinutes" type="number" min={0} required defaultValue={defaults?.preShiftWindowMinutes ?? 240} className={inputCls} />
        </Field>
        <Field label="Punch setelah shift (menit)" htmlFor="postShiftWindowMinutes">
          <input id="postShiftWindowMinutes" name="postShiftWindowMinutes" type="number" min={0} required defaultValue={defaults?.postShiftWindowMinutes ?? 360} className={inputCls} />
        </Field>
      </div>
      <p className="text-xs text-muted">
        Jendela punch menentukan punch milik shift yang mana. Untuk shift malam, jendela setelah shift harus cukup panjang agar clock out lewat tengah malam tetap masuk ke shift tersebut.
      </p>
      {error && <ErrorNote>{error}</ErrorNote>}
      {saved && (
        <p role="status" className="rounded-lg bg-accent-soft px-3.5 py-2.5 text-sm text-accent">
          Versi baru tersimpan. Hitung ulang absensi (di Rekap Absensi) agar perubahan berlaku pada data lama.
        </p>
      )}
      <button type="submit" className={btnPrimary} disabled={pending}>
        {pending ? "Menyimpan…" : "Simpan sebagai versi baru"}
      </button>
    </form>
  );
}
