"use client";

import { ChevronLeft, ChevronRight, Plus, Search } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { bff } from "@/lib/client-api";
import { dateOnly, fmtDate, qs } from "@/lib/format";
import type { Employee, Paged, WorkLocation } from "@/lib/types";
import { Modal } from "./modal";
import { Badge, btnGhost, btnPrimary, Card, EmptyState, ErrorNote, Field, inputCls, tdCls, thCls } from "./ui";

export function EmployeesManager({
  data,
  locations,
  canEdit,
  filters,
}: {
  data: Paged<Employee>;
  locations: WorkLocation[];
  canEdit: boolean;
  filters: { q: string; location: string };
}) {
  const router = useRouter();
  const [editing, setEditing] = useState<Employee | "new" | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  const totalPages = Math.max(1, Math.ceil(data.total / data.pageSize));
  const activeLocations = locations.filter((l) => l.isActive);

  const close = () => {
    setEditing(null);
    setError(null);
  };

  function onFilter(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    router.push(`/master/employees${qs({ q: String(f.get("q") ?? "").trim(), location: String(f.get("location") ?? "") })}`);
  }

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const str = (k: string) => String(f.get(k) ?? "").trim();
    const optional = (k: string) => str(k) || undefined;

    const body: Record<string, unknown> = {
      name: str("name"),
      workLocationId: str("workLocationId"),
      nik: optional("nik"),
      email: optional("email"),
      jobTitle: optional("jobTitle"),
      jobGrade: optional("jobGrade"),
      // string kosong = hapus tanggal (saat ubah); saat tambah diabaikan
      hireDate: str("hireDate") || (editing !== "new" ? null : undefined),
      parentOdooId: str("parentOdooId") ? Number(str("parentOdooId")) : undefined,
    };

    setPending(true);
    setError(null);
    try {
      if (editing === "new") {
        await bff("POST", "employees", { odooId: Number(str("odooId")), ...body });
      } else if (editing) {
        await bff("PATCH", `employees/${editing.id}`, { ...body, isActive: f.get("isActive") === "on" });
      }
      close();
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Gagal menyimpan.");
    } finally {
      setPending(false);
    }
  }

  const pageHref = (p: number) => `/master/employees${qs({ q: filters.q, location: filters.location, page: p > 1 ? p : undefined })}`;

  return (
    <>
      <div className="mb-4 flex flex-wrap items-end justify-between gap-3">
        <form onSubmit={onFilter} className="flex flex-wrap items-end gap-2" role="search">
          <div className="relative">
            <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" aria-hidden />
            <input
              name="q"
              defaultValue={filters.q}
              placeholder="Cari nama, NIK, email"
              aria-label="Cari karyawan"
              className={`${inputCls} w-64 pl-9`}
            />
          </div>
          <select name="location" defaultValue={filters.location} aria-label="Filter lokasi" className={`${inputCls} w-48`}>
            <option value="">Semua lokasi</option>
            {locations.map((l) => (
              <option key={l.id} value={l.id}>
                {l.name}
              </option>
            ))}
          </select>
          <button type="submit" className={btnGhost}>
            Terapkan
          </button>
        </form>
        {canEdit && (
          <button type="button" className={btnPrimary} onClick={() => setEditing("new")} disabled={activeLocations.length === 0}>
            <Plus className="h-4 w-4" aria-hidden /> Tambah karyawan
          </button>
        )}
      </div>

      <Card className="overflow-x-auto">
        {data.items.length === 0 ? (
          <EmptyState>
            {filters.q || filters.location
              ? "Tidak ada karyawan yang cocok dengan pencarian."
              : activeLocations.length === 0
                ? "Buat lokasi kerja dulu, baru karyawan bisa ditambahkan."
                : "Belum ada karyawan."}
          </EmptyState>
        ) : (
          <table className="w-full min-w-[860px]">
            <thead className="border-b border-border">
              <tr>
                <th className={thCls}>Nama</th>
                <th className={thCls}>NIK</th>
                <th className={thCls}>Jabatan</th>
                <th className={thCls}>Lokasi</th>
                <th className={thCls}>Mulai kerja</th>
                <th className={thCls}>Odoo ID</th>
                <th className={thCls}>Status</th>
                {canEdit && <th className={thCls} />}
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {data.items.map((emp) => (
                <tr key={emp.id}>
                  <td className={tdCls}>
                    <div className="font-medium">{emp.name}</div>
                    {emp.email && <div className="text-xs text-muted">{emp.email}</div>}
                  </td>
                  <td className={`${tdCls} font-mono`}>{emp.nik ?? "–"}</td>
                  <td className={tdCls}>{emp.jobTitle ?? "–"}</td>
                  <td className={tdCls}>{emp.workLocation?.name ?? "–"}</td>
                  <td className={`${tdCls} whitespace-nowrap`}>{emp.hireDate ? fmtDate(emp.hireDate) : <span className="text-muted">belum diisi</span>}</td>
                  <td className={`${tdCls} font-mono`}>{emp.odooId}</td>
                  <td className={tdCls}>
                    <Badge tone={emp.isActive ? "green" : "gray"}>{emp.isActive ? "Aktif" : "Nonaktif"}</Badge>
                  </td>
                  {canEdit && (
                    <td className={`${tdCls} text-right`}>
                      <button type="button" className={btnGhost} onClick={() => setEditing(emp)}>
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

      <div className="mt-4 flex items-center justify-between text-sm text-muted">
        <span>
          {data.total} karyawan · halaman {data.page} dari {totalPages}
        </span>
        <div className="flex gap-2">
          {data.page > 1 ? (
            <Link href={pageHref(data.page - 1)} className={btnGhost}>
              <ChevronLeft className="h-4 w-4" aria-hidden /> Sebelumnya
            </Link>
          ) : null}
          {data.page < totalPages ? (
            <Link href={pageHref(data.page + 1)} className={btnGhost}>
              Berikutnya <ChevronRight className="h-4 w-4" aria-hidden />
            </Link>
          ) : null}
        </div>
      </div>

      <Modal open={editing !== null} title={editing === "new" ? "Tambah karyawan" : "Ubah karyawan"} onClose={close}>
        {editing && (
          <form onSubmit={onSubmit} className="space-y-4" key={editing === "new" ? "new" : editing.id}>
            <Field label="Nama" htmlFor="name">
              <input id="name" name="name" required autoFocus defaultValue={editing === "new" ? "" : editing.name} className={inputCls} />
            </Field>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Odoo ID" htmlFor="odooId" hint={editing === "new" ? "ID karyawan di Odoo. Tidak bisa diubah nanti." : undefined}>
                <input
                  id="odooId"
                  name="odooId"
                  type="number"
                  min={1}
                  required={editing === "new"}
                  disabled={editing !== "new"}
                  defaultValue={editing === "new" ? "" : editing.odooId}
                  className={inputCls}
                />
              </Field>
              <Field label="NIK" htmlFor="nik">
                <input id="nik" name="nik" defaultValue={editing === "new" ? "" : (editing.nik ?? "")} className={inputCls} />
              </Field>
            </div>
            <Field label="Email" htmlFor="email">
              <input id="email" name="email" type="email" defaultValue={editing === "new" ? "" : (editing.email ?? "")} className={inputCls} />
            </Field>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Jabatan" htmlFor="jobTitle">
                <input id="jobTitle" name="jobTitle" defaultValue={editing === "new" ? "" : (editing.jobTitle ?? "")} className={inputCls} />
              </Field>
              <Field label="Grade" htmlFor="jobGrade">
                <input id="jobGrade" name="jobGrade" defaultValue={editing === "new" ? "" : (editing.jobGrade ?? "")} className={inputCls} />
              </Field>
            </div>
            <Field label="Tanggal mulai kerja" htmlFor="hireDate" hint="Dasar masa kerja, anniversary, dan saldo cuti. Wajib diisi bila aturan cuti mensyaratkan masa kerja minimum.">
              <input id="hireDate" name="hireDate" type="date" defaultValue={editing === "new" ? "" : editing.hireDate ? dateOnly(editing.hireDate) : ""} className={inputCls} />
            </Field>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Lokasi kerja" htmlFor="workLocationId">
                <select
                  id="workLocationId"
                  name="workLocationId"
                  required
                  defaultValue={editing === "new" ? "" : editing.workLocationId}
                  className={inputCls}
                >
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
              <Field label="Manager (Odoo ID)" htmlFor="parentOdooId" hint="Opsional">
                <input
                  id="parentOdooId"
                  name="parentOdooId"
                  type="number"
                  min={1}
                  defaultValue={editing === "new" ? "" : (editing.parentOdooId ?? "")}
                  className={inputCls}
                />
              </Field>
            </div>
            {editing !== "new" && (
              <label className="flex items-center gap-2 text-sm">
                <input type="checkbox" name="isActive" defaultChecked={editing.isActive} className="h-4 w-4" />
                Karyawan aktif
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
