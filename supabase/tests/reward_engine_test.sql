-- =====================================================================
-- pgTAP suite: ClaimPal referral reward engine + column guard
-- Run with:  supabase test db
-- (Supabase's test runner wraps this in a transaction and rolls back,
--  so the auth.users / profiles rows we create here never persist.)
--
-- now() is stable within a transaction, so every "+ 30 days" assertion
-- is an EXACT equality against the trigger's own now() -- no tolerance
-- windows needed.
-- =====================================================================

begin;

-- pgTAP lives in the `extensions` schema on Supabase.
create extension if not exists pgtap with schema extensions;

select plan(11);

-- ---------------------------------------------------------------------
-- Act as the trusted backend so setup writes to the server-owned
-- premium columns are allowed by guard_privileged_columns().
-- ---------------------------------------------------------------------
set local "request.jwt.claims" = '{"role":"service_role"}';

-- ---------------------------------------------------------------------
-- Fixtures: six users. handle_new_user() auto-creates the matching
-- public.profiles rows (tier=starter, premium_until=null) on insert.
--   A -> B : referee has NULL premium_until      (base = now)
--   C -> D : referee has FUTURE premium_until     (stacking)
--   E -> F : referee has PAST premium_until        (reset to now)
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, email) values
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-00000000000a', 'a@test.dev'),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-00000000000b', 'b@test.dev'),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-00000000000c', 'c@test.dev'),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-00000000000d', 'd@test.dev'),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-00000000000e', 'e@test.dev'),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-00000000000f', 'f@test.dev');

-- Seed the non-NULL premium states.
update public.profiles
   set premium_until = timestamptz '2099-01-01 00:00:00+00', premium_tier = 'plus'
 where id = '00000000-0000-0000-0000-00000000000d';      -- D: future

update public.profiles
   set premium_until = now() - interval '100 days', premium_tier = 'plus'
 where id = '00000000-0000-0000-0000-00000000000f';      -- F: expired/past

-- Referral ledger rows (still 'registered').
insert into public.referrals (id, referrer_id, referee_id) values
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000b'),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000c', '00000000-0000-0000-0000-00000000000d'),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-00000000000e', '00000000-0000-0000-0000-00000000000f');

-- =====================================================================
-- Scenario 1 (A -> B): referee premium_until was NULL -> now() + 30d
-- =====================================================================
update public.referrals set status = 'first_claim_filed'
 where id = '10000000-0000-0000-0000-000000000001';

select is(
  (select premium_until from public.profiles where id = '00000000-0000-0000-0000-00000000000b'),
  now() + interval '30 days',
  'NULL base -> referee premium_until = now() + 30 days'
);
select is(
  (select premium_tier from public.profiles where id = '00000000-0000-0000-0000-00000000000b')::text,
  'plus',
  'starter referee is upgraded to plus'
);

-- BOTH parties rewarded: referrer A (also NULL) gets the same 30 days.
select is(
  (select premium_until from public.profiles where id = '00000000-0000-0000-0000-00000000000a'),
  now() + interval '30 days',
  'referrer is rewarded too -> premium_until = now() + 30 days'
);
select is(
  (select premium_tier from public.profiles where id = '00000000-0000-0000-0000-00000000000a')::text,
  'plus',
  'starter referrer is upgraded to plus'
);

-- =====================================================================
-- Scenario 2 (C -> D): future premium_until stacks (+30d from the
-- existing future date, NOT from now()).
-- =====================================================================
update public.referrals set status = 'first_claim_filed'
 where id = '10000000-0000-0000-0000-000000000002';

select is(
  (select premium_until from public.profiles where id = '00000000-0000-0000-0000-00000000000d'),
  timestamptz '2099-01-31 00:00:00+00',
  'future base stacks: 2099-01-01 + 30 days = 2099-01-31'
);
select is(
  (select premium_tier from public.profiles where id = '00000000-0000-0000-0000-00000000000d')::text,
  'plus',
  'existing plus tier is preserved (not downgraded)'
);

-- =====================================================================
-- Scenario 3 (E -> F): past premium_until is treated as expired ->
-- reset to now() + 30d (not extended from the stale past value).
-- =====================================================================
update public.referrals set status = 'first_claim_filed'
 where id = '10000000-0000-0000-0000-000000000003';

select is(
  (select premium_until from public.profiles where id = '00000000-0000-0000-0000-00000000000f'),
  now() + interval '30 days',
  'past base is ignored -> premium_until = now() + 30 days'
);

-- =====================================================================
-- Scenario 4: idempotency. Re-applying status='first_claim_filed' must
-- NOT grant another 30 days (trigger fires only on the transition).
-- =====================================================================
update public.referrals set status = 'first_claim_filed'
 where id = '10000000-0000-0000-0000-000000000001';

select is(
  (select premium_until from public.profiles where id = '00000000-0000-0000-0000-00000000000b'),
  now() + interval '30 days',
  'no-op status re-write does not double-grant'
);

-- =====================================================================
-- Scenario 5: data_version telemetry tracks MAX(settlements.version_id).
-- =====================================================================
insert into public.settlements (brand_name, max_payout, proof_required)
values ('Acme Data Breach', 125.00, false);

select is(
  (select (value)::bigint from public.global_meta where key = 'data_version'),
  (select max(version_id) from public.settlements),
  'global_meta.data_version == MAX(settlements.version_id)'
);

-- =====================================================================
-- Scenario 6: column guard. A non-service_role client cannot self-grant
-- premium nor flip a referral's status from the client.
-- =====================================================================
set local "request.jwt.claims" = '{"role":"authenticated"}';

select throws_ok(
  $$ update public.profiles set premium_tier = 'pro'
      where id = '00000000-0000-0000-0000-00000000000b' $$,
  'P0001',
  'profiles.premium_tier is server-owned and cannot be modified by the client',
  'client cannot self-promote premium_tier'
);

select throws_ok(
  $$ update public.referrals set status = 'first_claim_filed'
      where id = '10000000-0000-0000-0000-000000000003' $$,
  'P0001',
  'referrals.status is server-controlled and cannot be set by the client',
  'client cannot set referral status directly'
);

select * from finish();
rollback;
