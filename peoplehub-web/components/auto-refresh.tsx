"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

/** Muat ulang data halaman secara berkala selama ada proses yang masih berjalan. */
export function AutoRefresh({ active, intervalMs = 2000 }: { active: boolean; intervalMs?: number }) {
  const router = useRouter();

  useEffect(() => {
    if (!active) return;
    const id = setInterval(() => router.refresh(), intervalMs);
    return () => clearInterval(id);
  }, [active, intervalMs, router]);

  if (!active) return null;
  return (
    <span role="status" className="inline-flex items-center gap-2 text-xs text-muted">
      <span className="relative flex h-2 w-2">
        <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-accent opacity-60" />
        <span className="relative inline-flex h-2 w-2 rounded-full bg-accent" />
      </span>
      Memperbarui otomatis
    </span>
  );
}
