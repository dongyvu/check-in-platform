alter table public.sign_tasks
  add column if not exists late_at timestamptz;

update public.sign_tasks
set late_at = coalesce(late_at, end_at);

alter table public.sign_tasks
  alter column late_at set not null;

alter table public.sign_tasks
  drop constraint if exists sign_tasks_late_at_range_check;

alter table public.sign_tasks
  add constraint sign_tasks_late_at_range_check
  check (start_at <= late_at and late_at <= end_at);

update public.sign_records records
set status = case
  when records.checked_at <= tasks.late_at then 'normal'
  else 'late'
end
from public.sign_tasks tasks
where records.task_id = tasks.id;
