-- =====================================================================
-- ROLLBACK for 20260530172624_init_claimpal_schema.sql
--
-- NOTE: kept OUTSIDE supabase/migrations/ on purpose. The Supabase CLI
-- treats every *.sql in migrations/ as a forward migration keyed by its
-- timestamp prefix, so a "down" file living there would either be run
-- forward or collide with the up-migration's version. Run this manually:
--
--   psql "$DATABASE_URL" -f supabase/rollback/20260530172624_init_claimpal_schema_down.sql
--
-- Objects are dropped in reverse dependency order. Policies and table-
-- owned triggers drop implicitly with their tables; functions, the
-- auth.users trigger, the sequence and the enum types are dropped
-- explicitly because they outlive the public tables.
-- =====================================================================

begin;

-- 8. auth.users provisioning trigger + function -----------------------
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- 7c. column guard ----------------------------------------------------
drop trigger if exists trg_profiles_guard  on public.profiles;
drop trigger if exists trg_referrals_guard on public.referrals;
drop function if exists public.guard_privileged_columns();

-- 6. reward engine ----------------------------------------------------
drop trigger if exists trg_referrals_grant_reward on public.referrals;
drop function if exists public.grant_referral_reward();

-- 4. data_version sync ------------------------------------------------
drop trigger if exists trg_settlements_sync_version on public.settlements;
drop function if exists public.sync_data_version();

-- 5/3/4/2. tables (their RLS policies, indexes and FKs drop with them)-
drop table if exists public.referrals;
drop table if exists public.settlements;
drop table if exists public.global_meta;
drop table if exists public.profiles;

-- 3. sequence ---------------------------------------------------------
drop sequence if exists public.settlement_version_seq;

-- 1. enum types -------------------------------------------------------
drop type if exists public.referral_status;
drop type if exists public.premium_tier;

commit;
