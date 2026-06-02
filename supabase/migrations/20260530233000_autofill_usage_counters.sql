-- =====================================================================
-- ClaimPal AI autofill usage persistence
-- Adds a dedicated usage table plus RPC helpers for read/consume.
-- =====================================================================

begin;

create table if not exists public.autofill_usage_counters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  scope text not null check (scope in ('starter_lifetime', 'plus_monthly')),
  period_start date not null,
  used_count integer not null default 0 check (used_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint autofill_usage_counters_user_scope_period_unique
    unique (user_id, scope, period_start)
);

create index if not exists autofill_usage_counters_user_scope_period_idx
  on public.autofill_usage_counters (user_id, scope, period_start);

alter table public.autofill_usage_counters enable row level security;

create or replace function public.resolve_autofill_context(p_user_id uuid)
returns table (
  effective_tier text,
  autofill_limit integer,
  scope text,
  period_start date
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.profiles%rowtype;
begin
  if p_user_id is null then
    raise exception 'No authenticated user found';
  end if;

  select *
    into v_profile
    from public.profiles
   where id = p_user_id;

  if not found then
    raise exception 'Profile not found for current user';
  end if;

  if v_profile.premium_tier = 'pro' then
    return query
    select 'pro'::text, null::integer, 'pro_unlimited'::text, date_trunc('month', now())::date;
    return;
  end if;

  if v_profile.premium_until is not null and v_profile.premium_until > now() then
    return query
    select 'plus'::text, 5, 'plus_monthly'::text, date_trunc('month', now())::date;
    return;
  end if;

  return query
  select 'starter'::text, 2, 'starter_lifetime'::text, date '1970-01-01';
end;
$$;

create or replace function public.get_current_autofill_usage()
returns table (
  effective_tier text,
  autofill_limit integer,
  scope text,
  period_start date,
  used_count integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_effective_tier text;
  v_limit integer;
  v_scope text;
  v_period_start date;
  v_used integer;
begin
  select c.effective_tier, c.autofill_limit, c.scope, c.period_start
    into v_effective_tier, v_limit, v_scope, v_period_start
    from public.resolve_autofill_context(v_user_id) as c;

  if v_effective_tier = 'pro' then
    return query
    select v_effective_tier, v_limit, v_scope, v_period_start, 0;
    return;
  end if;

  insert into public.autofill_usage_counters (user_id, scope, period_start)
  values (v_user_id, v_scope, v_period_start)
  on conflict (user_id, scope, period_start) do nothing;

  select c.used_count
    into v_used
    from public.autofill_usage_counters as c
   where c.user_id = v_user_id
     and c.scope = v_scope
     and c.period_start = v_period_start;

  return query
  select v_effective_tier, v_limit, v_scope, v_period_start, coalesce(v_used, 0);
end;
$$;

create or replace function public.consume_autofill_credit()
returns table (
  effective_tier text,
  autofill_limit integer,
  scope text,
  period_start date,
  used_count integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_effective_tier text;
  v_limit integer;
  v_scope text;
  v_period_start date;
  v_used integer;
begin
  select c.effective_tier, c.autofill_limit, c.scope, c.period_start
    into v_effective_tier, v_limit, v_scope, v_period_start
    from public.resolve_autofill_context(v_user_id) as c;

  if v_effective_tier = 'pro' then
    return query
    select v_effective_tier, v_limit, v_scope, v_period_start, 0;
    return;
  end if;

  insert into public.autofill_usage_counters (user_id, scope, period_start)
  values (v_user_id, v_scope, v_period_start)
  on conflict (user_id, scope, period_start) do nothing;

  select c.used_count
    into v_used
    from public.autofill_usage_counters as c
   where c.user_id = v_user_id
     and c.scope = v_scope
     and c.period_start = v_period_start
   for update;

  if coalesce(v_used, 0) >= v_limit then
    raise exception 'No autofill credits remaining';
  end if;

  update public.autofill_usage_counters
     set used_count = used_count + 1,
         updated_at = now()
   where user_id = v_user_id
     and scope = v_scope
     and period_start = v_period_start
  returning used_count into v_used;

  return query
  select v_effective_tier, v_limit, v_scope, v_period_start, v_used;
end;
$$;

commit;