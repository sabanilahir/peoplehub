import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const TOKEN_COOKIE = "ph_token";

// Hanya cek keberadaan cookie. Keabsahan token diperiksa API di setiap request data;
// bila token kedaluwarsa, halaman mengarahkan ke /logout yang menghapus cookie.
export function proxy(request: NextRequest) {
  const hasToken = request.cookies.has(TOKEN_COOKIE);
  const { pathname } = request.nextUrl;

  if (!hasToken && pathname !== "/login") {
    return NextResponse.redirect(new URL("/login", request.url));
  }
  if (hasToken && pathname === "/login") {
    return NextResponse.redirect(new URL("/", request.url));
  }
  return NextResponse.next();
}

// /bff dikecualikan: route handler-nya sendiri membalas 401 JSON agar mudah ditangani komponen client.
export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|logout|bff).*)"],
};
