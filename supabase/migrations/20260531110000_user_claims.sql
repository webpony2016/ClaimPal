begin;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'claim_status') then
    create type public.claim_status as enum (
      'draft',
      'submitted',
      'under_review',
      'approved',
      'payout_sent',
      'rejected',
      'self_ineligible'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'claim_stage') then
    create type public.claim_stage as enum (
      'ai_submitted',
      'court_review',
      'settlement_approved',
      'payout_sent'
    );
  end if;
end$$;

create table if not exists public.user_claims (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  settlement_id uuid not null references public.settlements (id) on delete cascade,
  status public.claim_status not null default 'draft',
  current_stage public.claim_stage,
  filing_data jsonb not null default '{}'::jsonb,
  attempt_count integer not null default 0 check (attempt_count >= 0),
  payout_amount numeric(14,2) check (payout_amount is null or payout_amount >= 0),
  submitted_at timestamptz,
  reviewed_at timestamptz,
  rejected_at timestamptz,
  payout_confirmed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint user_claims_user_settlement_unique unique (user_id, settlement_id),
  constraint user_claims_stage_consistency check (
    (current_stage is null and status in ('draft', 'rejected', 'self_ineligible'))
    or
    (current_stage is not null and status in ('submitted', 'under_review', 'approved', 'payout_sent'))
  )
);

create index if not exists user_claims_user_id_idx
  on public.user_claims (user_id);
create index if not exists user_claims_settlement_id_idx
  on public.user_claims (settlement_id);
create index if not exists user_claims_status_idx
  on public.user_claims (status);
create index if not exists user_claims_updated_at_idx
  on public.user_claims (updated_at desc);

create or replace function public.touch_user_claims_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_user_claims_touch_updated_at on public.user_claims;
create trigger trg_user_claims_touch_updated_at
  before update on public.user_claims
  for each row execute function public.touch_user_claims_updated_at();

alter table public.user_claims enable row level security;

drop policy if exists "user_claims_select_own" on public.user_claims;
create policy "user_claims_select_own"
  on public.user_claims for select
  to authenticated
  using (user_id = auth.uid());

create or replace function public.submit_user_claim(
  p_settlement_id uuid,
  p_filing_data jsonb default '{}'::jsonb
)
returns table (
  claim_id uuid,
  status public.claim_status,
  current_stage public.claim_stage,
  attempt_count integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing public.user_claims%rowtype;
  v_attempt_count integer;
begin
  if v_user_id is null then
    raise exception 'No authenticated user found';
  end if;

  perform 1
    from public.settlements
   where id = p_settlement_id;

  if not found then
    raise exception 'Settlement not found';
  end if;

  select *
    into v_existing
    from public.user_claims
   where user_id = v_user_id
     and settlement_id = p_settlement_id
   for update;

  if found and v_existing.status in ('submitted', 'under_review', 'approved', 'payout_sent') then
    raise exception 'Claim already submitted';
  end if;

  perform public.consume_autofill_credit();

  if found then
    v_attempt_count := greatest(v_existing.attempt_count, 0) + 1;

    update public.user_claims
       set status = 'submitted',
           current_stage = 'ai_submitted',
           filing_data = coalesce(p_filing_data, '{}'::jsonb),
           attempt_count = v_attempt_count,
           submitted_at = now(),
           reviewed_at = null,
           rejected_at = null
     where id = v_existing.id
     returning public.user_claims.id,
               public.user_claims.status,
               public.user_claims.current_stage,
               public.user_claims.attempt_count
          into claim_id, status, current_stage, attempt_count;
  else
    insert into public.user_claims (
      user_id,
      settlement_id,
      status,
      current_stage,
      filing_data,
      attempt_count,
      submitted_at
    )
    values (
      v_user_id,
      p_settlement_id,
      'submitted',
      'ai_submitted',
      coalesce(p_filing_data, '{}'::jsonb),
      1,
      now()
    )
    returning public.user_claims.id,
              public.user_claims.status,
              public.user_claims.current_stage,
              public.user_claims.attempt_count
         into claim_id, status, current_stage, attempt_count;
  end if;

  return next;
end;
$$;

create or replace function public.mark_self_ineligible(
  p_settlement_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing public.user_claims%rowtype;
begin
  if v_user_id is null then
    raise exception 'No authenticated user found';
  end if;

  select *
    into v_existing
    from public.user_claims
   where user_id = v_user_id
     and settlement_id = p_settlement_id
   for update;

  if found and v_existing.status in ('submitted', 'under_review', 'approved', 'payout_sent') then
    raise exception 'Submitted claims cannot be marked self-ineligible';
  end if;

  insert into public.user_claims (user_id, settlement_id, status)
  values (v_user_id, p_settlement_id, 'self_ineligible')
  on conflict (user_id, settlement_id)
  do update
        set status = 'self_ineligible',
            current_stage = null,
            reviewed_at = null,
            rejected_at = null;

  return true;
end;
$$;

create or replace function public.clear_self_ineligible(
  p_settlement_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'No authenticated user found';
  end if;

  update public.user_claims
     set status = 'draft',
         current_stage = null
   where user_id = v_user_id
     and settlement_id = p_settlement_id
     and status = 'self_ineligible';

  return found;
end;
$$;

create or replace function public.confirm_claim_payout(
  p_settlement_id uuid,
  p_payout_amount numeric(14,2)
)
returns table (
  claim_id uuid,
  status public.claim_status,
  payout_amount numeric(14,2),
  payout_confirmed_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'No authenticated user found';
  end if;

  if p_payout_amount < 0 then
    raise exception 'Payout amount must be non-negative';
  end if;

  update public.user_claims
     set status = 'payout_sent',
         current_stage = 'payout_sent',
         payout_amount = p_payout_amount,
         payout_confirmed_at = now()
   where user_id = v_user_id
     and settlement_id = p_settlement_id
  returning public.user_claims.id,
            public.user_claims.status,
            public.user_claims.payout_amount,
            public.user_claims.payout_confirmed_at
       into claim_id, status, payout_amount, payout_confirmed_at;

  if claim_id is null then
    raise exception 'No claim found for settlement';
  end if;

  return next;
end;
$$;

commit;
