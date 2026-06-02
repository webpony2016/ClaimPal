begin;

drop function if exists public.consume_autofill_credit();
drop function if exists public.get_current_autofill_usage();
drop function if exists public.resolve_autofill_context(uuid);

drop table if exists public.autofill_usage_counters;

commit;