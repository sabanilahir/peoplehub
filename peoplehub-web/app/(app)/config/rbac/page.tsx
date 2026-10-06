"use client";

import { useState, useEffect, useCallback } from "react";
import { clientFetch } from "@/lib/client-api";
import { Shield, ShieldCheck, Users, Menu as MenuIcon, Plus, Edit, Trash2, X, ChevronDown, Check } from "lucide-react";

interface Role { id: string; code: string; name: string; description: string | null; isSystem: boolean; _count: { users: number; permissions: number }; }
interface Permission { id: string; code: string; module: string; _count: { rolePermissions: number }; }
interface User { id: string; email: string; isActive: boolean; createdAt: string; roles: { role: { id: string; code: string; name: string } }[]; }
interface Menu { id: string; code: string; label: string; path: string | null; icon: string | null; sortOrder: number; isActive: boolean; children: Menu[]; requiredPermission?: { code: string } | null; }

export default function RbacPage() {
  const [tab, setTab] = useState<"roles"|"permissions"|"users"|"menus">("roles");
  const [roles, setRoles] = useState<Role[]>([]);
  const [permissions, setPermissions] = useState<Permission[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [menus, setMenus] = useState<Menu[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [modalType, setModalType] = useState<string>("");
  const [editItem, setEditItem] = useState<unknown>(null);
  const [form, setForm] = useState<Record<string, string>>({});
  const [search, setSearch] = useState("");

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      if (tab === "roles") setRoles(await clientFetch<Role[]>("/rbac/roles"));
      else if (tab === "permissions") { const d = await clientFetch<{ permissions: Permission[] }>("/rbac/permissions"); setPermissions(d.permissions); }
      else if (tab === "users") setUsers(await clientFetch<User[]>("/rbac/users" + (search ? "?search=" + search : "")));
      else if (tab === "menus") setMenus(await clientFetch<Menu[]>("/rbac/menus/tree"));
    } catch (e) { console.error(e); }
    finally { setLoading(false); }
  }, [tab, search]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const openCreate = (type: string) => { setModalType(type); setEditItem(null); setForm({}); setShowModal(true); };
  const openEdit = (type: string, item: unknown) => { setModalType(type); setEditItem(item); setForm(item as Record<string, string>); setShowModal(true); };

  const handleSubmit = async () => {
    try {
      if (modalType === "role") {
        if (editItem) await clientFetch(`/rbac/roles/${(editItem as Role).id}`, { method: "PATCH", body: JSON.stringify({ name: form.name, description: form.description }) });
        else await clientFetch("/rbac/roles", { method: "POST", body: JSON.stringify({ code: form.code, name: form.name, description: form.description }) });
      } else if (modalType === "permission") {
        if (!editItem) await clientFetch("/rbac/permissions", { method: "POST", body: JSON.stringify({ code: form.code, name: form.name, module: form.module, description: form.description }) });
      } else if (modalType === "user") {
        if (editItem) await clientFetch(`/rbac/users/${(editItem as User).id}`, { method: "PATCH", body: JSON.stringify({ name: form.name, ...(form.password ? { password: form.password } : {}) }) });
        else await clientFetch("/rbac/users", { method: "POST", body: JSON.stringify({ email: form.email, password: form.password, name: form.name }) });
      } else if (modalType === "menu") {
        if (editItem) await clientFetch(`/rbac/menus/${(editItem as Menu).id}`, { method: "PATCH", body: JSON.stringify({ label: form.label, path: form.path, icon: form.icon, sortOrder: parseInt(form.sortOrder) || 0 }) });
        else await clientFetch("/rbac/menus", { method: "POST", body: JSON.stringify({ code: form.code, label: form.label, path: form.path, icon: form.icon, sortOrder: parseInt(form.sortOrder) || 0 }) });
      }
      setShowModal(false);
      fetchData();
    } catch (e) { alert("Gagal menyimpan: " + (e as Error).message); }
  };

  const handleDelete = async (type: string, id: string) => {
    if (!confirm("Yakin hapus?")) return;
    try {
      await clientFetch(`/rbac/${type}/${id}`, { method: "DELETE" });
      fetchData();
    } catch (e) { alert("Gagal: " + (e as Error).message); }
  };

  const groupedPerms = permissions.reduce((acc, p) => { if (!acc[p.module]) acc[p.module] = []; acc[p.module].push(p); return acc; }, {} as Record<string, Permission[]>);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div><h1 className="text-2xl font-semibold">RBAC Management</h1><p className="text-muted text-sm">Kelola Roles, Permissions, Users, dan Menus</p></div>
      </div>

      <div className="flex gap-1 border-b border-border">
        {([{key:"roles",label:"Roles",icon:Shield},{key:"permissions",label:"Permissions",icon:ShieldCheck},{key:"users",label:"Users",icon:Users},{key:"menus",label:"Menus",icon:MenuIcon}] as const).map((t) => (
          <button key={t.key} onClick={() => setTab(t.key)} className={`flex items-center gap-2 px-4 py-2 text-sm border-b-2 -mb-px transition ${tab === t.key ? "border-primary text-primary" : "border-transparent text-muted hover:text-foreground"}`}>
            <t.icon className="h-4 w-4" />{t.label}
          </button>
        ))}
      </div>

      {loading ? <div className="text-center py-8 text-muted">Memuat...</div> : (
        <>
          {tab === "roles" && (
            <div className="card">
              <div className="p-3 border-b border-border flex justify-end"><button onClick={() => openCreate("role")} className="btn btn-primary"><Plus className="h-4 w-4" /> Tambah</button></div>
              <table className="w-full"><thead><tr className="border-b border-border"><th className="text-left py-3 px-4">Nama</th><th className="text-left py-3 px-4">Kode</th><th className="text-center py-3 px-4">Users</th><th className="text-center py-3 px-4">Permissions</th><th className="text-right py-3 px-4">Aksi</th></tr></thead>
              <tbody>{roles.map((r) => (<tr key={r.id} className="border-b border-border hover:bg-background/50"><td className="py-3 px-4 flex items-center gap-2"><Shield className="h-4 w-4 text-muted" /><span className="font-medium">{r.name}</span>{r.isSystem && <span className="text-xs bg-muted px-2 py-0.5 rounded">System</span>}</td><td className="py-3 px-4 text-muted font-mono">{r.code}</td><td className="py-3 px-4 text-center">{r._count.users}</td><td className="py-3 px-4 text-center">{r._count.permissions}</td><td className="py-3 px-4 text-right"><button onClick={() => openEdit("role", r)} className="p-1.5 hover:bg-background rounded"><Edit className="h-4 w-4" /></button>{!r.isSystem && <button onClick={() => handleDelete("roles", r.id)} className="p-1.5 hover:bg-background rounded text-red-600"><Trash2 className="h-4 w-4" /></button>}</td></tr>)}</tbody>
              </table>
              {roles.length === 0 && <div className="text-center py-8 text-muted">Belum ada role</div>}
            </div>
          )}

          {tab === "permissions" && (
            <div className="space-y-4">
              <div className="flex justify-end"><button onClick={() => openCreate("permission")} className="btn btn-primary"><Plus className="h-4 w-4" /> Tambah</button></div>
              {Object.entries(groupedPerms).map(([mod, perms]) => (
                <div key={mod} className="card"><div className="p-3 border-b border-border bg-muted/20"><h3 className="font-semibold text-sm uppercase">{mod}</h3></div>
                  <table className="w-full"><tbody>{perms.map((p) => (<tr key={p.id} className="border-b border-border last:border-0 hover:bg-background/50"><td className="py-2 px-3"><span className="font-mono text-sm">{p.code}</span></td><td className="py-2 px-3 text-right"><button onClick={() => handleDelete("permissions", p.id)} className="p-1.5 hover:bg-background rounded text-red-600"><Trash2 className="h-4 w-4" /></button></td></tr>)}</tbody></table>
                </div>
              ))}
            </div>
          )}

          {tab === "users" && (
            <div className="card">
              <div className="p-3 border-b border-border flex gap-2">
                <input type="text" placeholder="Cari..." value={search} onChange={(e) => setSearch(e.target.value)} className="input max-w-xs" />
                <button onClick={() => openCreate("user")} className="btn btn-primary"><Plus className="h-4 w-4" /> Tambah</button>
              </div>
              <table className="w-full"><thead><tr className="border-b border-border"><th className="text-left py-3 px-4">Email</th><th className="text-left py-3 px-4">Roles</th><th className="text-center py-3 px-4">Status</th><th className="text-right py-3 px-4">Aksi</th></tr></thead>
              <tbody>{users.map((u) => (<tr key={u.id} className="border-b border-border hover:bg-background/50"><td className="py-3 px-4"><Users className="h-4 w-4 text-muted inline mr-2" />{u.email}</td><td className="py-3 px-4"><div className="flex gap-1">{u.roles.map((r) => (<span key={r.role.id} className="text-xs bg-muted px-2 py-0.5 rounded">{r.role.name}</span>))}</div></td><td className="py-3 px-4 text-center">{u.isActive ? <span className="text-green-600">Aktif</span> : <span className="text-red-600">Nonaktif</span>}</td><td className="py-3 px-4 text-right"><button onClick={() => openEdit("user", u)} className="p-1.5 hover:bg-background rounded"><Edit className="h-4 w-4" /></button><button onClick={() => handleDelete("users", u.id)} className="p-1.5 hover:bg-background rounded text-red-600"><Trash2 className="h-4 w-4" /></button></td></tr>)}</tbody>
              </table>
            </div>
          )}

          {tab === "menus" && (
            <div className="card">
              <div className="p-3 border-b border-border flex justify-end"><button onClick={() => openCreate("menu")} className="btn btn-primary"><Plus className="h-4 w-4" /> Tambah</button></div>
              {menus.map((m) => (
                <div key={m.id} className="border-b border-border last:border-0"><div className="flex items-center gap-2 py-2 px-3 hover:bg-background/50"><MenuIcon className="h-4 w-4 text-muted" /><span className="flex-1 font-medium">{m.label}</span>{m.path && <span className="text-xs text-muted font-mono">{m.path}</span>}{m.requiredPermission && <span className="text-xs bg-muted px-2 py-0.5 rounded">{m.requiredPermission.code}</span>}<button onClick={() => openEdit("menu", m)} className="p-1 hover:bg-background rounded"><Edit className="h-4 w-4" /></button><button onClick={() => handleDelete("menus", m.id)} className="p-1 hover:bg-background rounded text-red-600"><Trash2 className="h-4 w-4" /></button></div>
                  {m.children && m.children.map((c) => (<div key={c.id} className="flex items-center gap-2 py-2 px-3 pl-8 hover:bg-background/50 border-t border-border/50"><MenuIcon className="h-4 w-4 text-muted" /><span className="flex-1">{c.label}</span>{c.path && <span className="text-xs text-muted font-mono">{c.path}</span>}<button onClick={() => openEdit("menu", c)} className="p-1 hover:bg-background rounded"><Edit className="h-4 w-4" /></button><button onClick={() => handleDelete("menus", c.id)} className="p-1 hover:bg-background rounded text-red-600"><Trash2 className="h-4 w-4" /></button></div>))}
                </div>
              ))}
              {menus.length === 0 && <div className="text-center py-8 text-muted">Belum ada menu</div>}
            </div>
          )}
        </>
      )}

      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-surface rounded-lg shadow-lg w-full max-w-md">
            <div className="flex items-center justify-between p-4 border-b border-border"><h2 className="font-semibold">{editItem ? "Edit" : "Tambah"} {modalType}</h2><button onClick={() => setShowModal(false)} className="p-1 hover:bg-background rounded"><X className="h-5 w-5" /></button></div>
            <div className="p-4 space-y-4">
              {!editItem && (modalType === "role" || modalType === "permission" || modalType === "menu") && (
                <div><label className="block text-sm font-medium mb-1">Kode</label><input type="text" value={form.code || ""} onChange={(e) => setForm({...form, code: e.target.value})} className="input w-full" required /></div>
              )}
              {(modalType === "user") && !editItem && (
                <><div><label className="block text-sm font-medium mb-1">Email</label><input type="email" value={form.email || ""} onChange={(e) => setForm({...form, email: e.target.value})} className="input w-full" required /></div><div><label className="block text-sm font-medium mb-1">Password</label><input type="password" value={form.password || ""} onChange={(e) => setForm({...form, password: e.target.value})} className="input w-full" required /></div></>
              )}
              {modalType === "permission" && <div><label className="block text-sm font-medium mb-1">Module</label><input type="text" value={form.module || ""} onChange={(e) => setForm({...form, module: e.target.value})} className="input w-full" required /></div>}
              <div><label className="block text-sm font-medium mb-1">Nama/Label</label><input type="text" value={form.name || form.label || ""} onChange={(e) => setForm({...form, name: e.target.value, label: e.target.value})} className="input w-full" required /></div>
              {(modalType === "role" || modalType === "permission") && <div><label className="block text-sm font-medium mb-1">Description</label><textarea value={form.description || ""} onChange={(e) => setForm({...form, description: e.target.value})} className="input w-full" rows={2} /></div>}
              {modalType === "menu" && <><div><label className="block text-sm font-medium mb-1">Path</label><input type="text" value={form.path || ""} onChange={(e) => setForm({...form, path: e.target.value})} className="input w-full" placeholder="/dashboard" /></div><div><label className="block text-sm font-medium mb-1">Icon</label><input type="text" value={form.icon || ""} onChange={(e) => setForm({...form, icon: e.target.value})} className="input w-full" placeholder="dashboard" /></div><div><label className="block text-sm font-medium mb-1">Sort Order</label><input type="number" value={form.sortOrder || "0"} onChange={(e) => setForm({...form, sortOrder: e.target.value})} className="input w-full" /></div></>}
              {editItem && modalType === "user" && <div><label className="block text-sm font-medium mb-1">Password Baru (kosongkan jika tidak diubah)</label><input type="password" value={form.password || ""} onChange={(e) => setForm({...form, password: e.target.value})} className="input w-full" /></div>}
              <div className="flex justify-end gap-2 pt-2"><button onClick={() => setShowModal(false)} className="btn btn-secondary">Batal</button><button onClick={handleSubmit} className="btn btn-primary"><Check className="h-4 w-4" /> Simpan</button></div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}