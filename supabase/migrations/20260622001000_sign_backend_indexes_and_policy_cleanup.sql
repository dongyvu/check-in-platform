create index if not exists sign_records_user_id_idx on public.sign_records (user_id);
create index if not exists sign_tasks_created_by_idx on public.sign_tasks (created_by);

drop policy if exists "admins manage tasks" on public.sign_tasks;

drop policy if exists "admins insert tasks" on public.sign_tasks;
create policy "admins insert tasks"
on public.sign_tasks for insert
to authenticated
with check (app_private.is_admin());

drop policy if exists "admins update tasks" on public.sign_tasks;
create policy "admins update tasks"
on public.sign_tasks for update
to authenticated
using (app_private.is_admin())
with check (app_private.is_admin());

drop policy if exists "admins delete tasks" on public.sign_tasks;
create policy "admins delete tasks"
on public.sign_tasks for delete
to authenticated
using (app_private.is_admin());
