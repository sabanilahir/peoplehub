import type { Metadata } from "next";
import { ShiftsManager } from "@/components/shifts-manager";
import { PageHeader } from "@/components/ui";
import { apiFetch, can } from "@/lib/api";
import type { Shift } from "@/lib/types";

export const metadata: Metadata = { title: "Shift · PeopleHub" };

export default async function ShiftsPage() {
  const [items, canEdit] = await Promise.all([apiFetch<Shift[]>("/shifts"), can("schedule.shift.edit")]);

  return (
    <div className="mx-auto max-w-4xl">
      <PageHeader
        title="Shift"
        description="Template jam kerja. Shift lintas hari (mis. 16:00 selama 8 jam) ditandai (+1) pada jam selesai."
      />
      <ShiftsManager items={items} canEdit={canEdit} />
    </div>
  );
}
