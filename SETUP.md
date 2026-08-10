# Panduan Setup DTMS dengan Supabase + GitHub Pages

> Dokumen ini menjelaskan langkah-langkah untuk menjalankan aplikasi DTMS di internet menggunakan Supabase sebagai database/backend dan GitHub Pages sebagai hosting.

---

## 1. Prasyarat

- Akun GitHub
- Akun Supabase (gratis di [supabase.com](https://supabase.com))
- `gh` CLI terinstall & login (opsional, untuk push otomatis)

---

## 2. Buat Project Supabase

1. Login ke [supabase.com](https://supabase.com) dan klik **New Project**.
2. Beri nama project: `dtms` (atau bebas).
3. Pilih region terdekat (mis. `Singapore` untuk Indonesia).
4. Tunggu project aktif.

---

## 3. Jalankan Skema Database

1. Di dashboard Supabase, buka menu **SQL Editor** > **New query**.
2. Buka file `supabase/schema.sql` di repo ini, salin seluruh isinya, tempel ke SQL Editor.
3. Klik **Run**.
4. Buat query baru lagi, salin isi `supabase/seed.sql`, klik **Run**.

> Setelah seed berhasil, database akan berisi data demo (5 tooling, 5 user, log, shoot, delivery, dll.).

---

## 4. Setup Supabase Auth

1. Di Supabase, buka **Authentication** > **Providers**.
2. Pastikan **Email** provider aktif.
3. Matikan **Confirm email** (untuk demo) atau aktifkan jika ingin verifikasi email.
4. Buat user awal via Supabase Dashboard atau gunakan akun demo yang akan dibuat di langkah 7.

---

## 5. Setup Supabase Storage

1. Buka **Storage** > **New bucket**.
2. Buat 3 bucket dengan pengaturan berikut:

| Bucket | Public | Allowed MIME |
|--------|--------|--------------|
| `evidence` | Yes | `application/pdf`, `image/*` |
| `documents` | Yes | `application/pdf`, `image/*` |
| `images` | Yes | `image/*` |

3. Untuk tiap bucket, buka **Policies** dan tambahkan policy:
   - **Name**: `Public read`
   - **Allowed operation**: `SELECT`
   - **Target roles**: `authenticated`, `anon`
   - **Policy definition**: `true`
   - Tambahkan juga policy write untuk `authenticated` dengan definisi `true` (atau batasi per role sesuai kebutuhan).

---

## 6. Ambil Supabase URL & Anon Key

1. Di Supabase, buka **Project Settings** > **API**.
2. Salin:
   - **Project URL** (contoh: `https://xxxx.supabase.co`)
   - **anon public** key

---

## 6A. Deploy Edge Function `admin-user`

Edge Function ini menangani penghapusan user dan update password di Supabase Auth
dengan service role key di sisi server (key tidak ter-expose ke client).

1. Install Supabase CLI (jika belum):
   ```bash
   npm install -g supabase
   ```
2. Login & link ke project (ganti `<PROJECT_REF>` dengan Reference ID dari Supabase > Settings > General):
   ```bash
   cd "D:\OpenCode\Aplikasi DTMS"
   supabase login
   supabase link --project-ref <PROJECT_REF>
   ```
3. Deploy fungsi:
   ```bash
   supabase functions deploy admin-user
   ```
4. Setel environment variable untuk fungsi (Supabase > Functions > admin-user):
   - `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` sudah otomatis tersedia di runtime Edge Function, tidak perlu diset manual.

---

## 7. Push Repo ke GitHub

Jika `gh` CLI sudah login:

```bash
cd "/home/darmawan/OpenCode/Aplikasi DTMS"
gh repo create Mesin-Isuzu/DTMS --public --source=. --push
```

Jika manual:

```bash
cd "/home/darmawan/OpenCode/Aplikasi DTMS"
git remote add origin https://github.com/Mesin-Isuzu/DTMS.git
git push -u origin main
```

---

## 8. Konfigurasi GitHub Secrets

1. Buka repo di GitHub: `https://github.com/Mesin-Isuzu/DTMS`
2. Masuk ke **Settings** > **Secrets and variables** > **Actions**.
3. Klik **New repository secret**, tambahkan:
   - `SUPABASE_URL`: URL Supabase Anda
   - `SUPABASE_ANON_KEY`: anon key Supabase Anda

---

## 9. Aktifkan GitHub Pages

1. Di repo GitHub, masuk **Settings** > **Pages**.
2. Under **Build and deployment** > **Source**, pilih **GitHub Actions**.
3. Push satu commit (atau buat perubahan kecil) untuk memicu workflow.
4. URL aplikasi akan muncul, contoh: `https://mesin-isuzu.github.io/DTMS/`

---

## 10. Buat Akun Demo di Supabase Auth

Agar login demo berfungsi, buat user di Supabase Auth dengan email & password berikut:

| Username | Email | Password | Role |
|----------|-------|----------|------|
| admin | `admin@dtms.local` | `password` | Admin Sistem |
| purchasing | `purchasing@dtms.local` | `password` | Purchasing MII |
| supplier1 | `supplier1@dtms.local` | `password` | Pengguna Supplier |
| supplier2 | `supplier2@dtms.local` | `password` | Pengguna Supplier |
| supplier3 | `supplier3@dtms.local` | `password` | Pengguna Supplier |

Cara:
1. Supabase > **Authentication** > **Users** > **Add user**.
2. Isi email & password.
3. Klik user yang baru dibuat, lalu **Edit user metadata** dan isi JSON:

```json
{
  "username": "admin",
  "name": "Admin User",
  "role": "Admin Sistem",
  "company": "MII",
  "supplierId": null
}
```

Untuk supplier:

```json
{
  "username": "supplier1",
  "name": "PT Auto Parts",
  "role": "Pengguna Supplier",
  "company": "PT Auto Parts",
  "supplierId": "SUP001"
}
```

---

## 11. CORS (jika diperlukan)

Supabase default mengizinkan semua origin untuk anon key. Jika mengalami masalah CORS:
1. Supabase > **API** > **Edge Config** atau **Settings** > **API**.
2. Tambahkan origin GitHub Pages ke allowed origins.

---

## 12. Uji Aplikasi

1. Buka URL GitHub Pages.
2. Login dengan akun demo.
3. Cek:
   - Dashboard memuat data.
   - Admin dapat menambah tooling/user.
   - Supplier hanya melihat tooling miliknya.
   - Upload evidence/PA/drawing/foto berfungsi.
   - Refresh browser -> data tetap ada.

---

## 13. Pengembangan Lokal

Untuk menjalankan secara lokal tanpa Supabase:

```bash
cd "/home/darmawan/OpenCode/Aplikasi DTMS"
python3 -m http.server 8000
```

Buka `http://localhost:8000`. Aplikasi akan menggunakan data mock (`js/data.js`) dan login fiktif.

---

## Catatan Keamanan

- **Anon key terlihat di client**. Ini wajar untuk Supabase. Keamanan ditangani oleh **Row Level Security (RLS)**, bukan kerahasiaan key.
- Pastikan RLS policies sudah aktif (sudah ada di `schema.sql`).
- Untuk production, pertimbangkan untuk:
  - Menggunakan email & password yang kuat.
  - Mengaktifkan email confirmation.
  - Membatasi storage policies lebih ketat.
  - Menggunakan custom domain GitHub Pages.
