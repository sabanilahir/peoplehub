# PeopleHub API

API HR modular (NestJS + Prisma + PostgreSQL): master karyawan dan lokasi, shift dan jadwal, absensi dari mesin fingerprint,
aturan keterlambatan, aturan cuti (masa kerja dan saldo anniversary), time entries CSV, dan Process Monitor.
Antarmuka webnya ada di folder `peoplehub-web`.

## Prasyarat
- Node.js 22.13 atau lebih baru (dikembangkan dengan 24)
- PostgreSQL 16 atau lebih baru

## Mulai
```bash
cp .env.example .env        # Windows: copy .env.example .env  (lalu isi DATABASE_URL, JWT_SECRET, PUNCH_API_KEY)
npm install                 # otomatis menjalankan `prisma generate`
npx prisma migrate deploy   # membuat semua tabel (database `peoplehub` harus sudah ada)
npm run db:seed             # permission, role, menu, dan akun admin dari .env
npm run build
npm start                   # http://localhost:3100/api
```
Mode pengembangan dengan muat-ulang otomatis: `npm run start:dev`.

Login API: `POST /api/auth/login` dengan `{ "email": "<SEED_ADMIN_EMAIL>", "password": "<SEED_ADMIN_PASSWORD>" }`.
Kolom `email` juga menerima username (mis. `admin`).

## Data contoh
Dengan API sedang berjalan:
```bash
npm run sample:load    # 10 karyawan, 3 lokasi, jadwal, punch, cuti, dan aturan, September 2026
npm run sample:reset   # hapus data contoh (berprefiks DEMO-); aturan cuti global tidak dihapus
```
`samples/time-entries-sample.csv` adalah contoh file untuk menu Time Entries (37 baris valid, 5 sengaja salah).

## Skrip
| Perintah | Fungsi |
|---|---|
| `npm run build` / `npm start` | Build dan jalankan API |
| `npm run start:dev` | Jalankan dengan watch |
| `npm run typecheck` | Periksa tipe TypeScript |
| `npm run db:seed` | Seed permission, role, menu, admin (idempoten) |
| `npm run sample:load` / `sample:reset` | Muat / hapus data contoh |
| `npx prisma migrate dev --name <nama>` | Buat migrasi baru saat mengubah `prisma/schema.prisma` |

## Variabel lingkungan (.env)
| Nama | Keterangan |
|---|---|
| `DATABASE_URL` | Koneksi PostgreSQL |
| `JWT_SECRET`, `JWT_EXPIRES_IN` | Penanda token login dan masa berlakunya |
| `PORT` | Port API (default 3100) |
| `PUNCH_API_KEY` | Kunci webhook fingerprint (header `x-api-key`) |
| `SEED_ADMIN_EMAIL`, `SEED_ADMIN_PASSWORD` | Akun admin awal untuk `db:seed` dan `sample:load` |

## Modul (`src/modules`)
`auth`, `rbac` (role, permission, menu), `employee` (lokasi dan karyawan), `schedule` (shift, jadwal, kalender),
`attendance` (aturan, mesin dan PIN, webhook punch, rekap harian), `request` (cuti, hanya baca + inbound),
`leave-rule` (aturan cuti), `overtime` (aturan dan SPL), `time-entry` (impor dan ekspor CSV), `process-monitor`.

## Catatan desain
- Persetujuan cuti dan lembur dilakukan di Odoo; PeopleHub hanya menerima hasilnya lewat jalur inbound
  (`POST /api/inbound/leave-requests`) dan tidak punya alur approval sendiri.
- Antrean (Redis/BullMQ) belum dipakai; proses impor berjalan di dalam server dan dipantau di Process Monitor.
- Waktu disimpan UTC; jam shift dan tampilan memakai zona waktu lokasi (WIB/WITA/WIT).
- Keterlambatan hanya dicatat (menit di atas toleransi), tanpa denda atau payroll.

## Format CSV time entries
`employee_number` (NIK), `start_datetime`, `end_datetime`, `work_schedule` (kode shift), `payroll_period` (YYYY-MM), `duration` (jam).
Waktu tanpa zona dibaca sebagai waktu lokal lokasi karyawan. Unggah ulang file yang sama memperbarui baris, tidak menggandakan.

## Contoh webhook fingerprint
```bash
curl -X POST http://localhost:3100/api/inbound/punches \
  -H "x-api-key: <PUNCH_API_KEY>" -H "content-type: application/json" \
  -d '{"deviceSerial":"DEMO-SN-JKT","punches":[{"enrollId":"101","punchAt":"2026-10-05T01:00:00Z"}]}'
```
Mesin harus terdaftar (menu Mesin Fingerprint) dan PIN-nya dipetakan ke karyawan.
