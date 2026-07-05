alter table public.sign_tasks
  add column if not exists start_time time,
  add column if not exists end_time time;

update public.sign_tasks
set
  start_time = coalesce(start_time, substring(time_range from '^\s*(\d{1,2}:\d{2})')::time),
  end_time = coalesce(end_time, substring(time_range from '-\s*(\d{1,2}:\d{2})\s*$')::time)
where time_range ~ '^\s*\d{1,2}:\d{2}\s*-\s*\d{1,2}:\d{2}\s*$';

update public.sign_tasks
set
  start_time = coalesce(start_time, '08:30'::time),
  end_time = coalesce(end_time, '09:00'::time);

alter table public.sign_tasks
  alter column start_time set not null,
  alter column end_time set not null;

alter table public.sign_tasks
  drop constraint if exists sign_tasks_time_order_check;

alter table public.sign_tasks
  add constraint sign_tasks_time_order_check check (start_time < end_time);
