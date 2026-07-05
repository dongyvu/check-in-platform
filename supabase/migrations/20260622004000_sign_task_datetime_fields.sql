alter table public.sign_tasks
  add column if not exists start_at timestamptz,
  add column if not exists end_at timestamptz;

update public.sign_tasks
set
  start_at = coalesce(
    start_at,
    ((current_date + start_time) at time zone 'Asia/Shanghai')
  ),
  end_at = coalesce(
    end_at,
    ((current_date + end_time) at time zone 'Asia/Shanghai')
  );

alter table public.sign_tasks
  alter column start_at set not null,
  alter column end_at set not null;

alter table public.sign_tasks
  drop constraint if exists sign_tasks_datetime_order_check;

alter table public.sign_tasks
  add constraint sign_tasks_datetime_order_check check (start_at < end_at);
