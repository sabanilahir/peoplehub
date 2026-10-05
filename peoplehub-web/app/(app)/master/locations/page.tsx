import type { Metadata } from "next";
import { LocationsManager } from "@/components/locations-manager";
import { PageHeader } from "@/components/ui";
import { apiFetch, can } from "@/lib/api";
import type { WorkLocation } from "@/lib/types";

export const metadata: Metadata = { title: "Lokasi Kerja · PeopleHub" };

export default async function LocationsPage() {
  const [items, canEdit] = await Promise.all([
    apiFetch<WorkLocation[]>("/work-locations"),
    can("master.location.edit"),
  ]);

  return (
    <div className="mx-auto max-w-5xl">
      <PageHeader
        title="Lokasi Kerja"
        description="Kantor pusat dan cabang. Zona waktu lokasi dipakai untuk menghitung jam shift."
      />
      <LocationsManager items={items} canEdit={canEdit} />
    </div>
  );
}
