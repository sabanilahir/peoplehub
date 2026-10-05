import { cookies } from "next/headers";
import { API_URL, TOKEN_COOKIE } from "@/lib/api";

// Jembatan untuk komponen client: meneruskan request ke API PeopleHub dengan token dari cookie httpOnly.
// Token tidak pernah sampai ke JavaScript di browser.
const ALLOWED = new Set(["GET", "POST", "PUT", "PATCH", "DELETE"]);

async function forward(req: Request, ctx: RouteContext<"/bff/[...path]">) {
  if (!ALLOWED.has(req.method)) {
    return Response.json({ message: "Method tidak didukung" }, { status: 405 });
  }
  const token = (await cookies()).get(TOKEN_COOKIE)?.value;
  if (!token) return Response.json({ message: "Sesi berakhir" }, { status: 401 });

  const { path } = await ctx.params;
  if (path.some((seg) => seg === ".." || seg === "." || seg === "")) {
    return Response.json({ message: "Path tidak valid" }, { status: 400 });
  }

  const { search } = new URL(req.url);
  const hasBody = req.method !== "GET";
  let res: Response;
  try {
    res = await fetch(`${API_URL}/${path.map(encodeURIComponent).join("/")}${search}`, {
      method: req.method,
      headers: { Authorization: `Bearer ${token}`, "content-type": "application/json" },
      body: hasBody ? await req.text() : undefined,
      cache: "no-store",
    });
  } catch {
    return Response.json({ message: "Server PeopleHub tidak dapat dihubungi" }, { status: 502 });
  }

  // Teruskan header unduhan (CSV) agar browser menyimpan sebagai file
  const headers: Record<string, string> = { "content-type": res.headers.get("content-type") ?? "application/json" };
  const disposition = res.headers.get("content-disposition");
  if (disposition) headers["content-disposition"] = disposition;

  return new Response(await res.text(), { status: res.status, headers });
}

export const GET = forward;
export const POST = forward;
export const PUT = forward;
export const PATCH = forward;
export const DELETE = forward;
