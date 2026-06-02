begin;

drop function if exists public.confirm_claim_payout(uuid, numeric);
drop function if exists public.clear_self_ineligible(uuid);
drop function if exists public.mark_self_ineligible(uuid);
drop function if exists public.submit_user_claim(uuid, jsonb);
drop trigger if exists trg_user_claims_touch_updated_at on public.user_claims;
drop function if exists public.touch_user_claims_updated_at();

drop table if exists public.user_claims;

drop type if exists public.claim_stage;
drop type if exists public.claim_status;

commit;
