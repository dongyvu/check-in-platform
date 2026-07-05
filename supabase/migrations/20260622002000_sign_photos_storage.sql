insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('sign-photos', 'sign-photos', false, 5242880, array['image/jpeg'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "sign photos read own or admin" on storage.objects;
create policy "sign photos read own or admin"
on storage.objects for select
to authenticated
using (
  bucket_id = 'sign-photos'
  and (owner = (select auth.uid()) or app_private.is_admin())
);

drop policy if exists "sign photos upload own" on storage.objects;
create policy "sign photos upload own"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'sign-photos'
  and owner = (select auth.uid())
);

drop policy if exists "sign photos update own or admin" on storage.objects;
create policy "sign photos update own or admin"
on storage.objects for update
to authenticated
using (
  bucket_id = 'sign-photos'
  and (owner = (select auth.uid()) or app_private.is_admin())
)
with check (
  bucket_id = 'sign-photos'
  and (owner = (select auth.uid()) or app_private.is_admin())
);

drop policy if exists "sign photos delete admin" on storage.objects;
create policy "sign photos delete admin"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'sign-photos'
  and app_private.is_admin()
);
