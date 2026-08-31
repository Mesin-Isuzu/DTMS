-- ============================================================
-- Konversi ID maintenanceLogs ke format MR-yyyy-xxxx
--   yyyy = tahun aktivitas pemeliharaan (dari dateStart)
--   xxxx = nomor urut ticket (global, 0001, 0002, ...)
-- Jalankan SEKALI di Supabase SQL Editor.
-- Aman dijalankan ulang (idempotent): baris yang sudah berformat
-- MR-yyyy-xxxx akan dilewatkan.
-- ============================================================

with numbered as (
  select "id",
         to_char(to_date("dateStart", 'DD Mon YYYY'), 'YYYY') as yr,
         row_number() over (
           order by to_date("dateStart", 'DD Mon YYYY'), "createdAt"
         ) as rn
  from public."maintenanceLogs"
)
update public."maintenanceLogs" m
set "id" = 'MR-' || n.yr || '-' || lpad(n.rn::text, 4, '0')
from numbered n
where m."id" = n."id"
  and m."id" !~ '^MR-[0-9]{4}-[0-9]{4}$';
