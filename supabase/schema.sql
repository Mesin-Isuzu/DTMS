-- ============================================================
-- Supabase schema for Digital Dies & Tool Management System (DTMS)
-- Run this in Supabase SQL Editor (new query)
-- ============================================================

-- ------------------------------------------------------------
-- 1. Helper functions to read role / supplier_id from JWT
-- ------------------------------------------------------------
create or replace function public.get_my_role()
returns text
language plpgsql
security definer
as $$
begin
  return (auth.jwt() -> 'user_metadata' ->> 'role');
end;
$$;

create or replace function public.get_my_supplier_id()
returns text
language plpgsql
security definer
as $$
begin
  return (auth.jwt() -> 'user_metadata' ->> 'supplierId');
end;
$$;

create or replace function public.is_admin()
returns boolean
language plpgsql
security definer
as $$
begin
  return public.get_my_role() = 'Admin Sistem';
end;
$$;

create or replace function public.is_purchasing()
returns boolean
language plpgsql
security definer
as $$
begin
  return public.get_my_role() = 'Purchasing MII';
end;
$$;

create or replace function public.is_supplier()
returns boolean
language plpgsql
security definer
as $$
begin
  return public.get_my_role() = 'Pengguna Supplier';
end;
$$;

create or replace function public.can_access_all_toolings()
returns boolean
language plpgsql
security definer
as $$
begin
  return public.get_my_role() in ('Admin Sistem', 'Purchasing MII');
end;
$$;

-- ------------------------------------------------------------
-- 2. Users table (app-level user directory)
-- ------------------------------------------------------------
create table if not exists public."users" (
  "id" serial primary key,
  "authId" uuid references auth.users(id) on delete set null,
  "username" text unique not null,
  "email" text unique not null,
  "role" text not null check ("role" in ('Admin Sistem', 'Purchasing MII', 'Pengguna Supplier')),
  "name" text not null,
  "company" text,
  "supplierId" text,
  "createdAt" timestamptz default now()
);

comment on table public."users" is 'Application user directory synced from auth.users';

alter table public."users" enable row level security;

drop policy if exists "users_select_all" on public."users";
create policy "users_select_all" on public."users"
  for select to authenticated using (true);

drop policy if exists "users_admin_all" on public."users";
create policy "users_admin_all" on public."users"
  for all to authenticated using (public.is_admin());

-- ------------------------------------------------------------
-- 3. Master data: die types
-- ------------------------------------------------------------
create table if not exists public."dieTypes" (
  "id" serial primary key,
  "name" text unique not null,
  "createdAt" timestamptz default now()
);

comment on table public."dieTypes" is 'Master list of die/tooling types';

alter table public."dieTypes" enable row level security;

drop policy if exists "dieTypes_select" on public."dieTypes";
create policy "dieTypes_select" on public."dieTypes"
  for select to authenticated using (true);

drop policy if exists "dieTypes_admin" on public."dieTypes";
create policy "dieTypes_admin" on public."dieTypes"
  for all to authenticated using (public.is_admin())
  with check (public.is_admin());

-- ------------------------------------------------------------
-- 4. Master data: product models
-- ------------------------------------------------------------
create table if not exists public."productModels" (
  "id" serial primary key,
  "name" text unique not null,
  "createdAt" timestamptz default now()
);

comment on table public."productModels" is 'Master list of product models';

alter table public."productModels" enable row level security;

drop policy if exists "productModels_select" on public."productModels";
create policy "productModels_select" on public."productModels"
  for select to authenticated using (true);

drop policy if exists "productModels_admin" on public."productModels";
create policy "productModels_admin" on public."productModels"
  for all to authenticated using (public.is_admin())
  with check (public.is_admin());

-- ------------------------------------------------------------
-- 4A. Master data: suppliers
-- ------------------------------------------------------------
create table if not exists public."suppliers" (
  "id" serial primary key,
  "supplierId" text unique not null,
  "name" text not null,
  "address" text,
  "mapUrl" text,
  "pic" text,
  "picEmail" text,
  "picPhone" text,
  "createdAt" timestamptz default now()
);

comment on table public."suppliers" is 'Master list of suppliers';

alter table public."suppliers" enable row level security;

drop policy if exists "suppliers_select" on public."suppliers";
create policy "suppliers_select" on public."suppliers"
  for select to authenticated using (true);

drop policy if exists "suppliers_admin" on public."suppliers";
create policy "suppliers_admin" on public."suppliers"
  for all to authenticated using (public.is_admin())
  with check (public.is_admin());

-- ------------------------------------------------------------
-- 5. Toolings
-- ------------------------------------------------------------
create table if not exists public."toolings" (
  "id" text primary key,
  "name" text not null,
  "type" text,
  "partNumber" text,
  "partName" text,
  "model" text,
  "supplier" text,
  "supplierId" text,
  "supplierAddress" text,
  "status" text,
  "condition" text,
  "owner" text,
  "lifetime" text,
  "maxShoot" integer,
  "lastMaintenance" text,
  "maker" text,
  "weight" text,
  "tonnage" text,
  "dimensions" text,
  "toolImage" text,
  "toolImage2" text,
  "partImage" text,
  "material" text,
  "depreciationType" text,
  "depreciationValue" text,
  "qtyDepreciation" text,
  "paNumber" text,
  "paDocumentName" text,
  "paDocumentPath" text,
  "drawingDiesName" text,
  "drawingDiesPath" text,
  "price" text,
  "notes" text,
  "pic" text,
  "picEmail" text,
  "picPhone" text,
  "qtyPerTooling" text,
  "mapUrl" text,
  "createdAt" timestamptz default now(),
  "updatedAt" timestamptz default now()
);

alter table public."toolings" enable row level security;

drop policy if exists "toolings_select" on public."toolings";
create policy "toolings_select" on public."toolings"
  for select to authenticated
  using (
    public.can_access_all_toolings()
    or (public.is_supplier() and public.get_my_supplier_id() = "supplierId")
  );

drop policy if exists "toolings_insert" on public."toolings";
create policy "toolings_insert" on public."toolings"
  for insert to authenticated
  with check (public.can_access_all_toolings());

drop policy if exists "toolings_update" on public."toolings";
create policy "toolings_update" on public."toolings"
  for update to authenticated
  using (
    public.can_access_all_toolings()
    or (public.is_supplier() and public.get_my_supplier_id() = "supplierId")
  )
  with check (
    public.can_access_all_toolings()
    or (public.is_supplier() and public.get_my_supplier_id() = "supplierId")
  );

drop policy if exists "toolings_delete" on public."toolings";
create policy "toolings_delete" on public."toolings"
  for delete to authenticated
  using (public.is_admin());

-- ------------------------------------------------------------
-- 6. Maintenance logs
-- ------------------------------------------------------------
create table if not exists public."maintenanceLogs" (
  "id" text primary key,
  "toolId" text references public."toolings"("id") on delete cascade,
  "toolName" text,
  "dateStart" text,
  "dateEnd" text,
  "type" text,
  "description" text,
  "status" text,
  "evidence" text,
  "evidencePath" text,
  "requestedBy" text,
  "cost" text,
  "createdAt" timestamptz default now()
);

alter table public."maintenanceLogs" enable row level security;

drop policy if exists "maintenance_select" on public."maintenanceLogs";
create policy "maintenance_select" on public."maintenanceLogs"
  for select to authenticated
  using (
    public.can_access_all_toolings()
    or (public.is_supplier() and public.get_my_supplier_id() = (select "supplierId" from public."toolings" where "id" = "toolId"))
  );

drop policy if exists "maintenance_write" on public."maintenanceLogs";
create policy "maintenance_write" on public."maintenanceLogs"
  for all to authenticated
  using (
    public.can_access_all_toolings()
    or (public.is_supplier() and public.get_my_supplier_id() = (select "supplierId" from public."toolings" where "id" = "toolId"))
  )
  with check (
    public.can_access_all_toolings()
    or (public.is_supplier() and public.get_my_supplier_id() = (select "supplierId" from public."toolings" where "id" = "toolId"))
  );

-- ------------------------------------------------------------
-- 7. Supplier tasks
-- ------------------------------------------------------------
create table if not exists public."supplierTasks" (
  "id" text primary key,
  "toolId" text references public."toolings"("id") on delete cascade,
  "toolName" text,
  "supplier" text,
  "supplierId" text,
  "type" text,
  "description" text,
  "assignedDate" text,
  "dueDate" text,
  "status" text,
  "priority" text,
  "completedDate" text,
  "evidence" text,
  "evidencePath" text,
  "createdAt" timestamptz default now()
);

alter table public."supplierTasks" enable row level security;

drop policy if exists "supplierTasks_select" on public."supplierTasks";
create policy "supplierTasks_select" on public."supplierTasks"
  for select to authenticated
  using (
    public.can_access_all_toolings()
    or (public.is_supplier() and public.get_my_supplier_id() = "supplierId")
  );

drop policy if exists "supplierTasks_write" on public."supplierTasks";
create policy "supplierTasks_write" on public."supplierTasks"
  for all to authenticated
  using (public.can_access_all_toolings())
  with check (public.can_access_all_toolings());

-- ------------------------------------------------------------
-- 8. Shoot logs
-- ------------------------------------------------------------
create table if not exists public."shootLogs" (
  "id" text primary key,
  "toolId" text references public."toolings"("id") on delete cascade,
  "month" text,
  "inputDate" text,
  "shootCount" integer,
  "createdAt" timestamptz default now()
);

alter table public."shootLogs" enable row level security;

drop policy if exists "shootLogs_select" on public."shootLogs";
create policy "shootLogs_select" on public."shootLogs"
  for select to authenticated
  using (
    public.can_access_all_toolings()
    or (public.is_supplier() and public.get_my_supplier_id() = (select "supplierId" from public."toolings" where "id" = "toolId"))
  );

drop policy if exists "shootLogs_write" on public."shootLogs";
create policy "shootLogs_write" on public."shootLogs"
  for all to authenticated
  using (
    public.can_access_all_toolings()
    or (public.is_supplier() and public.get_my_supplier_id() = (select "supplierId" from public."toolings" where "id" = "toolId"))
  )
  with check (
    public.can_access_all_toolings()
    or (public.is_supplier() and public.get_my_supplier_id() = (select "supplierId" from public."toolings" where "id" = "toolId"))
  );

-- ------------------------------------------------------------
-- 9. Production logs
-- ------------------------------------------------------------
create table if not exists public."productionLogs" (
  "id" text primary key,
  "toolId" text references public."toolings"("id") on delete cascade,
  "shootLogId" text references public."shootLogs"("id") on delete cascade,
  "actualPartOk" integer,
  "createdAt" timestamptz default now()
);

alter table public."productionLogs" enable row level security;

drop policy if exists "productionLogs_select" on public."productionLogs";
create policy "productionLogs_select" on public."productionLogs"
  for select to authenticated
  using (
    public.can_access_all_toolings()
    or (public.is_supplier() and public.get_my_supplier_id() = (select "supplierId" from public."toolings" where "id" = "toolId"))
  );

drop policy if exists "productionLogs_write" on public."productionLogs";
create policy "productionLogs_write" on public."productionLogs"
  for all to authenticated
  using (public.can_access_all_toolings())
  with check (public.can_access_all_toolings());

-- ------------------------------------------------------------
-- 10. Delivery logs
-- ------------------------------------------------------------
create table if not exists public."deliveryLogs" (
  "id" text primary key,
  "toolId" text references public."toolings"("id") on delete cascade,
  "month" text,
  "inputDate" text,
  "qtyDelivered" integer,
  "qtyOk" integer,
  "createdAt" timestamptz default now()
);

alter table public."deliveryLogs" enable row level security;

drop policy if exists "deliveryLogs_select" on public."deliveryLogs";
create policy "deliveryLogs_select" on public."deliveryLogs"
  for select to authenticated
  using (
    public.can_access_all_toolings()
    or (public.is_supplier() and public.get_my_supplier_id() = (select "supplierId" from public."toolings" where "id" = "toolId"))
  );

drop policy if exists "deliveryLogs_write" on public."deliveryLogs";
create policy "deliveryLogs_write" on public."deliveryLogs"
  for all to authenticated
  using (public.can_access_all_toolings())
  with check (public.can_access_all_toolings());

-- ------------------------------------------------------------
-- 11. Movement logs
-- ------------------------------------------------------------
create table if not exists public."movementLogs" (
  "id" text primary key,
  "toolId" text references public."toolings"("id") on delete cascade,
  "toolName" text,
  "fromLocation" text,
  "toLocation" text,
  "date" text,
  "reason" text,
  "status" text,
  "requestedBy" text,
  "createdAt" timestamptz default now()
);

alter table public."movementLogs" enable row level security;

drop policy if exists "movementLogs_select" on public."movementLogs";
create policy "movementLogs_select" on public."movementLogs"
  for select to authenticated
  using (
    public.can_access_all_toolings()
    or (public.is_supplier() and public.get_my_supplier_id() = (select "supplierId" from public."toolings" where "id" = "toolId"))
  );

drop policy if exists "movementLogs_write" on public."movementLogs";
create policy "movementLogs_write" on public."movementLogs"
  for all to authenticated
  using (public.can_access_all_toolings())
  with check (public.can_access_all_toolings());

-- ------------------------------------------------------------
-- 12. Notifications
-- ------------------------------------------------------------
create table if not exists public."notifications" (
  "id" serial primary key,
  "userId" integer references public."users"("id") on delete cascade,
  "message" text,
  "time" text,
  "read" boolean default false,
  "type" text,
  "route" text,
  "createdAt" timestamptz default now()
);

alter table public."notifications" add column if not exists "route" text;

alter table public."notifications" enable row level security;

drop policy if exists "notifications_select" on public."notifications";
create policy "notifications_select" on public."notifications"
  for select to authenticated
  using (
    public.is_admin()
    or "userId" = (select "id" from public."users" where "authId" = auth.uid())
  );

drop policy if exists "notifications_admin" on public."notifications";
create policy "notifications_admin" on public."notifications"
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ------------------------------------------------------------
-- 13. Audit logs
-- ------------------------------------------------------------
create table if not exists public."auditLogs" (
  "id" uuid primary key default gen_random_uuid(),
  "time" text,
  "userId" integer references public."users"("id") on delete set null,
  "userName" text,
  "action" text,
  "icon" text,
  "color" text,
  "createdAt" timestamptz default now()
);

alter table public."auditLogs" enable row level security;

drop policy if exists "auditLogs_select" on public."auditLogs";
create policy "auditLogs_select" on public."auditLogs"
  for select to authenticated
  using (public.can_access_all_toolings());

drop policy if exists "auditLogs_insert" on public."auditLogs";
create policy "auditLogs_insert" on public."auditLogs"
  for insert to authenticated
  with check (true);

drop policy if exists "auditLogs_admin" on public."auditLogs";
create policy "auditLogs_admin" on public."auditLogs"
  for delete to authenticated
  using (public.is_admin());

-- ------------------------------------------------------------
-- 14. Updated-at helper for toolings
-- ------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new."updatedAt" = now();
  return new;
end;
$$;

drop trigger if exists trg_toolings_updated_at on public."toolings";
create trigger trg_toolings_updated_at
  before update on public."toolings"
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- 15. Useful views
-- ------------------------------------------------------------
create or replace view public.kpis as
select
  (select count(*) from public."toolings" where "status" = 'Aktif') as "totalActive",
  (select count(*) from public."maintenanceLogs" where "status" in ('Menunggu Persetujuan', 'Sedang Berlangsung')) as "openRepairs",
  (select count(*) from public."movementLogs" where "status" = 'Menunggu Persetujuan') as "pendingApprovals",
  (select count(*) from public."supplierTasks" where "status" = 'Overdue') as "overdueTasks";
