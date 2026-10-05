"use client";

import { useState } from "react";
import { bff } from "@/lib/client-api";
import { addDaysStr, dateOnly, fmtDayShort } from "@/lib/format";
import type { Schedule } from "@/lib/types";
import { Card, EmptyState, ErrorNote, inputCls, thCls } from "./ui";

interface Person {
  id: string;
  name: string;
  nik: string | null;
}
interface ShiftOpt {
  id: string;
  code: string;
  name: string;
  startTime: string;
}

// "" = belum diatur, "OFF" = hari libur, selain itu = id shift
type CellValue = string;
interface Cell {
  id?: string;
  value: CellValue;
}

const key = (emp: string, date: string) => `${emp}|${date}`;

export function RosterGrid({
  week,
  employees,
  shifts,
  schedules,
  canEdit,
}: {
  week: string;
  employees: Person[];
  shifts: ShiftOpt[];
  schedules: Schedule[];
  canEdit: boolean;
}) {
  const days = Array.from({ length: 7 }, (_, i) => addDaysStr(week, i));

  const [cells, setCells] = useState<Map<string, Cell>>(() => {
    const m = new Map<string, Cell>();
    for (const s of schedules) {
      m.set(key(s.odooEmployeeId, dateOnly(s.workDate)), {
        id: s.id,
        value: s.dayType === "OFFDAY" ? "OFF" : (s.shiftId ?? ""),
      });
    }
    return m;
  });
  const [busy, setBusy] = useState<Set<string>>(new Set());
  const [error, setError] = useState<string | null>(null);

  async function change(emp: string, date: string, value: CellValue) {
    const k = key(emp, date);
    const prev = cells.get(k);
    setError(null);
    setBusy((b) => new Set(b).add(k));
    setCells((m) => new Map(m).set(k, { id: prev?.id, value }));

    try {
      if (value === "") {
        if (prev?.id) await bff("DELETE", `schedules/${prev.id}`);
        setCells((m) => {
          const n = new Map(m);
          n.delete(k);
          return n;
        });
      } else {
        const saved = await bff<Schedule>("PUT", "schedules", {
          odooEmployeeId: emp,
          workDate: date,
          dayType: value === "OFF" ? "OFFDAY" : "WORKDAY",
          shiftId: value === "OFF" ? undefined : value,
        });
        setCells((m) => new Map(m).set(k, { id: saved.id, value }));
      }
    } catch (err) {
      // Kembalikan ke nilai sebelumnya bila gagal
      setCells((m) => {
        const n = new Map(m);
        if (prev) n.set(k, prev);
        else n.delete(k);
        return n;
      });
      setError(err instanceof Error ? err.message : "Gagal menyimpan jadwal.");
    } finally {
      setBusy((b) => {
        const n = new Set(b);
        n.delete(k);
        return n;
      });
    }
  }

  if (employees.length === 0) {
    return (
      <Card>
        <EmptyState>Belum ada karyawan aktif di lokasi ini.</EmptyState>
      </Card>
    );
  }

  return (
    <div className="space-y-3">
      {error && <ErrorNote>{error}</ErrorNote>}
      <Card className="overflow-x-auto">
        <table className="w-full min-w-[920px] border-collapse">
          <thead className="border-b border-border">
            <tr>
              <th className={`${thCls} sticky left-0 z-10 bg-surface`}>Karyawan</th>
              {days.map((d) => (
                <th key={d} className={`${thCls} text-center`}>
                  {fmtDayShort(d)}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {employees.map((emp) => (
              <tr key={emp.id}>
                <th scope="row" className="sticky left-0 z-10 bg-surface px-4 py-2 text-left text-sm font-medium">
                  {emp.name}
                  {emp.nik && <span className="block text-xs font-normal text-muted">{emp.nik}</span>}
                </th>
                {days.map((d) => {
                  const k = key(emp.id, d);
                  const cell = cells.get(k);
                  const off = cell?.value === "OFF";
                  return (
                    <td key={d} className="px-1.5 py-1.5">
                      <select
                        aria-label={`Shift ${emp.name} ${fmtDayShort(d)}`}
                        value={cell?.value ?? ""}
                        disabled={!canEdit || busy.has(k)}
                        onChange={(e) => change(emp.id, d, e.target.value)}
                        className={`${inputCls} px-2 py-1.5 text-center text-xs ${
                          off ? "bg-zinc-100 text-muted dark:bg-zinc-800" : cell?.value ? "border-accent/40 bg-accent-soft font-medium" : ""
                        }`}
                      >
                        <option value="">–</option>
                        <option value="OFF">Libur</option>
                        {shifts.map((s) => (
                          <option key={s.id} value={s.id}>
                            {s.code} · {s.startTime}
                          </option>
                        ))}
                      </select>
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
      <p className="text-xs text-muted">
        “–” berarti belum ada jadwal. Hari tanpa jadwal tidak dinilai terlambat atau alpa.
        {!canEdit && " Anda hanya memiliki akses lihat."}
      </p>
    </div>
  );
}
