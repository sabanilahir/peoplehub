import type { Metadata } from "next";
import { EmployeesManager } from "@/components/employees-manager";
import { PageHeader } from "@/components/ui";
import { apiFetch, can } from "@/lib/api";
import { qs } from "@/lib/format";
import type { Employee, Paged, WorkLocation } from "@/lib/types";

export const metadata: Metadata = { title: "Karyawan · PeopleHub" };

export default async function EmployeesPage({ searchParams }: PageProps<"/master/employees">) {
  const sp = await searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const q = one(sp.q);
  const location = one(sp.location);
  const page = Math.max(1, Number(one(sp.page)) || 1);

  const [data, locations, canEdit] = await Promise.all([
    apiFetch<Paged<Employee>>(`/employees${qs({ q, workLocationId: location, page, pageSize: 25 })}`),
    apiFetch<WorkLocation[]>("/work-locations"),
    can("master.employee.edit"),
  ]);

  return (
    <div className="mx-auto max-w-6xl">
      <PageHeader
        title="Karyawan"
        description="Data karyawan. Master utamanya ada di Odoo; perubahan manual di sini untuk koreksi atau data awal."
      />
      <EmployeesManager
        data={data}
        locations={locations}
        canEdit={canEdit}
        filters={{ q: q ?? "", location: location ?? "" }}
      />
    </div>
  );
}
