-- =====================================================================
-- ClaimPal — Core schema, RLS, and referral-reward engine
-- Target: Supabase (PostgreSQL 15+ / PostgREST + GoTrue auth)
-- Idempotent & migration-ready.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 0. Extensions
-- ---------------------------------------------------------------------
create extension if not exists "pgcrypto";   -- gen_random_uuid()

-- ---------------------------------------------------------------------
-- 1. Enumerated types
-- ---------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'premium_tier') then
    create type public.premium_tier as enum ('starter', 'plus', 'pro');
  end if;
  if not exists (select 1 from pg_type where typname = 'referral_status') then
    create type public.referral_status as enum ('registered', 'first_claim_filed');
  end if;
end$$;

-- =====================================================================
-- 2. TABLE: profiles
--    1:1 with auth.users. tier / premium_until are SERVER-OWNED
--    (mutated only by IAP webhooks or the reward engine, never by the
--    end user -- enforced by RLS + a column guard below).
-- =====================================================================
create table if not exists public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  email         text not null,
  premium_tier  public.premium_tier not null default 'starter',
  premium_until timestamptz,                       -- null = no active premium
  created_at    timestamptz not null default now()
);

comment on column public.profiles.premium_until is
  'Server-owned. Extended by the referral reward engine and IAP webhooks. Never user-writable.';

-- =====================================================================
-- 3. TABLE: settlements  (+ delta-sync versioning)
--    Each published row gets a monotonically increasing version_id.
--    Clients delta-sync with: WHERE version_id > <local_cache_version>.
-- =====================================================================
create sequence if not exists public.settlement_version_seq as bigint;

create table if not exists public.settlements (
  id              uuid primary key default gen_random_uuid(),
  brand_name      text not null,
  max_payout      numeric(14,2),                   -- USD/CAD; null = "up to TBD"
  deadline        timestamptz,
  eligibility_text text,
  proof_required  boolean not null default false,
  version_id      bigint not null default nextval('public.settlement_version_seq'),
  created_at      timestamptz not null default now()
);

-- Delta-sync cursor lookup (the hot path for GET /api/check-version deltas).
create index if not exists settlements_version_id_idx on public.settlements (version_id);
-- Active vs. recently-expired (deadline > now) / (now - deadline <= 180d) windows.
create index if not exists settlements_deadline_idx on public.settlements (deadline);

-- =====================================================================
-- 4. TABLE: global_meta  (dynamic key/value telemetry)
--    Holds the current global MAX data_version so the client's
--    lightweight version check is a single O(1) lookup.
-- =====================================================================
create table if not exists public.global_meta (
  key        text primary key,
  value      jsonb not null,
  updated_at timestamptz not null default now()
);

insert into public.global_meta (key, value)
values ('data_version', '0'::jsonb)
on conflict (key) do nothing;

-- Keep global_meta.data_version == MAX(settlements.version_id).
-- Fires whenever a settlement is published (insert) or re-versioned (update).
create or replace function public.sync_data_version()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.global_meta
     set value      = to_jsonb(new.version_id),
         updated_at = now()
   where key = 'data_version'
     and (value)::bigint < new.version_id;
  return new;
end;
$$;

drop trigger if exists trg_settlements_sync_version on public.settlements;
create trigger trg_settlements_sync_version
  after insert or update of version_id on public.settlements
  for each row execute function public.sync_data_version();

-- =====================================================================
-- 5. TABLE: referrals
--    "Give 1 Month, Get 1 Month" ledger. Kept anonymized: a user may
--    see rows they participate in, but the schema exposes no settlement
--    or payout detail (PRD 1.2 Privacy Guard).
-- =====================================================================
create table if not exists public.referrals (
  id          uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references public.profiles (id) on delete cascade,
  referee_id  uuid not null references public.profiles (id) on delete cascade,
  status      public.referral_status not null default 'registered',
  created_at  timestamptz not null default now(),

  constraint referrals_no_self_referral check (referrer_id <> referee_id),
  -- A given referee can only be the *referred* party once -> reward fires once.
  constraint referrals_referee_unique unique (referee_id)
);

create index if not exists referrals_referrer_id_idx on public.referrals (referrer_id);
create index if not exists referrals_referee_id_idx  on public.referrals (referee_id);

-- =====================================================================
-- 6. REWARD ENGINE
--    When a referral transitions INTO 'first_claim_filed', grant BOTH
--    parties +30 days. Base = max(now, current premium_until); if NULL
--    or past, base = now. Reward stacks infinitely (PRD 1.2).
--    SECURITY DEFINER so it bypasses RLS to write the server-owned
--    premium columns; fires only on the state transition (idempotent).
-- =====================================================================
create or replace function public.grant_referral_reward()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Only act on the registered -> first_claim_filed transition.
  if new.status = 'first_claim_filed'
     and old.status is distinct from 'first_claim_filed' then

    update public.profiles
       set premium_until =
             (case
                when premium_until is null or premium_until < now() then now()
                else premium_until
              end) + interval '30 days',
           -- Reward grants Plus; never downgrade an existing Pro.
           premium_tier =
             case when premium_tier = 'starter' then 'plus'::public.premium_tier
                  else premium_tier
             end
     where id in (new.referrer_id, new.referee_id);
  end if;

  return new;
end;
$$;

drop trigger if exists trg_referrals_grant_reward on public.referrals;
create trigger trg_referrals_grant_reward
  after update of status on public.referrals
  for each row execute function public.grant_referral_reward();

-- =====================================================================
-- 7. ROW-LEVEL SECURITY
-- =====================================================================

-- 7a. profiles --------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.profiles force row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select
  to authenticated
  using (id = auth.uid());

-- User may update their OWN row only. Privileged columns are protected
-- separately (7c) so a non-privileged UPDATE can't self-promote tier.
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- 7b. referrals -------------------------------------------------------
alter table public.referrals enable row level security;
alter table public.referrals force row level security;

-- A user sees a referral only if they are a participant. No payout or
-- settlement columns exist on this table, so visibility stays anonymized.
drop policy if exists "referrals_select_participant" on public.referrals;
create policy "referrals_select_participant"
  on public.referrals for select
  to authenticated
  using (referrer_id = auth.uid() or referee_id = auth.uid());

-- Status transitions (-> first_claim_filed) are driven by the trusted
-- backend (service_role), which bypasses RLS. We still scope any
-- client-side update to the participant to satisfy the requirement,
-- while the column guard (7c) blocks tampering with `status` itself.
drop policy if exists "referrals_update_participant" on public.referrals;
create policy "referrals_update_participant"
  on public.referrals for update
  to authenticated
  using (referrer_id = auth.uid() or referee_id = auth.uid())
  with check (referrer_id = auth.uid() or referee_id = auth.uid());

-- 7c. Column guard: block clients from mutating server-owned fields.
--     service_role / SECURITY DEFINER (IAP webhook, reward engine) is
--     exempt because those connections bypass RLS *and* triggers run as
--     the definer -- but this guard also fires for any direct client
--     write, so we whitelist the privileged path via the role check.
create or replace function public.guard_privileged_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Allow trusted backend roles to change anything.
  if (auth.role() = 'service_role') then
    return new;
  end if;

  if tg_table_name = 'profiles' then
    if new.premium_tier  is distinct from old.premium_tier
       or new.premium_until is distinct from old.premium_until
       or new.id    is distinct from old.id
       or new.email is distinct from old.email then
      raise exception 'profiles.% is server-owned and cannot be modified by the client',
        (case when new.premium_tier is distinct from old.premium_tier then 'premium_tier'
              when new.premium_until is distinct from old.premium_until then 'premium_until'
              else 'identity' end);
    end if;
  elsif tg_table_name = 'referrals' then
    if new.status is distinct from old.status
       or new.referrer_id is distinct from old.referrer_id
       or new.referee_id  is distinct from old.referee_id then
      raise exception 'referrals.status is server-controlled and cannot be set by the client';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_profiles_guard on public.profiles;
create trigger trg_profiles_guard
  before update on public.profiles
  for each row execute function public.guard_privileged_columns();

drop trigger if exists trg_referrals_guard on public.referrals;
create trigger trg_referrals_guard
  before update on public.referrals
  for each row execute function public.guard_privileged_columns();

-- 7d. settlements / global_meta -- public catalog data.
--     RLS is left enabled (Supabase tables are PostgREST-exposed by
--     default) with read-only access for authenticated clients; writes
--     go through the service_role admin path only.
alter table public.settlements enable row level security;
drop policy if exists "settlements_read_all" on public.settlements;
create policy "settlements_read_all"
  on public.settlements for select
  to authenticated
  using (true);

alter table public.global_meta enable row level security;
drop policy if exists "global_meta_read_all" on public.global_meta;
create policy "global_meta_read_all"
  on public.global_meta for select
  to authenticated
  using (true);

-- =====================================================================
-- 8. (Optional) Auto-provision a profile row when a user signs up.
--    Standard Supabase pattern; remove if you create profiles in code.
-- =====================================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

commit;
