drop policy if exists "users delete own records or admins" on public.sign_records;
create policy "users delete own records or admins"
on public.sign_records for delete
to authenticated
using (user_id = (select auth.uid()) or app_private.is_admin());

drop policy if exists "admins delete records" on public.sign_records;

drop policy if exists "sign photos delete own or admin" on storage.objects;
create policy "sign photos delete own or admin"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'sign-photos'
  and (owner = (select auth.uid()) or app_private.is_admin())
);

drop policy if exists "sign photos delete admin" on storage.objects;
