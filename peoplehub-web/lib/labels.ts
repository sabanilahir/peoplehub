export const STATUS_LABEL: Record<string, string> = {
  PRESENT: "Hadir",
  LATE: "Terlambat",
  ABSENT: "Alpa",
  ON_LEAVE: "Cuti",
  OFFDAY: "Libur",
  HOLIDAY: "Hari libur",
  INCOMPLETE: "Tidak lengkap",
};

export const EVENT_TYPE_LABEL: Record<string, string> = {
  PUBLIC_HOLIDAY: "Libur nasional",
  COLLECTIVE_LEAVE: "Cuti bersama",
  BUSINESS_TRIP: "Dinas luar",
  TRAINING: "Pelatihan",
  COMPANY_EVENT: "Acara perusahaan",
};

export const LEAVE_KIND_LABEL: Record<string, string> = {
  ANNUAL: "Tahunan",
  SICK: "Sakit",
  UNPAID: "Tanpa gaji",
  OTHER: "Lainnya",
};

export const REQUEST_STATUS_LABEL: Record<string, string> = {
  PENDING: "Menunggu",
  APPROVED: "Disetujui",
  REJECTED: "Ditolak",
  CANCELLED: "Dibatalkan",
};

export const PROCESS_STATUS_LABEL: Record<string, string> = {
  RECEIVED: "Antre",
  VALIDATING: "Berjalan",
  APPLIED: "Selesai",
  PARTIAL: "Selesai dengan error",
  FAILED: "Gagal",
};

export const PROCESS_TYPE_LABEL: Record<string, string> = {
  TIME_ENTRY: "Impor Time Entries",
  SCHEDULE: "Impor Jadwal",
  LEAVE: "Impor Cuti",
  CALENDAR: "Impor Kalender",
  OVERTIME_PLAN: "Impor Plan Lembur",
  OVERTIME_REALIZATION: "Impor Realisasi Lembur",
};

export const ACCRUAL_LABEL: Record<string, string> = {
  NONE: "Tidak ada pemberian otomatis",
  ANNIVERSARY: "Setiap anniversary masa kerja",
};
