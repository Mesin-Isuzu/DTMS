# Rencana: Database Supabase + Deploy GitHub Pages untuk Aplikasi DTMS

> Dibuat: 2026-08-09  
> Tujuan: Memindahkan aplikasi static "Digital Dies & Tool Management System" (DTMS) ke Supabase + GitHub Pages agar multi-user, persisten, dan bisa diakses via internet.

---

## 1. Temuan dari Analisis Kode

- Aplikasi **static murni**: `index.html` + `css/style.css` + `js/data.js` + `js/app.js`.
- **Tidak ada build tool** (tidak ada `package.json`, bundler, framework).
- **10 koleksi data** di `js/data.js`:
  - `users`
  - `toolings`
  - `maintenanceLogs`
  - `supplierTasks`
  - `shootLogs`
  - `productionLogs`
  - `deliveryLogs`
  - `movementLogs`
  - `notifications`
  - `auditLogs`
- `kpis` bersifat komputatif (bisa dihitung dari tabel tooling/maintenance).
- **~30 titik mutasi data** di `js/app.js:1063–2656`, semuanya in-memory.
- **File upload** (evidence, PA document, drawing dies, foto tooling) disimpan sebagai base64 in-memory.
- Login fiktif: tidak ada cek password.
- Routing berbasis hash (`#dashboard`), cocok untuk subpath GitHub Pages.

---

## 2. Arsitektur Target

```text
User  ──▶  GitHub Pages  ──▶  static HTML/CSS/JS
                     │
                     └────▶  Supabase (Postgres + Auth + Storage)
```

- **GitHub Pages**: hosting static gratis.
- **Supabase Auth**: login email/password, role & supplierId di `raw_user_meta_data`.
- **Supabase Postgres**: 9 tabel utama.
- **Supabase Storage**: bucket `evidence`, `documents`, `images`.
- **RLS (Row Level Security)**: batasi akses per role.

---

## 3. Fase Pengerjaan

### Fase 3.1 — GitHub Repo & Pages
- `git init` di folder proyek.
- Buat repo GitHub baru (mis. `Aplikasi-DTMS`).
- Push kode awal.
- Aktifkan GitHub Pages + workflow deploy.

### Fase 3.2 — Skema Supabase
- Jalankan SQL di Supabase SQL Editor:
  - `supabase/schema.sql`  → tabel, relasi, RLS policies, function/trigger sinkron users.
  - `supabase/seed.sql`    → seed data dari `mockData`.
- Buat Storage bucket:
  - `evidence`   (private write, public read)
  - `documents`  (PA, drawing dies)
  - `images`     (foto tooling/part)

### Fase 3.3 — Integrasi Kode Aplikasi
- `index.html`: tambah CDN `@supabase/supabase-js` + `js/config.js`.
- `js/config.js`: `supabaseUrl` + `supabaseAnonKey` (dihasilkan oleh GitHub Actions dari secrets).
- `js/db.js` (baru): layer akses data Supabase.
  - init client
  - load all collections
  - CRUD helpers per tabel
  - upload/download file ke Storage
- `js/app.js` (modifikasi):
  - `login()` → `supabase.auth.signInWithPassword`.
  - load data dari Supabase saat start.
  - ubah ~30 titik mutasi in-memory menjadi call ke `js/db.js`.
  - file upload → Storage (URL publik), ganti base64.
- `js/data.js`: dipertahankan sebagai fallback/mock saat offline/dev.

### Fase 3.4 — Deploy
- `.github/workflows/deploy.yml`:
  - Generate `js/config.js` dari GitHub secrets.
  - Deploy ke GitHub Pages.
- URL target: `https://<username>.github.io/Aplikasi-DTMS/`

### Fase 3.5 — Verifikasi
- Login per role (admin / purchasing / supplier).
- Cek RLS (supplier hanya lihat tool miliknya).
- CRUD tooling, task, maintenance, shoot log.
- Upload evidence / PA / drawing / foto.
- Refresh browser → data tetap ada.

---

## 4. Keputusan Desain

| Aspek | Keputusan |
|-------|-----------|
| Login | Supabase Auth email/password |
| Role | disimpan di `raw_user_meta_data`, sinkron ke tabel `users` |
| KPI | dihitung via query SQL/view, bukan tabel statis |
| File upload | Supabase Storage, URL publik disimpan di kolom tabel |
| Keamanan key | Anon key aman di client karena RLS aktif |
| Fallback | `js/data.js` tetap ada untuk pengembangan offline |

---

## 5. Risiko & Catatan

- Anon key akan terlihat di kode client; keamanan bergantung pada RLS.
- Setelah integrasi, aplikasi berubah dari "data hilang saat refresh" menjadi persisten multi-user.
- Perubahan di `app.js` cukup luas karena banyak titik mutasi in-memory.
- Diperlukan kredensial Supabase dari dashboard (URL + anon key) untuk menyelesaikan konfigurasi.
