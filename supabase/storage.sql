-- Storage buckets and policies for DTMS file uploads
-- Run this in Supabase SQL Editor after schema.sql

-- Create buckets if not exist
insert into storage.buckets (id, name, public)
values
  ('evidence', 'evidence', true),
  ('documents', 'documents', true),
  ('images', 'images', true)
on conflict (id) do nothing;

-- Policy: allow public read access
CREATE POLICY IF NOT EXISTS "Public read evidence" ON storage.objects
  FOR SELECT TO public USING (bucket_id = 'evidence');

CREATE POLICY IF NOT EXISTS "Public read documents" ON storage.objects
  FOR SELECT TO public USING (bucket_id = 'documents');

CREATE POLICY IF NOT EXISTS "Public read images" ON storage.objects
  FOR SELECT TO public USING (bucket_id = 'images');

-- Policy: allow authenticated users to upload
CREATE POLICY IF NOT EXISTS "Authenticated upload evidence" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'evidence');

CREATE POLICY IF NOT EXISTS "Authenticated upload documents" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'documents');

CREATE POLICY IF NOT EXISTS "Authenticated upload images" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'images');

-- Policy: allow authenticated users to update/delete their own uploads
CREATE POLICY IF NOT EXISTS "Authenticated update evidence" ON storage.objects
  FOR UPDATE TO authenticated USING (bucket_id = 'evidence');

CREATE POLICY IF NOT EXISTS "Authenticated update documents" ON storage.objects
  FOR UPDATE TO authenticated USING (bucket_id = 'documents');

CREATE POLICY IF NOT EXISTS "Authenticated update images" ON storage.objects
  FOR UPDATE TO authenticated USING (bucket_id = 'images');

CREATE POLICY IF NOT EXISTS "Authenticated delete evidence" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'evidence');

CREATE POLICY IF NOT EXISTS "Authenticated delete documents" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'documents');

CREATE POLICY IF NOT EXISTS "Authenticated delete images" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'images');
