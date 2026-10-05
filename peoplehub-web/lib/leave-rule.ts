export interface RuleLike {
  minTenureMonths: number;
  accrualMode: "NONE" | "ANNIVERSARY";
  entitlementDays: string | number | null;
  firstGrantAnniversary: number;
  expiryMonths: number | null;
}

export function tenureLabel(months: number): string {
  const y = Math.floor(months / 12);
  const m = months % 12;
  return [y ? `${y} tahun` : "", m ? `${m} bulan` : ""].filter(Boolean).join(" ") || "0 bulan";
}

const num = (n: string | number | null) => Number(n ?? 0).toLocaleString("id-ID", { maximumFractionDigits: 2 });

/** Ringkasan aturan dalam kalimat biasa (dipakai di halaman dan pratinjau form). */
export function describeRule(r: RuleLike): string[] {
  const lines: string[] = [];
  lines.push(
    r.minTenureMonths > 0
      ? `Karyawan baru boleh mengambil cuti ini setelah bekerja minimal ${tenureLabel(r.minTenureMonths)}. Pengajuan sebelum itu ditolak.`
      : "Tidak ada syarat masa kerja: semua karyawan boleh mengambil cuti ini.",
  );
  if (r.accrualMode === "ANNIVERSARY") {
    lines.push(
      `Saldo baru ${num(r.entitlementDays)} hari diberikan setiap anniversary tanggal mulai kerja, mulai anniversary ke-${r.firstGrantAnniversary}.`,
    );
    lines.push(r.expiryMonths ? `Setiap saldo berlaku ${tenureLabel(r.expiryMonths)} sejak diberikan.` : "Saldo tidak kedaluwarsa.");
    if (r.firstGrantAnniversary * 12 < r.minTenureMonths) {
      lines.push("Perhatian: saldo pertama diberikan sebelum syarat masa kerja terpenuhi, sehingga belum bisa dipakai saat itu.");
    }
  } else {
    lines.push("Tidak ada pemberian saldo otomatis (saldo dikelola di sistem lain, mis. Odoo).");
  }
  return lines;
}
