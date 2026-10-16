-- Run once in the Supabase SQL Editor for the Campus Found project.
-- Adds Open/Resolved status and lets approved admins change it.

alter table public.reports
  add column if not exists status text not null default 'open';

alter table public.reports
  drop constraint if exists reports_status_check;

alter table public.reports
  add constraint reports_status_check
  check (status in ('open', 'resolved'));

-- Authenticated users may only read reports if they are approved admins.
-- Anonymous public browsing/posting policies are left unchanged.
revoke update on public.reports from anon, authenticated;
grant select on public.reports to authenticated;
grant update (status) on public.reports to authenticated;

drop policy if exists "Approved admins can read reports for management" on public.reports;
create policy "Approved admins can read reports for management"
  on public.reports
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.admins
      where admins.email = (select auth.jwt() ->> 'email')
    )
  );

drop policy if exists "Approved admins can update report status" on public.reports;
create policy "Approved admins can update report status"
  on public.reports
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
