-- Run once in the Campus Found Supabase SQL Editor after the resolved-status setup.
-- Public visitors can submit a private claim. Only approved admins can read or review claims.

create table if not exists public.item_claims (
  id uuid primary key default gen_random_uuid(),
  report_id text not null references public.reports(id) on delete cascade,
  item_name text not null check (length(item_name) between 1 and 60),
  claimant_name text not null check (length(claimant_name) between 2 and 80),
  contact_info text not null check (length(contact_info) between 3 and 100),
  identifying_details text not null check (length(identifying_details) between 15 and 500),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

alter table public.item_claims enable row level security;
revoke all on public.item_claims from anon, authenticated;
grant insert on public.item_claims to anon;
grant select on public.item_claims to authenticated;
grant update (status) on public.item_claims to authenticated;

drop policy if exists "Anyone can submit a pending claim for an open found item" on public.item_claims;
create policy "Anyone can submit a pending claim for an open found item"
  on public.item_claims
  for insert
  to anon
  with check (
    status = 'pending'
    and exists (
      select 1
      from public.reports
      where reports.id = item_claims.report_id
        and reports.type = 'found'
        and coalesce(reports.status, 'open') = 'open'
    )
  );

drop policy if exists "Approved admins can read private claims" on public.item_claims;
create policy "Approved admins can read private claims"
  on public.item_claims
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.admins
      where admins.email = (select auth.jwt() ->> 'email')
    )
  );

drop policy if exists "Approved admins can review claims" on public.item_claims;
create policy "Approved admins can review claims"
  on public.item_claims
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.admins
      where admins.email = (select auth.jwt() ->> 'email')
    )
  )
  with check (
    exists (
      select 1
      from public.admins
      where admins.email = (select auth.jwt() ->> 'email')
    )
  );
