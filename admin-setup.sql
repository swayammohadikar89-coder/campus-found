-- Run once in the Supabase SQL Editor for the Campus Found project.
-- This keeps report viewing/posting public while limiting deletion to approved admins.

create table if not exists public.admins (
  email text primary key check (email = lower(email))
);

alter table public.admins enable row level security;

revoke all on public.admins from anon, authenticated;
grant select on public.admins to authenticated;

drop policy if exists "Admins can read their own approval" on public.admins;
create policy "Admins can read their own approval"
  on public.admins
  for select
  to authenticated
  using (email = (select auth.jwt() ->> 'email'));

revoke delete on public.reports from anon;
grant delete on public.reports to authenticated;

drop policy if exists "Approved admins can delete reports" on public.reports;
create policy "Approved admins can delete reports"
  on public.reports
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.admins
      where admins.email = (select auth.jwt() ->> 'email')
    )
  );

-- After creating the admin in Authentication > Users, approve that exact email:
-- insert into public.admins (email) values ('admin@your-college.edu')
-- on conflict (email) do nothing;
