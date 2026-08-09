-- Fix emails in public.users to match Supabase Auth users
UPDATE public."users" SET "email" = 'admin@dtms.mail' WHERE "username" = 'admin';
UPDATE public."users" SET "email" = 'purchasing@dtms.mail' WHERE "username" = 'purchasing';
UPDATE public."users" SET "email" = 'supplier1@dtms.mail' WHERE "username" = 'supplier1';
UPDATE public."users" SET "email" = 'supplier2@dtms.mail' WHERE "username" = 'supplier2';
UPDATE public."users" SET "email" = 'supplier3@dtms.mail' WHERE "username" = 'supplier3';
