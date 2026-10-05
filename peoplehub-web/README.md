# PeopleHub Web

Antarmuka web PeopleHub (Next.js 16, React 19, Tailwind 4). Membutuhkan API di folder `peoplehub` yang sedang berjalan.

## Mulai
```bash
cp .env.local.example .env.local   # Windows: copy .env.local.example .env.local
npm install
npm run dev                        # http://localhost:3200
```
Produksi: `npm run build` lalu `npm start` (port 3200).

`API_URL` di `.env.local` menunjuk ke API (default `http://localhost:3100/api`). Alamat ini hanya dipakai dari sisi server Next.js,
jadi tidak perlu pengaturan CORS.

## Cara kerja
- **Login**: token JWT disimpan di cookie `httpOnly` (`ph_token`), tidak terbaca JavaScript di browser.
- **Data halaman**: dibaca di server component lewat `lib/api.ts`.
- **Perubahan dari browser** (tambah, ubah, hapus, unggah): lewat jembatan `app/bff/[...path]` yang meneruskan ke API dengan token dari cookie.
- **Menu** dibangun dari `GET /api/auth/menu` sehingga mengikuti hak akses pengguna.
- `proxy.ts` mengarahkan pengguna yang belum login ke `/login`.

## Halaman
Master Data (lokasi, karyawan), Rekap Absensi, Mesin Fingerprint, Time Entries, Process Monitor, Shift, Jadwal Karyawan,
Kalender, Cuti (hanya baca), Aturan Absensi, Aturan Cuti. Lembur, Konfigurasi Lembur, dan Impor Data masih placeholder.

## Catatan Next.js 16
Versi ini punya perubahan besar dari versi lama (mis. `middleware` berganti nama menjadi `proxy`, `cookies()` bersifat async).
Dokumentasinya ikut terpasang di `node_modules/next/dist/docs/` setelah `npm install`; baca bagian yang relevan sebelum mengubah kode.
