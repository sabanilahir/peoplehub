"use client";

import { Plus, Trash2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useEffect, useState, type FormEvent } from "react";
import { bff } from "@/lib/client-api";
import { qs } from "@/lib/format";
import type { Device, DeviceMapping, Employee, Paged, WorkLocation } from "@/lib/types";
import { Modal } from "./modal";
import { Badge, btnGhost, btnPrimary, Card, EmptyState, ErrorNote, Field, inputCls, tdCls, thCls } from "./ui";

export function DevicesManager({
  devices,
  locations,
  canEdit,
}: {
  devices: Device[];
  locations: WorkLocation[];
  canEdit: boolean;
}) {
  const router = useRouter();
  const [editing, setEditing] = useState<Device | "new" | null>(null);
  const [mapping, setMapping] = useState<Device | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  const locName = (id: string) => locations.find((l) => l.id === id)?.name ?? "–";
  const activeLocations = locations.filter((l) => l.isActive);

  const close = () => {
    setEditing(null);
    setError(null);
  };

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const str = (k: string) => String(f.get(k) ?? "").trim();
    const body = { name: str("name"), vendor: str("vendor") || undefined, workLocationId: str("workLocationId") };
    setPending(true);
    setError(null);
    try {
      if (editing === "new") {
        await bff("POST", "devices", { serialNumber: str("serialNumber"), ...body });
      } else if (editing) {
        await bff("PATCH", `devices/${editing.id}`, { ...body, isActive: f.get("isActive") === "on" });
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
        <div className="flex justify-end">
          <button type="button" className={btnPrimary} onClick={() => setEditing("new")} disabled={activeLocations.length === 0}>
            <Plus className="h-4 w-4" aria-hidden /> Tambah mesin
          </button>
        </div>
      )}

      <Card className="overflow-x-auto">
        {devices.length === 0 ? (
          <EmptyState>
            {activeLocations.length === 0 ? "Buat lokasi kerja dulu, lalu daftarkan mesin." : "Belum ada mesin terdaftar."}
          </EmptyState>
        ) : (
          <table className="w-full min-w-[640px]">
            <thead className="border-b border-border">
              <tr>
                <th className={thCls}>Nama</th>
                <th className={thCls}>Serial</th>
                <th className={thCls}>Lokasi</th>
                <th className={thCls}>PIN terpetakan</th>
                <th className={thCls}>Status</th>
                <th className={thCls} />
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {devices.map((d) => (
                <tr key={d.id}>
                  <td className={tdCls}>
                    <div className="font-medium">{d.name}</div>
                    {d.vendor && <div className="text-xs text-muted">{d.vendor}</div>}
                  </td>
                  <td className={`${tdCls} font-mono`}>{d.serialNumber}</td>
                  <td className={tdCls}>{locName(d.workLocationId)}</td>
                  <td className={tdCls}>{d._count?.mappings ?? 0}</td>
                  <td className={tdCls}>
                    <Badge tone={d.isActive ? "green" : "gray"}>{d.isActive ? "Aktif" : "Nonaktif"}</Badge>
                  </td>
                  <td className={`${tdCls} whitespace-nowrap text-right`}>
                    <button type="button" className={btnGhost} onClick={() => setMapping(d)}>
                      {canEdit ? "Kelola PIN" : "Lihat PIN"}
                    </button>
                    {canEdit && (
                      <button type="button" className={`${btnGhost} ml-2`} onClick={() => setEditing(d)}>
                        Ubah
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>

      <Modal open={editing !== null} title={editing === "new" ? "Tambah mesin" : "Ubah mesin"} onClose={close}>
        {editing && (
          <form onSubmit={onSubmit} className="space-y-4" key={editing === "new" ? "new" : editing.id}>
            <Field label="Serial number" htmlFor="serialNumber" hint={editing === "new" ? "Harus sama dengan yang dikirim mesin. Tidak bisa diubah nanti." : undefined}>
              <input
                id="serialNumber"
                name="serialNumber"
                required
                autoFocus={editing === "new"}
                disabled={editing !== "new"}
                defaultValue={editing === "new" ? "" : editing.serialNumber}
                className={`${inputCls} font-mono`}
              />
            </Field>
            <Field label="Nama" htmlFor="name">
              <input id="name" name="name" required defaultValue={editing === "new" ? "" : editing.name} placeholder="mis. Mesin Lobby" className={inputCls} />
            </Field>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Vendor" htmlFor="vendor" hint="Opsional">
                <input id="vendor" name="vendor" defaultValue={editing === "new" ? "" : (editing.vendor ?? "")} placeholder="mis. ZKTeco" className={inputCls} />
              </Field>
              <Field label="Lokasi" htmlFor="workLocationId">
                <select id="workLocationId" name="workLocationId" required defaultValue={editing === "new" ? "" : editing.workLocationId} className={inputCls}>
                  {editing === "new" && <option value="">Pilih lokasi…</option>}
                  {locations
                    .filter((l) => l.isActive || (editing !== "new" && l.id === editing.workLocationId))
                    .map((l) => (
                      <option key={l.id} value={l.id}>
                        {l.name}
                      </option>
                    ))}
                </select>
              </Field>
            </div>
            {editing !== "new" && (
              <label className="flex items-center gap-2 text-sm">
                <input type="checkbox" name="isActive" defaultChecked={editing.isActive} className="h-4 w-4" />
                Mesin aktif (mesin nonaktif ditolak webhook)
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

      <MappingsDialog device={mapping} canEdit={canEdit} onClose={() => setMapping(null)} onChanged={() => router.refresh()} />
    </>
  );
}

function MappingsDialog({
  device,
  canEdit,
  onClose,
  onChanged,
}: {
  device: Device | null;
  canEdit: boolean;
  onClose: () => void;
  onChanged: () => void;
}) {
  return (
    <Modal open={device !== null} title={device ? `PIN · ${device.name}` : "PIN"} onClose={onClose}>
      {device && <MappingsBody key={device.id} device={device} canEdit={canEdit} onChanged={onChanged} />}
    </Modal>
  );
}

function MappingsBody({ device, canEdit, onChanged }: { device: Device; canEdit: boolean; onChanged: () => void }) {
  const [rows, setRows] = useState<DeviceMapping[] | null>(null);
  const [people, setPeople] = useState<Employee[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  // Muat saat dialog dibuka (komponen ini di-mount ulang per mesin)
  useEffect(() => {
    let cancelled = false;
    Promise.all([
      bff<DeviceMapping[]>("GET", `devices/${device.id}/mappings`),
      canEdit
        ? bff<Paged<Employee>>("GET", `employees${qs({ workLocationId: device.workLocationId, pageSize: 200 })}`)
        : Promise.resolve(null),
    ])
      .then(([m, e]) => {
        if (cancelled) return;
        setRows(m);
        setPeople((e?.items ?? []).filter((x) => x.isActive));
      })
      .catch((err) => {
        if (!cancelled) setError(err instanceof Error ? err.message : "Gagal memuat PIN.");
      });
    return () => {
      cancelled = true;
    };
  }, [device.id, device.workLocationId, canEdit]);

  const mappedIds = new Set(rows?.map((r) => r.odooEmployeeId));

  async function reload() {
    setRows(await bff<DeviceMapping[]>("GET", `devices/${device.id}/mappings`));
    onChanged();
  }

  async function add(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = e.currentTarget;
    const f = new FormData(form);
    setPending(true);
    setError(null);
    setNotice(null);
    try {
      const res = await bff<{ relinked: number }>("POST", `devices/${device.id}/mappings`, {
        enrollId: String(f.get("enrollId") ?? "").trim(),
        odooEmployeeId: String(f.get("odooEmployeeId") ?? ""),
      });
      if (res.relinked > 0) setNotice(`${res.relinked} punch lama dari PIN ini sudah ditautkan ke karyawan.`);
      form.reset();
      await reload();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Gagal menambah PIN.");
    } finally {
      setPending(false);
    }
  }

  async function remove(m: DeviceMapping) {
    if (!window.confirm(`Hapus pemetaan PIN ${m.enrollId} (${m.employee.name})? Punch yang sudah tercatat tidak berubah.`)) return;
    setError(null);
    try {
      await bff("DELETE", `devices/${device.id}/mappings/${m.id}`);
      await reload();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Gagal menghapus.");
    }
  }

  return (
    <div className="space-y-4">
      {canEdit && (
        <form onSubmit={add} className="flex flex-wrap items-end gap-2">
          <Field label="PIN di mesin" htmlFor="enrollId">
            <input id="enrollId" name="enrollId" required className={`${inputCls} w-28 font-mono`} />
          </Field>
          <div className="min-w-48 flex-1">
            <Field label="Karyawan" htmlFor="odooEmployeeId">
              <select id="odooEmployeeId" name="odooEmployeeId" required defaultValue="" className={inputCls}>
                <option value="">Pilih karyawan…</option>
                {people.map((p) => (
                  <option key={p.id} value={p.id} disabled={mappedIds.has(p.id)}>
                    {p.name}
                    {p.nik ? ` (${p.nik})` : ""}
                    {mappedIds.has(p.id) ? " · sudah dipetakan" : ""}
                  </option>
                ))}
              </select>
            </Field>
          </div>
          <button type="submit" className={btnPrimary} disabled={pending}>
            {pending ? "…" : "Tambah"}
          </button>
        </form>
      )}

      {error && <ErrorNote>{error}</ErrorNote>}
      {notice && (
        <p role="status" className="rounded-lg bg-accent-soft px-3.5 py-2.5 text-sm text-accent">
          {notice}
        </p>
      )}

      {rows === null ? (
        <p className="py-6 text-center text-sm text-muted">Memuat…</p>
      ) : rows.length === 0 ? (
        <p className="py-6 text-center text-sm text-muted">Belum ada PIN yang dipetakan di mesin ini.</p>
      ) : (
        <ul className="divide-y divide-border rounded-lg border border-border">
          {rows.map((m) => (
            <li key={m.id} className="flex items-center justify-between gap-3 px-3.5 py-2.5 text-sm">
              <span>
                <span className="mr-2 rounded bg-background px-1.5 py-0.5 font-mono text-xs">{m.enrollId}</span>
                {m.employee.name}
                {m.employee.nik && <span className="ml-1 text-muted">({m.employee.nik})</span>}
              </span>
              {canEdit && (
                <button type="button" onClick={() => remove(m)} aria-label={`Hapus PIN ${m.enrollId}`} className="rounded-md p-1.5 text-muted hover:bg-background hover:text-danger">
                  <Trash2 className="h-4 w-4" />
                </button>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
