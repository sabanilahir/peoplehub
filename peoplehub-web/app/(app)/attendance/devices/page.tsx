import type { Metadata } from "next";
import { DevicesManager } from "@/components/devices-manager";
import { Card, PageHeader } from "@/components/ui";
import { apiFetch, API_URL, can } from "@/lib/api";
import type { Device, WorkLocation } from "@/lib/types";

export const metadata: Metadata = { title: "Mesin Fingerprint · PeopleHub" };

export default async function DevicesPage() {
  const [devices, locations, canEdit] = await Promise.all([
    apiFetch<Device[]>("/devices"),
    apiFetch<WorkLocation[]>("/work-locations"),
    can("attendance.device.edit"),
  ]);

  return (
    <div className="mx-auto max-w-5xl space-y-6">
      <PageHeader
        title="Mesin Fingerprint"
        description="Daftarkan mesin dan petakan PIN di mesin ke karyawan agar punch masuk ke absensi yang benar."
      />

      <Card className="p-5 text-sm">
        <h2 className="mb-2 font-semibold">Cara mesin mengirim data</h2>
        <p className="text-muted">
          Mesin atau perantaranya mengirim punch ke endpoint berikut dengan header <code className="font-mono">x-api-key</code> (nilainya{" "}
          <code className="font-mono">PUNCH_API_KEY</code> di server). Mesin harus terdaftar di bawah ini; punch dari PIN yang belum dipetakan tetap
          disimpan dan otomatis ditautkan begitu PIN dipetakan.
        </p>
        <pre className="mt-3 overflow-x-auto rounded-lg bg-background p-3 font-mono text-xs">{`POST ${API_URL}/inbound/punches
{ "deviceSerial": "SN-001",
  "punches": [{ "enrollId": "7", "punchAt": "2026-10-05T09:25:00Z" }] }`}</pre>
      </Card>

      <DevicesManager devices={devices} locations={locations} canEdit={canEdit} />
    </div>
  );
}
