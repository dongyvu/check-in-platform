alter table public.profiles
  add column if not exists avatar_url text;

grant update (display_name, avatar_url) on table public.profiles to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', false, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "avatars read own or admin" on storage.objects;
create policy "avatars read own or admin"
on storage.objects for select
to authenticated
using (
  bucket_id = 'avatars'
  and (owner = (select auth.uid()) or app_private.is_admin())
);

drop policy if exists "avatars upload own" on storage.objects;
create policy "avatars upload own"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and owner = (select auth.uid())
);

drop policy if exists "avatars update own or admin" on storage.objects;
create policy "avatars update own or admin"
on storage.objects for update
to authenticated
using (
  bucket_id = 'avatars'
  and (owner = (select auth.uid()) or app_private.is_admin())
)
with check (
  bucket_id = 'avatars'
  and (owner = (select auth.uid()) or app_private.is_admin())
);

drop policy if exists "avatars delete own or admin" on storage.objects;
create policy "avatars delete own or admin"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (owner = (select auth.uid()) or app_private.is_admin())
);
