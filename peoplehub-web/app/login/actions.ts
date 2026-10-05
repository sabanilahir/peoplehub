"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { API_URL, TOKEN_COOKIE } from "@/lib/api";

export interface LoginState {
  error?: string;
  email?: string;
}

const TOKEN_MAX_AGE = 60 * 60 * 8; // selaras dengan JWT_EXPIRES_IN API (8 jam)

export async function login(
  _prev: LoginState,
  formData: FormData,
): Promise<LoginState> {
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");

  if (!email || !password) {
    return { error: "Username dan password wajib diisi.", email };
  }

  let res: Response;
  try {
    res = await fetch(`${API_URL}/auth/login`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ email, password }),
      cache: "no-store",
    });
  } catch {
    return { error: "Server PeopleHub tidak dapat dihubungi.", email };
  }

  if (res.status === 401) return { error: "Username atau password salah.", email };
  if (res.status === 400) return { error: "Username dan password wajib diisi.", email };
  if (!res.ok) return { error: "Terjadi kesalahan di server. Coba lagi.", email };

  const { accessToken } = (await res.json()) as { accessToken: string };
  (await cookies()).set(TOKEN_COOKIE, accessToken, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: TOKEN_MAX_AGE,
  });
  redirect("/");
}
