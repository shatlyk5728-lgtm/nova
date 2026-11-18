-- Nova VPN: Premium entitlements for anonymous and registered Supabase users.
create table if not exists public.nova_user_premium (user_id uuid primary key references auth.users(id) on delete cascade, expires_at timestamptz not null, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.nova_user_premium enable row level security;
drop policy if exists "Users can read their own premium" on public.nova_user_premium;
create policy "Users can read their own premium" on public.nova_user_premium for select to authenticated using (user_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true));
drop policy if exists "Admins can insert premium" on public.nova_user_premium;
create policy "Admins can insert premium" on public.nova_user_premium for insert to authenticated with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true));
drop policy if exists "Admins can update premium" on public.nova_user_premium;
create policy "Admins can update premium" on public.nova_user_premium for update to authenticated using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true)) with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true));
drop policy if exists "Admins can delete premium" on public.nova_user_premium;
create policy "Admins can delete premium" on public.nova_user_premium for delete to authenticated using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true));