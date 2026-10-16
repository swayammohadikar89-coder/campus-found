# Campus Found — Lost & Found

A small, mobile-friendly lost and found board for a college. It includes separate Lost and Found filters, search, a report form, optional photos, location/date details, and a contact link.

## Run it

Open `index.html` in a browser, or publish this folder with GitHub Pages (Repository **Settings → Pages → Deploy from a branch**, select `main` and `/ (root)`).

The app works immediately in local demo mode. Reports are saved in that browser only. To let all visitors see and post to one shared board, complete the optional Supabase setup below before publishing.

## Enable the shared public board

1. Create a Supabase project and open its SQL editor.
2. Run this SQL to create the public reports table and allow the app's public anon key to read and add reports:

```sql
create table public.reports (
  id text primary key,
  type text not null check (type in ('lost', 'found')),
  name text not null,
  description text not null,
  location text not null,
  date date not null,
  contact text not null,
  photo text not null default '',
  emoji text not null default '📦',
  created_at timestamptz not null default now()
);

alter table public.reports enable row level security;
create policy "Anyone can view reports" on public.reports
  for select to anon using (true);
create policy "Anyone can add reports" on public.reports
  for insert to anon with check (
    type in ('lost', 'found') and length(name) <= 60
    and length(description) <= 300 and length(location) <= 80
    and length(contact) <= 100
  );
grant select, insert on public.reports to anon;
```

3. In `index.html`, set `SUPABASE_URL` and `SUPABASE_ANON_KEY` near the start of the script. Find the project's URL and public anon/publishable key in Supabase **Project Settings → API**. The public anon key is designed for browser use; never put a `service_role` or secret key in this file.
4. Publish or push the folder to GitHub Pages. Reports will then be shared across visitors.

Large photos are compressed in the browser before upload and stored inline in the table. For a larger public deployment, use Supabase Storage and moderation/rate limiting. Contact information is visible to everyone, so reporters should use a campus email or other safe contact method.

## Admin-only report deletion

Visitors can still browse and post reports without signing in. To let one trusted admin remove spam or outdated reports:

1. In Supabase, open **SQL Editor**, create a new query, paste the contents of `admin-setup.sql`, and run it.
2. In **Authentication → Users**, add one admin user with the admin's email and a strong password. Do not publish or share that password.
3. In SQL Editor, approve that exact email (replace the example email, then run):

   ```sql
   insert into public.admins (email)
   values ('admin@your-college.edu')
   on conflict (email) do nothing;
   ```

4. The admin opens the site, selects **Admin login**, and signs in. A **Delete report** button then appears on report cards. Each deletion asks for confirmation.

The database policy checks the authenticated email against `public.admins`, so merely creating an account does not grant delete access. Keep the admin account credentials private. Removing an email from `public.admins` revokes its delete permission.

## Mark a report as resolved

Approved admins can mark an item **Resolved** when it has been returned, or reopen it if needed. Reports show an Open/Resolved badge and can be filtered by status. To enable this, open Supabase **SQL Editor**, create a new query, paste the contents of `resolved-status-setup.sql`, and run it once. This is a separate update; do not rerun the original admin setup. The existing approved-admin list controls who can change status.

## Main user flow

1. Browse all reports or select Lost / Found; search by item, details, or campus location.
2. Click an item card to open its full description, location, date, photo, and contact details.
3. Choose **Post a report**, select lost or found, and enter the item, description, location, date, and contact. A photo is optional.
4. Publish. The card appears in the list, with a contact link for anyone who can help.

## Report data

```json
{
  "type": "lost",
  "status": "open",
  "name": "Blue water bottle",
  "description": "Navy bottle with stickers",
  "location": "Library, second floor",
  "date": "2026-10-15",
  "contact": "student@campus.edu",
  "photo": "",
  "emoji": "🔎"
}
```
