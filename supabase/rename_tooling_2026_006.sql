-- ============================================================
-- Rename Tooling IDs (renumbering)
--   T-2026-006 -> T-2026-001
--   T-2026-007 -> T-2026-002
--   T-2026-008 -> T-2026-003
--   T-2026-009 -> T-2026-004
-- Run this in Supabase SQL Editor.
-- ============================================================

begin;

do $$
declare
  v_cnt text;
begin
  foreach v_cnt in array array['T-2026-006','T-2026-007','T-2026-008','T-2026-009']
  loop
    if not exists (select 1 from public."toolings" where "id" = v_cnt) then
      raise exception 'Tooling % tidak ditemukan', v_cnt;
    end if;
  end loop;

  foreach v_cnt in array array['T-2026-001','T-2026-002','T-2026-003','T-2026-004']
  loop
    if exists (
      select 1 from public."toolings"
      where "id" = v_cnt
        and "id" not in ('T-2026-006','T-2026-007','T-2026-008','T-2026-009')
    ) then
      raise exception 'ID target % sudah dipakai tooling lain', v_cnt;
    end if;
  end loop;
end $$;

-- Foreign keys are not deferrable, so temporarily disable RI triggers
-- on the child tables while we renumber the parent.
alter table public."maintenanceLogs" disable trigger all;
alter table public."supplierTasks"   disable trigger all;
alter table public."shootLogs"       disable trigger all;
alter table public."productionLogs"  disable trigger all;
alter table public."deliveryLogs"    disable trigger all;
alter table public."movementLogs"    disable trigger all;

-- Rename parent rows
update public."toolings" set "id" = 'T-2026-001' where "id" = 'T-2026-006';
update public."toolings" set "id" = 'T-2026-002' where "id" = 'T-2026-007';
update public."toolings" set "id" = 'T-2026-003' where "id" = 'T-2026-008';
update public."toolings" set "id" = 'T-2026-004' where "id" = 'T-2026-009';

-- Update child references
update public."maintenanceLogs" set "toolId" = 'T-2026-001' where "toolId" = 'T-2026-006';
update public."supplierTasks"   set "toolId" = 'T-2026-001' where "toolId" = 'T-2026-006';
update public."shootLogs"       set "toolId" = 'T-2026-001' where "toolId" = 'T-2026-006';
update public."productionLogs"  set "toolId" = 'T-2026-001' where "toolId" = 'T-2026-006';
update public."deliveryLogs"    set "toolId" = 'T-2026-001' where "toolId" = 'T-2026-006';
update public."movementLogs"    set "toolId" = 'T-2026-001' where "toolId" = 'T-2026-006';

update public."maintenanceLogs" set "toolId" = 'T-2026-002' where "toolId" = 'T-2026-007';
update public."supplierTasks"   set "toolId" = 'T-2026-002' where "toolId" = 'T-2026-007';
update public."shootLogs"       set "toolId" = 'T-2026-002' where "toolId" = 'T-2026-007';
update public."productionLogs"  set "toolId" = 'T-2026-002' where "toolId" = 'T-2026-007';
update public."deliveryLogs"    set "toolId" = 'T-2026-002' where "toolId" = 'T-2026-007';
update public."movementLogs"    set "toolId" = 'T-2026-002' where "toolId" = 'T-2026-007';

update public."maintenanceLogs" set "toolId" = 'T-2026-003' where "toolId" = 'T-2026-008';
update public."supplierTasks"   set "toolId" = 'T-2026-003' where "toolId" = 'T-2026-008';
update public."shootLogs"       set "toolId" = 'T-2026-003' where "toolId" = 'T-2026-008';
update public."productionLogs"  set "toolId" = 'T-2026-003' where "toolId" = 'T-2026-008';
update public."deliveryLogs"    set "toolId" = 'T-2026-003' where "toolId" = 'T-2026-008';
update public."movementLogs"    set "toolId" = 'T-2026-003' where "toolId" = 'T-2026-008';

update public."maintenanceLogs" set "toolId" = 'T-2026-004' where "toolId" = 'T-2026-009';
update public."supplierTasks"   set "toolId" = 'T-2026-004' where "toolId" = 'T-2026-009';
update public."shootLogs"       set "toolId" = 'T-2026-004' where "toolId" = 'T-2026-009';
update public."productionLogs"  set "toolId" = 'T-2026-004' where "toolId" = 'T-2026-009';
update public."deliveryLogs"    set "toolId" = 'T-2026-004' where "toolId" = 'T-2026-009';
update public."movementLogs"    set "toolId" = 'T-2026-004' where "toolId" = 'T-2026-009';

-- Re-enable triggers
alter table public."maintenanceLogs" enable trigger all;
alter table public."supplierTasks"   enable trigger all;
alter table public."shootLogs"       enable trigger all;
alter table public."productionLogs"  enable trigger all;
alter table public."deliveryLogs"    enable trigger all;
alter table public."movementLogs"    enable trigger all;

commit;

-- Verifikasi hasil (opsional, di luar transaksi di atas)
select "id", "name" from public."toolings"
where "id" in ('T-2026-001','T-2026-002','T-2026-003','T-2026-004','T-2026-006','T-2026-007','T-2026-008','T-2026-009')
order by "id";
