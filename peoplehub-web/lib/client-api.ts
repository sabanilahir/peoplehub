"use client";

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
  ) {
    super(message);
  }
}

/** Panggil API lewat jembatan /bff (cookie httpOnly dipasang server). */
export async function bff<T = unknown>(method: string, path: string, body?: unknown): Promise<T> {
  let res: Response;
  try {
    res = await fetch(`/bff/${path.replace(/^\//, "")}`, {
      method,
      headers: body !== undefined ? { "content-type": "application/json" } : undefined,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  } catch {
    throw new ApiError("Tidak dapat terhubung ke server.", 0);
  }

  if (res.status === 401) {
    // Sengaja navigasi penuh: /logout adalah route handler yang menghapus cookie, bukan halaman.
    // eslint-disable-next-line @next/next/no-location-assign-relative-destination
    window.location.href = "/logout";
    throw new ApiError("Sesi berakhir.", 401);
  }

  const text = await res.text();
  const data = text ? safeJson(text) : null;
  if (!res.ok) {
    const raw = (data as { message?: string | string[] } | null)?.message;
    const message = Array.isArray(raw) ? raw.join(" · ") : (raw ?? `Permintaan gagal (${res.status})`);
    throw new ApiError(message, res.status);
  }
  return data as T;
}

function safeJson(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}
