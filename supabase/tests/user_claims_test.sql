begin;

create extension if not exists pgtap with schema extensions;

select plan(9);

set local "request.jwt.claims" = '{"role":"service_role"}';

insert into auth.users (instance_id, id, email) values
  ('00000000-0000-0000-0000-000000000000', '30000000-0000-0000-0000-000000000001', 'claim-user@test.dev'),
  ('00000000-0000-0000-0000-000000000000', '30000000-0000-0000-0000-000000000002', 'other-user@test.dev');

insert into public.settlements (
  id,
  brand_name,
  max_payout,
  deadline,
  eligibility_text,
  proof_required
)
values (
  '40000000-0000-0000-0000-000000000001',
  'ClaimPal Test Settlement',
  75.00,
  now() + interval '45 days',
  'Test eligibility',
  false
);

set local "request.jwt.claims" = '{"role":"authenticated","sub":"30000000-0000-0000-0000-000000000001"}';

select ok(
  public.mark_self_ineligible('40000000-0000-0000-0000-000000000001'),
  'user can mark a settlement as self-ineligible'
);

select is(
  (select status::text
     from public.user_claims
    where user_id = '30000000-0000-0000-0000-000000000001'
      and settlement_id = '40000000-0000-0000-0000-000000000001'),
  'self_ineligible',
  'self-ineligible state is persisted'
);

select is(
  (select count(*)
     from public.autofill_usage_counters
    where user_id = '30000000-0000-0000-0000-000000000001'),
  0::bigint,
  'marking self-ineligible does not consume autofill credit'
);

select ok(
  public.clear_self_ineligible('40000000-0000-0000-0000-000000000001'),
  'user can clear self-ineligible state'
);

select is(
  (select status::text
     from public.user_claims
    where user_id = '30000000-0000-0000-0000-000000000001'
      and settlement_id = '40000000-0000-0000-0000-000000000001'),
  'draft',
  'clearing self-ineligible returns claim to draft'
);

select is(
  (select status::text
     from public.submit_user_claim(
       '40000000-0000-0000-0000-000000000001',
       '{"action_required_fields":{"Purchase Year":"2019"},"uploaded_file_name":"receipt.pdf","signature_data":"sig:1"}'::jsonb
     )),
  'submitted',
  'submit_user_claim stores a submitted claim'
);

select is(
  (select used_count
     from public.autofill_usage_counters
    where user_id = '30000000-0000-0000-0000-000000000001'
      and scope = 'starter_lifetime'
      and period_start = date '1970-01-01'),
  1,
  'submit_user_claim consumes exactly one autofill credit'
);

set local "request.jwt.claims" = '{"role":"service_role"}';
update public.user_claims
   set status = 'rejected',
       current_stage = null,
       rejected_at = now()
 where user_id = '30000000-0000-0000-0000-000000000001'
   and settlement_id = '40000000-0000-0000-0000-000000000001';

set local "request.jwt.claims" = '{"role":"authenticated","sub":"30000000-0000-0000-0000-000000000001"}';

select is(
  (select attempt_count
     from public.submit_user_claim(
       '40000000-0000-0000-0000-000000000001',
       '{"action_required_fields":{"Purchase Year":"2020"},"uploaded_file_name":"receipt-2.pdf","signature_data":"sig:2"}'::jsonb
     )),
  2,
  're-submitting a rejected claim increments attempt_count'
);

select ok(
  (select payout_confirmed_at is not null
     from public.confirm_claim_payout(
       '40000000-0000-0000-0000-000000000001',
       42.50
     )),
  'user can confirm payout receipt'
);

select * from finish();
rollback;
