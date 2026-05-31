begin;

alter table public.pending_settlements
  drop column if exists reviewed_at;

commit;
