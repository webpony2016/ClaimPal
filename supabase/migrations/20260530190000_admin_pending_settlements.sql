-- =====================================================================
-- ClaimPal admin review pool
-- Adds pending scraped settlement review rows and live settlement country.
-- =====================================================================

begin;

create extension if not exists "pgcrypto";

alter table public.settlements
  add column country text;

alter table public.settlements
  add constraint settlements_country_check
  check (country is null or country in ('US', 'CA'));

alter table public.settlements
  add constraint settlements_max_payout_non_negative_check
  check (max_payout is null or max_payout >= 0);

create table if not exists public.pending_settlements (
  id uuid primary key default gen_random_uuid(),
  source_url text,
  raw_content text not null,
  raw_content_type text not null default 'text',
  brand_name text not null,
  max_payout numeric(14,2) check (max_payout is null or max_payout >= 0),
  country text not null check (country in ('US', 'CA')),
  proof_required boolean not null default false,
  deadline date,
  eligibility_text text,
  ai_payload jsonb not null default '{}'::jsonb,
  scraper_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists pending_settlements_created_at_idx
  on public.pending_settlements (created_at);

alter table public.pending_settlements enable row level security;

drop policy if exists "pending_settlements_no_client_access" on public.pending_settlements;
create policy "pending_settlements_no_client_access"
  on public.pending_settlements
  as restrictive
  for all
  to anon, authenticated
  using (false)
  with check (false);

commit;
