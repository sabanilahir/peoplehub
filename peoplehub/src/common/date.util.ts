const DAY_MS = 86_400_000;

/** 'YYYY-MM-DD' -> Date (00:00 UTC), cocok untuk kolom @db.Date. */
export function parseDate(s: string): Date {
  return new Date(`${s.slice(0, 10)}T00:00:00.000Z`);
}

export function addDays(d: Date, n: number): Date {
  return new Date(d.getTime() + n * DAY_MS);
}

export function toDateString(d: Date): string {
  return d.toISOString().slice(0, 10);
}

/** Offset zona waktu (ms, timur UTC positif) pada instan tertentu. */
function tzOffsetMs(instant: Date, timeZone: string): number {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    hourCycle: 'h23',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  }).formatToParts(instant);
  const get = (t: string) => Number(parts.find((p) => p.type === t)!.value);
  const asUtc = Date.UTC(get('year'), get('month') - 1, get('day'), get('hour'), get('minute'), get('second'));
  return asUtc - Math.floor(instant.getTime() / 1000) * 1000;
}

/** Waktu lokal lokasi ('YYYY-MM-DD' + 'HH:mm') -> instan UTC. */
export function localToUtc(date: string, time: string, timeZone: string): Date {
  const [y, m, d] = date.slice(0, 10).split('-').map(Number);
  const [hh, mm] = time.split(':').map(Number);
  const guess = new Date(Date.UTC(y, m - 1, d, hh, mm));
  const first = new Date(guess.getTime() - tzOffsetMs(guess, timeZone));
  // Hitung ulang sekali untuk zona yang punya DST
  return new Date(guess.getTime() - tzOffsetMs(first, timeZone));
}

/** Instan UTC -> tanggal kalender lokal 'YYYY-MM-DD' pada timezone tertentu. */
export function toLocalDate(instant: Date, timeZone: string): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone, year: 'numeric', month: '2-digit', day: '2-digit' }).format(instant);
}

/** Offset zona waktu (ms, timur UTC positif) pada instan tertentu. */
export function offsetMs(instant: Date, timeZone: string): number {
  return tzOffsetMs(instant, timeZone);
}

/** Instan UTC -> ISO 8601 dengan offset zona lokasi, mis. 2026-09-15T16:25:00+07:00. */
export function toOffsetIso(instant: Date, timeZone: string): string {
  const off = tzOffsetMs(instant, timeZone);
  const local = new Date(instant.getTime() + off).toISOString().slice(0, 19);
  const sign = off >= 0 ? '+' : '-';
  const abs = Math.abs(off) / 60_000;
  const hh = String(Math.floor(abs / 60)).padStart(2, '0');
  const mm = String(abs % 60).padStart(2, '0');
  return `${local}${sign}${hh}:${mm}`;
}

/** Tambah bulan pada tanggal (UTC); hari dijepit ke akhir bulan (31 Jan + 1 bulan = 28/29 Feb). */
export function addMonths(d: Date, n: number): Date {
  const first = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + n, 1));
  const lastDay = new Date(Date.UTC(first.getUTCFullYear(), first.getUTCMonth() + 1, 0)).getUTCDate();
  return new Date(Date.UTC(first.getUTCFullYear(), first.getUTCMonth(), Math.min(d.getUTCDate(), lastDay)));
}

/** Jumlah bulan penuh dari `from` sampai `to` (0 bila `to` sebelum `from`). */
export function monthsBetween(from: Date, to: Date): number {
  if (to.getTime() < from.getTime()) return 0;
  let m = (to.getUTCFullYear() - from.getUTCFullYear()) * 12 + (to.getUTCMonth() - from.getUTCMonth());
  while (m > 0 && addMonths(from, m).getTime() > to.getTime()) m--;
  return m;
}
