-- =====================================================================
-- pgTAP suite: ClaimPal autofill usage persistence + RPC guards
-- =====================================================================

begin;

create extension if not exists pgtap with schema extensions;

select plan(10);

set local "request.jwt.claims" = '{"role":"service_role"}';

insert into auth.users (instance_id, id, email) values
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000001', 'starter@test.dev'),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000002', 'plus@test.dev'),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000003', 'pro@test.dev');

update public.profiles
   set premium_tier = 'plus',
       premium_until = now() + interval '30 days'
 where id = '20000000-0000-0000-0000-000000000002';

update public.profiles
   set premium_tier = 'pro'
 where id = '20000000-0000-0000-0000-000000000003';

set local "request.jwt.claims" = '{"role":"authenticated","sub":"20000000-0000-0000-0000-000000000001"}';

select is(
  (select effective_tier from public.get_current_autofill_usage() limit 1),
  'starter',
  'starter user resolves to starter tier'
);

select is(
  (select used_count from public.get_current_autofill_usage() limit 1),
  0,
  'starter usage begins at 0'
);

select is(
  (select used_count from public.consume_autofill_credit() limit 1),
  1,
  'starter first consume increments to 1'
);

select is(
  (select used_count from public.consume_autofill_credit() limit 1),
  2,
  'starter second consume increments to 2'
);

select throws_ok(
  $$ select * from public.consume_autofill_credit() $$,
  'P0001',
  'No autofill credits remaining',
  'starter third consume is blocked'
);

select is(
  (select used_count
     from public.autofill_usage_counters
    where user_id = '20000000-0000-0000-0000-000000000001'
      and scope = 'starter_lifetime'
      and period_start = date '1970-01-01'),
  2,
  'starter lifetime bucket persists the used count'
);

set local "request.jwt.claims" = '{"role":"authenticated","sub":"20000000-0000-0000-0000-000000000002"}';

select is(
  (select scope from public.get_current_autofill_usage() limit 1),
  'plus_monthly',
  'plus user resolves to monthly bucket'
);

select is(
  (select period_start from public.get_current_autofill_usage() limit 1),
  date_trunc('month', now())::date,
  'plus bucket starts at the current month boundary'
);

select is(
  (select used_count from public.consume_autofill_credit() limit 1),
  1,
  'plus consume increments the monthly bucket'
);

set local "request.jwt.claims" = '{"role":"authenticated","sub":"20000000-0000-0000-0000-000000000003"}';

select is(
  (select used_count from public.consume_autofill_credit() limit 1),
  0,
  'pro consume is a no-op because usage is unlimited'
);

select * from finish();
rollback;