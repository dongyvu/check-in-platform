create schema if not exists app_private;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  display_name text not null,
  role text not null default 'user' check (role in ('user', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.sign_tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  time_range text not null,
  location text not null,
  remarks text not null default '',
  status text not null default 'active' check (status in ('pending', 'active', 'ended')),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.sign_records (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.sign_tasks(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  checked_at timestamptz not null default now(),
  location text not null,
  status text not null default 'normal' check (status in ('normal', 'late')),
  photo_url text,
  created_at timestamptz not null default now(),
  unique (task_id, user_id)
);

create or replace function app_private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function app_private.touch_updated_at();

drop trigger if exists sign_tasks_touch_updated_at on public.sign_tasks;
create trigger sign_tasks_touch_updated_at
before update on public.sign_tasks
for each row execute function app_private.touch_updated_at();

create or replace function app_private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, display_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1), '用户'),
    case when new.raw_app_meta_data->>'role' = 'admin' then 'admin' else 'user' end
  )
  on conflict (id) do update set
    email = excluded.email,
    display_name = excluded.display_name;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function app_private.handle_new_user();

create or replace function app_private.is_admin()
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

alter table public.profiles enable row level security;
alter table public.sign_tasks enable row level security;
alter table public.sign_records enable row level security;

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.sign_tasks from anon, authenticated;
revoke all on table public.sign_records from anon, authenticated;
revoke all on schema app_private from anon, authenticated;

grant usage on schema app_private to authenticated;
grant execute on function app_private.is_admin() to authenticated;

grant select on table public.profiles to authenticated;
grant update (display_name) on table public.profiles to authenticated;

grant select, insert, update, delete on table public.sign_tasks to authenticated;
grant select, insert, update, delete on table public.sign_records to authenticated;

drop policy if exists "profiles read own or admin" on public.profiles;
create policy "profiles read own or admin"
on public.profiles for select
to authenticated
using ((select auth.uid()) = id or app_private.is_admin());

drop policy if exists "profiles update own display name" on public.profiles;
create policy "profiles update own display name"
on public.profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

drop policy if exists "authenticated users can read tasks" on public.sign_tasks;
create policy "authenticated users can read tasks"
on public.sign_tasks for select
to authenticated
using (true);

drop policy if exists "admins manage tasks" on public.sign_tasks;
create policy "admins manage tasks"
on public.sign_tasks for all
to authenticated
using (app_private.is_admin())
with check (app_private.is_admin());

drop policy if exists "records read own or admin" on public.sign_records;
create policy "records read own or admin"
on public.sign_records for select
to authenticated
using (user_id = (select auth.uid()) or app_private.is_admin());

drop policy if exists "users create own records" on public.sign_records;
create policy "users create own records"
on public.sign_records for insert
to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "users update own records or admins" on public.sign_records;
create policy "users update own records or admins"
on public.sign_records for update
to authenticated
using (user_id = (select auth.uid()) or app_private.is_admin())
with check (user_id = (select auth.uid()) or app_private.is_admin());

drop policy if exists "admins delete records" on public.sign_records;
create policy "admins delete records"
on public.sign_records for delete
to authenticated
using (app_private.is_admin());

insert into public.sign_tasks (title, time_range, location, remarks, status)
values
  ('早班签到', '08:30 - 09:00', '公司正门', '请务必穿工装', 'active'),
  ('项目A现场巡查', '10:00 - 11:00', '高新区工地', '带好安全帽', 'pending'),
  ('晚班签退', '18:00 - 18:30', '公司正门', '', 'pending')
on conflict do nothing;
