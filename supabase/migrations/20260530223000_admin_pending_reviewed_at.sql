begin;

alter table public.pending_settlements
  add column if not exists reviewed_at timestamptz;

commit;
