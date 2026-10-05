"use client";

import { Plus } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { bff } from "@/lib/client-api";
import { endTimeLabel } from "@/lib/format";
import type { Shift } from "@/lib/types";
import { Modal } from "./modal";
import { Badge, btnGhost, btnPrimary, Card, EmptyState, ErrorNote, Field, inputCls, tdCls, thCls } from "./ui";

function durationLabel(min: number) {
  const h = Math.floor(min / 60);
  const m = min % 60;
  return m ? `${h} j ${m} m` : `${h} jam`;
}

export function ShiftsManager({ items, canEdit }: { items: Shift[]; canEdit: boolean }) {
  const router = useRouter();
  const [editing, setEditing] = useState<Shift | "new" | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  const close = () => {
    setEditing(null);
    setError(null);
  };

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const str = (k: string) => String(f.get(k) ?? "").trim();
    const hours = Number(str("durationHours"));
    const body = {
      name: str("name"),
      startTime: str("startTime"),
      durationMinutes: Math.round(hours * 60),
      breakMinutes: Number(str("breakMinutes") || 0),
    };
    setPending(true);
    setError(null);
    try {
      if (editing === "new") {
        await bff("POST", "shifts", { code: str("code"), ...body });
      } else if (editing) {
        await bff("PATCH", `shifts/${editing.id}`, { ...body, isActive: f.get("isActive") === "on" });
      }
      close();
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Gagal menyimpan.");
    } finally {
      setPending(false);
    }
  }

  return (
    <>
      {canEdit && (
        <div className="mb-4 flex justify-end">
          <button type="button" className={btnPrimary} onClick={() => setEditing("new")}>
            <Plus className="h-4 w-4" aria-hidden /> Tambah shift
          </button>
        </div>
      )}

      <Card className="overflow-x-auto">
        {items.length === 0 ? (
          <EmptyState>Belum ada shift. Tambahkan shift agar jadwal karyawan bisa disusun.</EmptyState>
        ) : (
          <table className="w-full min-w-[560px]">
            <thead className="border-b border-border">
              <tr>
                <th className={thCls}>Kode</th>
                <th className={thCls}>Nama</th>
                <th className={thCls}>Jam kerja</th>
                <th className={thCls}>Durasi</th>
                <th className={thCls}>Istirahat</th>
                <th className={thCls}>Status</th>
                {canEdit && <th className={thCls} />}
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {items.map((s) => (
                <tr key={s.id}>
                  <td className={`${tdCls} font-mono`}>{s.code}</td>
                  <td className={`${tdCls} font-medium`}>{s.name}</td>
                  <td className={tdCls}>
                    {s.startTime} – {endTimeLabel(s.startTime, s.durationMinutes)}
                  </td>
                  <td className={tdCls}>{durationLabel(s.durationMinutes)}</td>
                  <td className={tdCls}>{s.breakMinutes} menit</td>
                  <td className={tdCls}>
                    <Badge tone={s.isActive ? "green" : "gray"}>{s.isActive ? "Aktif" : "Nonaktif"}</Badge>
                  </td>
                  {canEdit && (
                    <td className={`${tdCls} text-right`}>
                      <button type="button" className={btnGhost} onClick={() => setEditing(s)}>
                        Ubah
                      </button>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>

      <Modal open={editing !== null} title={editing === "new" ? "Tambah shift" : "Ubah shift"} onClose={close}>
        {editing && (
          <form onSubmit={onSubmit} className="space-y-4" key={editing === "new" ? "new" : editing.id}>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Kode" htmlFor="code" hint={editing === "new" ? "Harus sama dengan kode shift di file sumber." : undefined}>
                <input
                  id="code"
                  name="code"
                  required
                  autoFocus={editing === "new"}
                  disabled={editing !== "new"}
                  defaultValue={editing === "new" ? "" : editing.code}
                  className={inputCls}
                />
              </Field>
              <Field label="Nama" htmlFor="name">
                <input id="name" name="name" required defaultValue={editing === "new" ? "" : editing.name} className={inputCls} />
              </Field>
            </div>
            <div className="grid gap-4 sm:grid-cols-3">
              <Field label="Jam mulai" htmlFor="startTime">
                <input id="startTime" name="startTime" type="time" required defaultValue={editing === "new" ? "08:00" : editing.startTime} className={inputCls} />
              </Field>
              <Field label="Durasi (jam)" htmlFor="durationHours">
                <input
                  id="durationHours"
                  name="durationHours"
                  type="number"
                  step="0.25"
                  min="0.25"
                  max="24"
                  required
                  defaultValue={editing === "new" ? 8 : editing.durationMinutes / 60}
                  className={inputCls}
                />
              </Field>
              <Field label="Istirahat (menit)" htmlFor="breakMinutes">
                <input id="breakMinutes" name="breakMinutes" type="number" min="0" defaultValue={editing === "new" ? 60 : editing.breakMinutes} className={inputCls} />
              </Field>
            </div>
            <p className="text-xs text-muted">Mengubah shift tidak mengubah jadwal yang sudah tersusun; jam tiap hari tersimpan terpisah.</p>
            {editing !== "new" && (
              <label className="flex items-center gap-2 text-sm">
                <input type="checkbox" name="isActive" defaultChecked={editing.isActive} className="h-4 w-4" />
                Shift aktif
              </label>
            )}
            {error && <ErrorNote>{error}</ErrorNote>}
            <div className="flex justify-end gap-2 pt-1">
              <button type="button" className={btnGhost} onClick={close}>
                Batal
              </button>
              <button type="submit" className={btnPrimary} disabled={pending}>
                {pending ? "Menyimpan…" : "Simpan"}
              </button>
            </div>
          </form>
        )}
      </Modal>
    </>
  );
}
