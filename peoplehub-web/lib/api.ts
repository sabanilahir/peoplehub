import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { cache } from "react";

export const TOKEN_COOKIE = "ph_token";
export const API_URL = process.env.API_URL ?? "http://localhost:3100/api";

export interface MenuNode {
  id: string;
  code: string;
  label: string;
  path: string | null;
  icon: string | null;
  children: MenuNode[];
}

export interface Me {
  id: string;
  email: string;
  permissions: string[];
}

/** Panggil API PeopleHub dari server component/action dengan token dari cookie httpOnly. */
export async function apiFetch<T>(path: string): Promise<T> {
  const token = (await cookies()).get(TOKEN_COOKIE)?.value;
  if (!token) redirect("/login");

  const res = await fetch(`${API_URL}${path}`, {
    headers: { Authorization: `Bearer ${token}` },
    cache: "no-store",
  });
  // Token kedaluwarsa/tidak valid: hapus cookie lewat route /logout
  if (res.status === 401) redirect("/logout");
  if (!res.ok) throw new Error(`API ${path} gagal (${res.status})`);
  return res.json() as Promise<T>;
}

/** /auth/me, di-cache per request agar layout dan halaman tidak memanggil API dua kali. */
export const getMe = cache(() => apiFetch<Me>("/auth/me"));

export async function can(permission: string): Promise<boolean> {
  return (await getMe()).permissions.includes(permission);
}
