"use client";

import { Plus, Trash2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { bff } from "@/lib/client-api";
import { dateOnly, fmtDate, qs } from "@/lib/format";
import { EVENT_TYPE_LABEL } from "@/lib/labels";
import type { CalendarEvent, WorkLocation } from "@/lib/types";
import { Modal } from "./modal";
import { Badge, btnGhost, btnPrimary, Card, EmptyState, ErrorNote, Field, inputCls, tdCls, thCls } from "./ui";

const TYPE_TONE: Record<string, "red" | "amber" | "blue" | "orange" | "gray"> = {
  PUBLIC_HOLIDAY: "red",
  COLLECTIVE_LEAVE: "amber",
  BUSINESS_TRIP: "blue",
  TRAINING: "orange",
  COMPANY_EVENT: "gray",
};

function rangeLabel(e: CalendarEvent) {
  const s = dateOnly(e.startDate);
  const t = dateOnly(e.endDate);
  return s === t ? fmtDate(s) : `${fmtDate(s)} – ${fmtDate(t)}`;
}

function scopeLabel(e: CalendarEvent) {
  if (e.scope === "GLOBAL") return "Semua lokasi";
  if (e.scope === "LOCATION") return e.workLocation?.name ?? "Lokasi";
  return "Satu karyawan";
}

export function CalendarManager({
  events,
  locations,
  canEdit,
  year,
  location,
}: {
  events: CalendarEvent[];
  locations: WorkLocation[];
  canEdit: boolean;
  year: number;
  location: string;
}) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [scope, setScope] = useState<"GLOBAL" | "LOCATION">("GLOBAL");
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  const close = () => {
    setOpen(false);
    setError(null);
    setScope("GLOBAL");
  };

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const str = (k: string) => String(f.get(k) ?? "").trim();
    setPending(true);
    setError(null);
    try {
      await bff("POST", "calendar-events", {
        name: str("name"),
        eventType: str("eventType"),
        scope,
        workLocationId: scope === "LOCATION" ? str("workLocationId") : undefined,
        startDate: str("startDate"),
        endDate: str("endDate") || str("startDate"),
        cancelsWorkday: f.get("cancelsWorkday") === "on",
        skipGeofence: f.get("skipGeofence") === "on",
      });
      close();
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Gagal menyimpan.");
    } finally {
      setPending(false);
    }
  }

  async function remove(ev: CalendarEvent) {
    if (!window.confirm(`Hapus event “${ev.name}” (${rangeLabel(ev)})?`)) return;
    try {
      await bff("DELETE", `calendar-events/${ev.id}`);
      router.refresh();
    } catch (err) {
      window.alert(err instanceof Error ? err.message : "Gagal menghapus.");
    }
  }

  return (
    <>
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <form
          onSubmit={(e) => {
            e.preventDefault();
            const loc = String(new FormData(e.currentTarget).get("location") ?? "");
            router.push(`/schedule/calendar${qs({ year, location: loc })}`);
          }}
          className="flex items-center gap-2"
        >
          <select name="location" defaultValue={location} aria-label="Filter lokasi" className={`${inputCls} w-52`}>
            <option value="">Semua event</option>
            {locations
              .filter((l) => l.isActive)
              .map((l) => (
                <option key={l.id} value={l.id}>
                  Berlaku di {l.name}
                </option>
              ))}
          </select>
          <button type="submit" className={btnGhost}>
            Terapkan
          </button>
        </form>
        {canEdit && (
          <button type="button" className={btnPrimary} onClick={() => setOpen(true)}>
            <Plus className="h-4 w-4" aria-hidden /> Tambah event
          </button>
        )}
      </div>

      <Card className="overflow-x-auto">
        {events.length === 0 ? (
          <EmptyState>Belum ada event di tahun {year}. Tambahkan libur nasional agar absensi hari itu tidak dihitung alpa.</EmptyState>
        ) : (
          <table className="w-full min-w-[640px]">
            <thead className="border-b border-border">
              <tr>
                <th className={thCls}>Tanggal</th>
                <th className={thCls}>Nama</th>
                <th className={thCls}>Jenis</th>
                <th className={thCls}>Berlaku untuk</th>
                <th className={thCls}>Hari kerja</th>
                {canEdit && <th className={thCls} />}
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {events.map((ev) => (
                <tr key={ev.id}>
                  <td className={`${tdCls} whitespace-nowrap`}>{rangeLabel(ev)}</td>
                  <td className={`${tdCls} font-medium`}>{ev.name}</td>
                  <td className={tdCls}>
                    <Badge tone={TYPE_TONE[ev.eventType] ?? "gray"}>{EVENT_TYPE_LABEL[ev.eventType]}</Badge>
                  </td>
                  <td className={tdCls}>{scopeLabel(ev)}</td>
                  <td className={tdCls}>{ev.cancelsWorkday ? "Dibatalkan (libur)" : "Tetap berjalan"}</td>
                  {canEdit && (
                    <td className={`${tdCls} text-right`}>
                      <button type="button" onClick={() => remove(ev)} aria-label={`Hapus ${ev.name}`} className="rounded-md p-1.5 text-muted hover:bg-background hover:text-danger">
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>

      <Modal open={open} title="Tambah event kalender" onClose={close}>
        {open && (
          <form onSubmit={onSubmit} className="space-y-4">
            <Field label="Nama" htmlFor="name">
              <input id="name" name="name" required autoFocus placeholder="mis. Hari Kemerdekaan RI" className={inputCls} />
            </Field>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Jenis" htmlFor="eventType">
                <select id="eventType" name="eventType" defaultValue="PUBLIC_HOLIDAY" className={inputCls}>
                  {Object.entries(EVENT_TYPE_LABEL).map(([v, l]) => (
                    <option key={v} value={v}>
                      {l}
                    </option>
                  ))}
                </select>
              </Field>
              <Field label="Berlaku untuk" htmlFor="scope">
                <select id="scope" value={scope} onChange={(e) => setScope(e.target.value as "GLOBAL" | "LOCATION")} className={inputCls}>
                  <option value="GLOBAL">Semua lokasi</option>
                  <option value="LOCATION">Satu lokasi</option>
                </select>
              </Field>
            </div>
            {scope === "LOCATION" && (
              <Field label="Lokasi" htmlFor="workLocationId">
                <select id="workLocationId" name="workLocationId" required defaultValue="" className={inputCls}>
                  <option value="">Pilih lokasi…</option>
                  {locations
                    .filter((l) => l.isActive)
                    .map((l) => (
                      <option key={l.id} value={l.id}>
                        {l.name}
                      </option>
                    ))}
                </select>
              </Field>
            )}
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Tanggal mulai" htmlFor="startDate">
                <input id="startDate" name="startDate" type="date" required className={inputCls} />
              </Field>
              <Field label="Tanggal selesai" htmlFor="endDate" hint="Kosongkan bila hanya satu hari">
                <input id="endDate" name="endDate" type="date" className={inputCls} />
              </Field>
            </div>
            <div className="space-y-2">
              <label className="flex items-center gap-2 text-sm">
                <input type="checkbox" name="cancelsWorkday" defaultChecked className="h-4 w-4" />
                Membatalkan hari kerja (karyawan tidak dinilai terlambat atau alpa)
              </label>
              <label className="flex items-center gap-2 text-sm">
                <input type="checkbox" name="skipGeofence" className="h-4 w-4" />
                Lewati pemeriksaan geofence pada hari ini
              </label>
            </div>
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
