"use client";

import { Download, FileDown, Upload } from "lucide-react";
import { useRouter } from "next/navigation";
import { useRef, useState, type ChangeEvent } from "react";
import { bff } from "@/lib/client-api";
import type { WorkLocation } from "@/lib/types";
import { Modal } from "./modal";
import { btnGhost, btnPrimary, ErrorNote, Field, inputCls } from "./ui";

const MAX_BYTES = 10 * 1024 * 1024;

export function TimeEntriesActions({
  canUpload,
  locations,
  defaultPeriod,
}: {
  canUpload: boolean;
  locations: WorkLocation[];
  defaultPeriod: string;
}) {
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [downloadOpen, setDownloadOpen] = useState(false);

  async function onFile(e: ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = ""; // izinkan memilih file yang sama lagi setelah diperbaiki
    if (!file) return;

    setUploadError(null);
    if (file.size > MAX_BYTES) {
      setUploadError(`Ukuran file ${(file.size / 1024 / 1024).toFixed(1)} MB melebihi batas 10 MB.`);
      return;
    }
    setUploading(true);
    try {
      const content = await file.text();
      // File yang format-nya salah ditolak di sini (400). Selebihnya diproses di latar belakang.
      const accepted = await bff<{ batchId: string }>("POST", "inbound/time-entries", { fileName: file.name, content });
      router.push(`/process-monitor/${accepted.batchId}`);
    } catch (err) {
      setUploadError(err instanceof Error ? err.message : "Gagal mengunggah file.");
      setUploading(false);
    }
  }

  return (
    <>
      <div className="flex flex-wrap items-center gap-2">
        {canUpload && (
          <>
            <input ref={fileRef} type="file" accept=".csv,text/csv" onChange={onFile} className="sr-only" aria-label="Pilih file CSV" tabIndex={-1} />
            <button type="button" className={btnPrimary} onClick={() => fileRef.current?.click()} disabled={uploading}>
              <Upload className="h-4 w-4" aria-hidden />
              {uploading ? "Mengunggah…" : "Unggah CSV"}
            </button>
          </>
        )}
        <button type="button" className={btnGhost} onClick={() => setDownloadOpen(true)}>
          <Download className="h-4 w-4" aria-hidden /> Unduh CSV
        </button>
        <a href="/bff/time-entries/template" className={btnGhost} download>
          <FileDown className="h-4 w-4" aria-hidden /> Template
        </a>
      </div>
      {uploadError && (
        <div className="mt-3 w-full basis-full">
          <ErrorNote>{uploadError}</ErrorNote>
        </div>
      )}

      {/* Dialog unduh: form GET biasa; server membalas file dengan Content-Disposition */}
      <Modal open={downloadOpen} title="Unduh time entries (CSV)" onClose={() => setDownloadOpen(false)}>
        <form action="/bff/time-entries/export" method="get" onSubmit={() => setTimeout(() => setDownloadOpen(false), 300)} className="space-y-4">
          <Field label="Sumber data" htmlFor="source">
            <select id="source" name="source" defaultValue="attendance" className={inputCls}>
              <option value="attendance">Absensi PeopleHub (jam masuk dan pulang aktual)</option>
              <option value="imported">Hasil unggahan CSV</option>
            </select>
          </Field>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Periode payroll" htmlFor="payrollPeriod">
              <input id="payrollPeriod" name="payrollPeriod" type="month" required defaultValue={defaultPeriod} className={inputCls} />
            </Field>
            <Field label="Lokasi" htmlFor="workLocationId">
              <select id="workLocationId" name="workLocationId" defaultValue="" className={inputCls}>
                <option value="">Semua lokasi</option>
                {locations.map((l) => (
                  <option key={l.id} value={l.id}>
                    {l.name}
                  </option>
                ))}
              </select>
            </Field>
          </div>
          <ul className="list-disc space-y-1 pl-5 text-xs text-muted">
            <li>Periode payroll saat ini = satu bulan kalender (tanggal 1 sampai akhir bulan).</li>
            <li>Dari absensi: hanya hari dengan jam masuk dan jam pulang yang diekspor. Karyawan tanpa NIK dilewati.</li>
            <li>Kolom duration berisi lama kerja dalam jam (selisih jam pulang dan masuk).</li>
            <li>Waktu ditulis dengan offset zona lokasi, mis. +07:00, sehingga bisa diunggah kembali tanpa ambigu.</li>
          </ul>
          <div className="flex justify-end gap-2 pt-1">
            <button type="button" className={btnGhost} onClick={() => setDownloadOpen(false)}>
              Batal
            </button>
            <button type="submit" className={btnPrimary}>
              <Download className="h-4 w-4" aria-hidden /> Unduh
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}
