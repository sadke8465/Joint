begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(11);

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '10000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'user-a@example.test',
    'not-a-real-password-hash',
    statement_timestamp(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    statement_timestamp(),
    statement_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '10000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'user-b@example.test',
    'not-a-real-password-hash',
    statement_timestamp(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    statement_timestamp(),
    statement_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '10000000-0000-0000-0000-000000000003',
    'authenticated',
    'authenticated',
    'user-c@example.test',
    'not-a-real-password-hash',
    statement_timestamp(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    statement_timestamp(),
    statement_timestamp()
  );

insert into public.profiles (id, display_name, accent_color, app_language)
values
  ('10000000-0000-0000-0000-000000000001', 'User A', 'coral', 'en'),
  ('10000000-0000-0000-0000-000000000002', 'User B', 'blue', 'en'),
  ('10000000-0000-0000-0000-000000000003', 'User C', 'green', 'en');

insert into public.couples (id, created_by)
values
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000003');

insert into public.couple_members (couple_id, user_id, member_position)
values
  (
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    1
  ),
  (
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000002',
    2
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000003',
    1
  );

insert into public.tasks (
  id,
  couple_id,
  title,
  assignee_kind,
  assignee_user_id,
  created_by
)
values
  (
    '30000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    'Couple 1 task',
    'person',
    '10000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001'
  ),
  (
    '30000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000002',
    'User C task',
    'person',
    '10000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000003'
  );

insert into public.device_tokens (id, user_id, token, environment)
values
  (
    '40000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'token-a',
    'development'
  ),
  (
    '40000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    'token-b',
    'development'
  ),
  (
    '40000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000003',
    'token-c',
    'development'
  );

set local role authenticated;

select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000001',
  true
);

select is(
  (select count(*) from public.couples),
  1::bigint,
  'A can select only Couple 1'
);

select is(
  (select count(*) from public.profiles),
  2::bigint,
  'A can select A and partner B profiles'
);

select is(
  (select count(*) from public.device_tokens),
  1::bigint,
  'A can select only A device tokens'
);

select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000002',
  true
);

select is(
  (
    select count(*)
    from public.tasks
    where id = '30000000-0000-0000-0000-000000000001'
  ),
  1::bigint,
  'B can select the shared Couple 1 task'
);

select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000003',
  true
);

select is(
  (
    select count(*)
    from public.couples
    where id = '20000000-0000-0000-0000-000000000001'
  ),
  0::bigint,
  'C cannot select Couple 1'
);

select is(
  (
    select count(*)
    from public.tasks
    where id = '30000000-0000-0000-0000-000000000001'
  ),
  0::bigint,
  'C cannot select Couple 1 tasks'
);

with changed as (
  update public.tasks
  set title = 'Unauthorized change'
  where id = '30000000-0000-0000-0000-000000000001'
  returning id
)
select is(
  (select count(*) from changed),
  0::bigint,
  'C cannot update Couple 1 tasks'
);

select throws_ok(
  $$
    insert into public.tasks (
      couple_id,
      title,
      assignee_kind,
      assignee_user_id,
      created_by
    )
    values (
      '20000000-0000-0000-0000-000000000001',
      'Unauthorized task',
      'person',
      '10000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001'
    )
  $$,
  '42501',
  'new row violates row-level security policy for table "tasks"',
  'C cannot insert tasks into Couple 1'
);

select is(
  (
    select count(*)
    from public.device_tokens
    where user_id = '10000000-0000-0000-0000-000000000001'
  ),
  0::bigint,
  'C cannot read A device tokens'
);

select is(
  (select count(*) from public.device_tokens),
  1::bigint,
  'C can still read C device tokens'
);

select is(
  (
    select count(*)
    from public.tasks
    where id = '30000000-0000-0000-0000-000000000002'
  ),
  1::bigint,
  'C can still select C own-couple tasks'
);

select * from finish();

reset role;
rollback;
