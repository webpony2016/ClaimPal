begin;

drop table if exists public.pending_settlements;

alter table public.settlements
  drop constraint if exists settlements_max_payout_non_negative_check;

alter table public.settlements
  drop constraint if exists settlements_country_check;

alter table public.settlements
  drop column if exists country;

commit;
