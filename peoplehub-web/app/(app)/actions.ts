"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { TOKEN_COOKIE } from "@/lib/api";

export async function logout() {
  (await cookies()).delete(TOKEN_COOKIE);
  redirect("/login");
}
