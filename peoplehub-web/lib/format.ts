const DAY_MS = 86_400_000;

/** 'YYYY-MM-DD' atau ISO dari kolom @db.Date -> tanggal tanpa pergeseran timezone. */
export function dateOnly(value: string): string {
  return value.slice(0, 10);
}

export function fmtDate(value: string): string {
  return new Intl.DateTimeFormat("id-ID", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    timeZone: "UTC",
  }).format(new Date(`${dateOnly(value)}T00:00:00Z`));
}

export function fmtDayShort(value: string): string {
  return new Intl.DateTimeFormat("id-ID", {
    weekday: "short",
    day: "2-digit",
    month: "short",
    timeZone: "UTC",
  }).format(new Date(`${dateOnly(value)}T00:00:00Z`));
}

/** Jam lokal (HH:mm) dari instan UTC pada timezone lokasi. */
export function fmtTime(iso: string | null, timeZone: string): string {
  if (!iso) return "–";
  return new Intl.DateTimeFormat("id-ID", {
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
    timeZone,
  })
    .format(new Date(iso))
    .replace(".", ":");
}

export function addDaysStr(date: string, n: number): string {
  return new Date(new Date(`${dateOnly(date)}T00:00:00Z`).getTime() + n * DAY_MS).toISOString().slice(0, 10);
}

/** Tanggal hari ini (WIB) sebagai 'YYYY-MM-DD'. */
export function todayStr(timeZone = "Asia/Jakarta"): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone, year: "numeric", month: "2-digit", day: "2-digit" }).format(new Date());
}

/** Senin dari minggu yang memuat tanggal tersebut. */
export function mondayOf(date: string): string {
  const d = new Date(`${dateOnly(date)}T00:00:00Z`);
  const dow = (d.getUTCDay() + 6) % 7; // Senin=0
  return addDaysStr(date, -dow);
}

export function isDateStr(v: string | undefined): v is string {
  return !!v && /^\d{4}-\d{2}-\d{2}$/.test(v);
}

export function endTimeLabel(startTime: string, durationMinutes: number): string {
  const [h, m] = startTime.split(":").map(Number);
  const total = h * 60 + m + durationMinutes;
  const day = Math.floor(total / 1440);
  const hh = String(Math.floor((total % 1440) / 60)).padStart(2, "0");
  const mm = String(total % 60).padStart(2, "0");
  return `${hh}:${mm}${day > 0 ? ` (+${day})` : ""}`;
}

export function qs(params: Record<string, string | number | boolean | undefined | null>): string {
  const sp = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== null && v !== "") sp.set(k, String(v));
  }
  const s = sp.toString();
  return s ? `?${s}` : "";
}

/** Detik -> '45 dtk' / '2 mnt 5 dtk' / '1 j 3 mnt'. */
export function fmtDuration(seconds: number | null): string {
  if (seconds === null) return "–";
  if (seconds < 60) return `${seconds} dtk`;
  const m = Math.floor(seconds / 60);
  if (m < 60) return `${m} mnt${seconds % 60 ? ` ${seconds % 60} dtk` : ""}`;
  return `${Math.floor(m / 60)} j${m % 60 ? ` ${m % 60} mnt` : ""}`;
}

const dateTimeFmt = new Intl.DateTimeFormat("id-ID", {
  dateStyle: "medium",
  timeStyle: "medium",
  timeZone: "Asia/Jakarta",
  hourCycle: "h23",
});
const clockFmt = new Intl.DateTimeFormat("id-ID", { timeStyle: "medium", timeZone: "Asia/Jakarta", hourCycle: "h23" });

export function fmtDateTime(iso: string | null): string {
  return iso ? dateTimeFmt.format(new Date(iso)).replace(/\./g, ":") : "–";
}

export function fmtClock(iso: string): string {
  return clockFmt.format(new Date(iso)).replace(/\./g, ":");
}

/** Durasi jam: 8 -> '8', 7.83 -> '7,83' (format Indonesia). */
export function fmtHours(value: string | number): string {
  return new Intl.NumberFormat("id-ID", { maximumFractionDigits: 2 }).format(Number(value));
}
