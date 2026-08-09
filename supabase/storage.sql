-- Storage buckets and policies for DTMS file uploads
-- Run this in Supabase SQL Editor after schema.sql

-- Create buckets if not exist
insert into storage.buckets (id, name, public)
values
  ('evidence', 'evidence', true),
  ('documents', 'documents', true),
  ('images', 'images', true)
on conflict (id) do nothing;

-- Public read access
drop policy if exists "Public read evidence" on storage.objects;
create policy "Public read evidence" on storage.objects
  for select to public using (bucket_id = 'evidence');

drop policy if exists "Public read documents" on storage.objects;
create policy "Public read documents" on storage.objects
  for select to public using (bucket_id = 'documents');

drop policy if exists "Public read images" on storage.objects;
create policy "Public read images" on storage.objects
  for select to public using (bucket_id = 'images');

-- Authenticated users can upload
drop policy if exists "Authenticated upload evidence" on storage.objects;
create policy "Authenticated upload evidence" on storage.objects
  for insert to authenticated with check (bucket_id = 'evidence');

drop policy if exists "Authenticated upload documents" on storage.objects;
create policy "Authenticated upload documents" on storage.objects
  for insert to authenticated with check (bucket_id = 'documents');

drop policy if exists "Authenticated upload images" on storage.objects;
create policy "Authenticated upload images" on storage.objects
  for insert to authenticated with check (bucket_id = 'images');

-- Authenticated users can update/delete their own uploads
drop policy if exists "Authenticated update evidence" on storage.objects;
create policy "Authenticated update evidence" on storage.objects
  for update to authenticated using (bucket_id = 'evidence');

drop policy if exists "Authenticated update documents" on storage.objects;
create policy "Authenticated update documents" on storage.objects
  for update to authenticated using (bucket_id = 'documents');

drop policy if exists "Authenticated update images" on storage.objects;
create policy "Authenticated update images" on storage.objects
  for update to authenticated using (bucket_id = 'images');

drop policy if exists "Authenticated delete evidence" on storage.objects;
create policy "Authenticated delete evidence" on storage.objects
  for delete to authenticated using (bucket_id = 'evidence');

drop policy if exists "Authenticated delete documents" on storage.objects;
create policy "Authenticated delete documents" on storage.objects
  for delete to authenticated using (bucket_id = 'documents');

drop policy if exists "Authenticated delete images" on storage.objects;
create policy "Authenticated delete images" on storage.objects
  for delete to authenticated using (bucket_id = 'images');
