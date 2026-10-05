"use client";

import { Plus } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { bff } from "@/lib/client-api";
import type { WorkLocation } from "@/lib/types";
import { Modal } from "./modal";
import { Badge, btnGhost, btnPrimary, Card, EmptyState, ErrorNote, Field, inputCls, tdCls, thCls } from "./ui";

export const TIMEZONES = [
  { value: "Asia/Jakarta", label: "WIB (Asia/Jakarta)" },
  { value: "Asia/Makassar", label: "WITA (Asia/Makassar)" },
  { value: "Asia/Jayapura", label: "WIT (Asia/Jayapura)" },
];

export function LocationsManager({ items, canEdit }: { items: WorkLocation[]; canEdit: boolean }) {
  const router = useRouter();
  const [editing, setEditing] = useState<WorkLocation | "new" | null>(null);
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
    const body: Record<string, unknown> = {
      name: str("name"),
      type: str("type"),
      timezone: str("timezone"),
    };
    setPending(true);
    setError(null);
    try {
      if (editing === "new") {
        await bff("POST", "work-locations", { code: str("code"), ...body });
      } else if (editing) {
        await bff("PATCH", `work-locations/${editing.id}`, { ...body, isActive: f.get("isActive") === "on" });
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
            <Plus className="h-4 w-4" aria-hidden /> Tambah lokasi
          </button>
        </div>
      )}

      <Card className="overflow-x-auto">
        {items.length === 0 ? (
          <EmptyState>Belum ada lokasi kerja. Tambahkan lokasi pertama untuk memulai.</EmptyState>
        ) : (
          <table className="w-full min-w-[560px]">
            <thead className="border-b border-border">
              <tr>
                <th className={thCls}>Kode</th>
                <th className={thCls}>Nama</th>
                <th className={thCls}>Tipe</th>
                <th className={thCls}>Zona waktu</th>
                <th className={thCls}>Status</th>
                {canEdit && <th className={thCls} />}
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {items.map((l) => (
                <tr key={l.id}>
                  <td className={`${tdCls} font-mono`}>{l.code}</td>
                  <td className={`${tdCls} font-medium`}>{l.name}</td>
                  <td className={tdCls}>{l.type === "HO" ? "Kantor pusat" : "Cabang"}</td>
                  <td className={tdCls}>{l.timezone}</td>
                  <td className={tdCls}>
                    <Badge tone={l.isActive ? "green" : "gray"}>{l.isActive ? "Aktif" : "Nonaktif"}</Badge>
                  </td>
                  {canEdit && (
                    <td className={`${tdCls} text-right`}>
                      <button type="button" className={btnGhost} onClick={() => setEditing(l)}>
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

      <Modal open={editing !== null} title={editing === "new" ? "Tambah lokasi kerja" : "Ubah lokasi kerja"} onClose={close}>
        {editing && (
          <form onSubmit={onSubmit} className="space-y-4" key={editing === "new" ? "new" : editing.id}>
            <Field label="Kode" htmlFor="code" hint={editing === "new" ? "Singkat dan unik, mis. HO atau CBG-BDG. Tidak bisa diubah nanti." : undefined}>
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
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Tipe" htmlFor="type">
                <select id="type" name="type" defaultValue={editing === "new" ? "BRANCH" : editing.type} className={inputCls}>
                  <option value="HO">Kantor pusat</option>
                  <option value="BRANCH">Cabang</option>
                </select>
              </Field>
              <Field label="Zona waktu" htmlFor="timezone">
                <select id="timezone" name="timezone" defaultValue={editing === "new" ? "Asia/Jakarta" : editing.timezone} className={inputCls}>
                  {TIMEZONES.map((t) => (
                    <option key={t.value} value={t.value}>
                      {t.label}
                    </option>
                  ))}
                </select>
              </Field>
            </div>
            {editing !== "new" && (
              <label className="flex items-center gap-2 text-sm">
                <input type="checkbox" name="isActive" defaultChecked={editing.isActive} className="h-4 w-4" />
                Lokasi aktif
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
