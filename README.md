# PeopleHub — paket berbagi

Aplikasi HR untuk jadwal kerja, absensi fingerprint, aturan keterlambatan, aturan cuti (masa kerja dan saldo anniversary),
time entries (impor dan ekspor CSV), dan Process Monitor. Terdiri dari API (NestJS) dan antarmuka web (Next.js) di atas PostgreSQL.

## Isi paket
```
peoplehub/                       API (NestJS + Prisma), port 3100
peoplehub-web/                   Antarmuka web (Next.js), port 3200
database/peoplehub-initial.sql   Salinan database awal (opsional, lihat Cara B)
```

## Yang harus terpasang
- **Node.js 22.13 atau lebih baru** (dikembangkan dengan 24; disarankan 24). Cek: `node -v`
- **PostgreSQL 16 atau lebih baru**, beserta `psql`. Cek: `psql --version`

## Langkah cepat

### 1. Buat database kosong
```bash
psql -U postgres -c "CREATE DATABASE peoplehub;"
```

### 2. Isi database. Pilih SATU cara

**Cara A (disarankan): bangun dari migrasi.** Mengikuti versi kode, tidak bergantung versi PostgreSQL.
Dikerjakan di langkah 3 (`prisma migrate deploy` lalu `db:seed`), lalu data contoh dimuat di langkah 5.

**Cara B: pulihkan dari dump.** Salinan persis database awal, sudah berisi data contoh dan admin.
```bash
psql -U postgres -d peoplehub -f database/peoplehub-initial.sql
```
Bila memakai Cara B, **lewati** `prisma migrate deploy`, `db:seed`, dan `sample:load` di bawah.

### 3. API
```bash
cd peoplehub
cp .env.example .env          # Windows (cmd/PowerShell): copy .env.example .env
```
Edit `.env`: isi `DATABASE_URL` (user dan password PostgreSQL Anda; karakter khusus di-URL-encode, mis. `@` jadi `%40`),
`JWT_SECRET` dan `PUNCH_API_KEY` (string acak panjang).
```bash
npm install                   # otomatis menjalankan `prisma generate`
npx prisma migrate deploy     # hanya Cara A
npm run db:seed               # hanya Cara A
npm run build
npm start                     # API di http://localhost:3100/api  (biarkan terminal ini terbuka)
```

### 4. Web (terminal kedua)
```bash
cd peoplehub-web
cp .env.local.example .env.local   # Windows: copy .env.local.example .env.local
npm install
npm run dev                        # http://localhost:3200
```

### 5. Data contoh (opsional, hanya Cara A; API harus sedang berjalan)
```bash
cd peoplehub
npm run sample:load
```

## Login
Buka http://localhost:3200

| | |
|---|---|
| Username | `admin` |
| Password | `pass123` |

Dengan Cara A, akun ini berasal dari `SEED_ADMIN_EMAIL` dan `SEED_ADMIN_PASSWORD` di `.env` (default sama seperti di atas).
Dengan Cara B, akun admin sudah ada di dump (`admin` / `pass123`).

## Yang bisa dicoba
Data contoh berisi 10 karyawan (September 2026) dengan beragam skenario. Pilih rentang **1–30 September 2026** di halaman berikut:

- **Rekap Absensi**: terlambat, alpa, lupa absen pulang, cuti, libur, shift lintas hari, tiga zona waktu.
- **Jadwal Karyawan**: pilih minggu 14 September 2026 (`/schedule/roster?week=2026-09-14`).
- **Aturan Absensi** dan **Aturan Cuti**: toleransi per lokasi; syarat masa kerja 12 bulan dan saldo 12 hari tiap anniversary.
  Gunakan panel "Cek karyawan" di Aturan Cuti.
- **Time Entries**: unggah `peoplehub/samples/time-entries-sample.csv` lalu lihat hasilnya di **Process Monitor**
  (37 baris berhasil, 5 sengaja gagal dengan alasan masing-masing). Tombol Unduh CSV mengekspor dalam format yang sama.
- **Mesin Fingerprint**: pemetaan PIN ke karyawan; webhook punch dijelaskan di `peoplehub/README.md`.

Hapus data contoh: `npm run sample:reset` (di folder `peoplehub`).

## Catatan keamanan
- Paket ini untuk **demo di komputer sendiri**. Akun `admin` / `pass123` sengaja sederhana; ganti sebelum dipakai di luar itu.
- File `.env` dan `.env.local` tidak ikut paket. Buat sendiri dari contohnya dan jangan dibagikan atau di-commit.
- Dump database hanya berisi data contoh dan satu akun admin (password tersimpan sebagai hash).

## Masalah umum
| Gejala | Penyebab dan solusi |
|---|---|
| `@prisma/client did not initialize yet` atau banyak error TypeScript saat build | Klien Prisma belum dibuat. Jalankan `npx prisma generate` di folder `peoplehub`, lalu ulangi. |
| Peringatan `EBADENGINE` untuk `@angular-devkit/schematics` saat `npm install` | Aman diabaikan: itu alat generator kode Nest CLI dan tidak memengaruhi build atau aplikasi. |
| `password authentication failed` | `DATABASE_URL` salah. Periksa user/password; encode karakter khusus (`@` → `%40`). |
| `database "peoplehub" does not exist` | Jalankan langkah 1. |
| Web menampilkan "fetch failed" atau halaman error | API belum berjalan. Jalankan `npm start` di folder `peoplehub`, dan pastikan `API_URL` di `peoplehub-web/.env.local` benar. |
| `EADDRINUSE` / port sudah dipakai | Ubah `PORT` di `peoplehub/.env`, atau port web dengan `npx next dev -p <port>` (lalu sesuaikan `API_URL` bila port API berubah). |
| Login ditolak | Cara A: pastikan `db:seed` sudah dijalankan dan sesuai `SEED_ADMIN_*` di `.env`. |

---

## 👥 Pengembangan Tim

Repo: https://github.com/sabanilahir/peoplehub

### Clone Repository
```bash
git clone https://github.com/sabanilahir/peoplehub.git
cd peoplehub
```

### Setup untuk Developer Baru
```bash
# Backend
cd peoplehub
cp .env.example .env
# Edit .env - sesuaikan DATABASE_URL dengan konfigurasi PostgreSQL Anda
npm install
npx prisma migrate deploy
npm run db:seed

# Frontend
cd ../peoplehub-web
cp .env.local.example .env.local
npm install
```

### Workflow Development
```bash
# 1. Pull sebelum mulai kerja
git pull origin main

# 2. Buat branch untuk fitur
git checkout -b fitur/nama-fitur

# 3. Development...

# 4. Commit & push
git add .
git commit -m "feat: deskripsi fitur"
git push origin fitur/nama-fitur

# 5. Buat Pull Request di GitHub untuk review
```

### Catatan Penting
- **JWT_SECRET** dan **PUNCH_API_KEY** harus sama antar semua developer
- Setiap developer punya **database PostgreSQL lokal sendiri**
- Schema sync via `npx prisma migrate dev` (lalu push) atau `npx prisma migrate deploy`
- Jangan pernah commit file `.env` atau `.env.local`
| Rekap Absensi kosong | Pilih rentang 1–30 September 2026; data contoh hanya untuk bulan itu. |
