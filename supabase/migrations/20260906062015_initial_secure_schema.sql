-- Couples Todo foundational schema.
--
-- Access to shared data is derived exclusively from couple_members. Tables that
-- ordinary clients must not mutate directly receive no corresponding grants.

create schema if not exists private;

revoke all on schema private from public;
grant usage on schema private to authenticated;

alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke execute on functions from public;
alter default privileges in schema private revoke execute on functions from public;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  avatar_path text,
  accent_color text not null,
  app_language text not null,
  hebrew_address_style text,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint profiles_display_name_length
    check (char_length(btrim(display_name)) between 1 and 80),
  constraint profiles_accent_color_length
    check (char_length(btrim(accent_color)) between 1 and 64),
  constraint profiles_app_language_supported
    check (app_language in ('en', 'he')),
  constraint profiles_hebrew_address_style_length
    check (
      hebrew_address_style is null
      or char_length(btrim(hebrew_address_style)) between 1 and 64
    )
);

create table public.couples (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  dissolved_at timestamptz,
  constraint couples_dissolved_after_creation
    check (dissolved_at is null or dissolved_at >= created_at)
);

create table public.couple_members (
  couple_id uuid not null references public.couples (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default statement_timestamp(),
  member_position smallint not null,
  primary key (couple_id, user_id),
  constraint couple_members_one_couple_per_user unique (user_id),
  constraint couple_members_position_per_couple unique (couple_id, member_position),
  constraint couple_members_valid_position check (member_position in (1, 2))
);

create table public.couple_invites (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  created_by uuid not null references public.profiles (id) on delete restrict,
  token_hash text not null,
  short_code_hash text not null,
  expires_at timestamptz not null,
  accepted_by uuid references public.profiles (id) on delete restrict,
  accepted_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default statement_timestamp(),
  constraint couple_invites_token_hash_unique unique (token_hash),
  constraint couple_invites_short_code_hash_unique unique (short_code_hash),
  constraint couple_invites_token_hash_not_blank check (btrim(token_hash) <> ''),
  constraint couple_invites_short_code_hash_not_blank check (btrim(short_code_hash) <> ''),
  constraint couple_invites_expires_after_creation check (expires_at > created_at),
  constraint couple_invites_acceptance_complete
    check ((accepted_by is null) = (accepted_at is null)),
  constraint couple_invites_terminal_state
    check (accepted_at is null or revoked_at is null)
);

create table public.lists (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  emoji text not null,
  internal_name text,
  sort_order integer not null default 0,
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  deleted_at timestamptz,
  constraint lists_emoji_length check (char_length(emoji) between 1 and 16),
  constraint lists_internal_name_length
    check (internal_name is null or char_length(btrim(internal_name)) between 1 and 120),
  constraint lists_sort_order_nonnegative check (sort_order >= 0),
  constraint lists_deleted_after_creation check (deleted_at is null or deleted_at >= created_at)
);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  title text not null,
  notes text,
  assignee_kind text not null,
  assignee_user_id uuid references public.profiles (id) on delete restrict,
  due_date date,
  due_time time,
  list_id uuid references public.lists (id) on delete set null,
  status text not null default 'active',
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  completed_by uuid references public.profiles (id) on delete restrict,
  completed_at timestamptz,
  deleted_at timestamptz,
  constraint tasks_title_length check (char_length(btrim(title)) between 1 and 500),
  constraint tasks_assignee_kind_supported
    check (assignee_kind in ('person', 'together')),
  constraint tasks_assignee_integrity
    check (
      (assignee_kind = 'person' and assignee_user_id is not null)
      or (assignee_kind = 'together' and assignee_user_id is null)
    ),
  constraint tasks_due_time_requires_date check (due_time is null or due_date is not null),
  constraint tasks_status_supported check (status in ('active', 'completed')),
  constraint tasks_completion_integrity
    check (
      (status = 'active' and completed_by is null and completed_at is null)
      or (status = 'completed' and completed_by is not null and completed_at is not null)
    ),
  constraint tasks_deleted_after_creation check (deleted_at is null or deleted_at >= created_at)
);

create table public.notification_preferences (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  timezone text not null default 'UTC',
  evening_before_enabled boolean not null default true,
  evening_before_time time not null default time '21:00',
  morning_of_enabled boolean not null default true,
  morning_of_time time not null default time '10:00',
  evening_of_enabled boolean not null default true,
  evening_of_time time not null default time '18:30',
  notify_task_assigned boolean not null default true,
  notify_task_reassigned boolean not null default true,
  notify_task_date_changed boolean not null default true,
  notify_task_completed boolean not null default true,
  notify_task_uncompleted boolean not null default true,
  badge_enabled boolean not null default true,
  updated_at timestamptz not null default statement_timestamp(),
  constraint notification_preferences_timezone_not_blank check (btrim(timezone) <> '')
);

create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  token text not null,
  platform text not null default 'ios',
  environment text not null,
  app_version text,
  last_seen_at timestamptz not null default statement_timestamp(),
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint device_tokens_user_token_unique unique (user_id, token),
  constraint device_tokens_token_not_blank check (btrim(token) <> ''),
  constraint device_tokens_platform_not_blank check (btrim(platform) <> ''),
  constraint device_tokens_environment_supported
    check (environment in ('development', 'production')),
  constraint device_tokens_app_version_length
    check (app_version is null or char_length(btrim(app_version)) between 1 and 64)
);

create table public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  couple_id uuid not null references public.couples (id) on delete cascade,
  kind text not null,
  local_date date not null,
  slot text not null,
  sent_at timestamptz not null default statement_timestamp(),
  dedupe_key text not null,
  constraint notification_deliveries_dedupe_key_unique unique (dedupe_key),
  constraint notification_deliveries_kind_not_blank check (btrim(kind) <> ''),
  constraint notification_deliveries_slot_not_blank check (btrim(slot) <> ''),
  constraint notification_deliveries_dedupe_key_not_blank check (btrim(dedupe_key) <> '')
);

comment on table public.couple_invites is
  'Server-controlled invitation records. Only hashes of reusable secrets are stored.';
comment on table public.notification_deliveries is
  'Server-written notification ledger used to prevent duplicate delivery.';

-- Foreign-key and application query indexes not already covered by unique indexes.
create index couples_created_by_idx on public.couples (created_by);
create index couple_invites_created_by_idx on public.couple_invites (created_by);
create index couple_invites_open_idx
  on public.couple_invites (couple_id, expires_at)
  where accepted_at is null and revoked_at is null;
create index lists_created_by_idx on public.lists (created_by);
create index lists_active_couple_sort_idx
  on public.lists (couple_id, sort_order, id)
  where deleted_at is null;
create index tasks_created_by_idx on public.tasks (created_by);
create index tasks_completed_by_idx on public.tasks (completed_by)
  where completed_by is not null;
create index tasks_list_id_idx on public.tasks (list_id)
  where list_id is not null;
create index tasks_active_couple_due_idx
  on public.tasks (couple_id, due_date, due_time, id)
  where status = 'active' and deleted_at is null;
create index tasks_active_assignee_due_idx
  on public.tasks (assignee_user_id, due_date, due_time, id)
  where status = 'active' and deleted_at is null and assignee_user_id is not null;
create index notification_deliveries_user_date_idx
  on public.notification_deliveries (user_id, local_date, slot);
create index notification_deliveries_couple_id_idx
  on public.notification_deliveries (couple_id);

-- Trigger helpers live outside the Data API schemas and use fully-qualified names.
create or replace function private.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at := statement_timestamp();
  return new;
end;
$$;

create or replace function private.enforce_profile_integrity()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.id is distinct from old.id or new.created_at is distinct from old.created_at then
    raise exception 'Profile identity and creation time are immutable'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create or replace function private.enforce_two_members()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Serialize membership additions for the same couple to avoid a count race.
  perform 1
  from public.couples
  where id = new.couple_id
  for update;

  if (select count(*) from public.couple_members where couple_id = new.couple_id) >= 2 then
    raise exception 'A couple cannot have more than two members'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create or replace function private.enforce_invite_integrity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and (
    new.id is distinct from old.id
    or new.couple_id is distinct from old.couple_id
    or new.created_by is distinct from old.created_by
    or new.token_hash is distinct from old.token_hash
    or new.short_code_hash is distinct from old.short_code_hash
    or new.expires_at is distinct from old.expires_at
    or new.created_at is distinct from old.created_at
  ) then
    raise exception 'Invite identity, couple, secrets, expiry, creator, and creation time are immutable'
      using errcode = '23514';
  end if;

  if not exists (
    select 1
    from public.couple_members
    where couple_id = new.couple_id and user_id = new.created_by
  ) then
    raise exception 'Invite creator must belong to the invite couple'
      using errcode = '23514';
  end if;

  if new.accepted_by is not null and not exists (
    select 1
    from public.couple_members
    where couple_id = new.couple_id and user_id = new.accepted_by
  ) then
    raise exception 'Invite acceptor must belong to the invite couple'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create or replace function private.enforce_list_integrity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and (
    new.id is distinct from old.id
    or new.couple_id is distinct from old.couple_id
    or new.created_by is distinct from old.created_by
    or new.created_at is distinct from old.created_at
  ) then
    raise exception 'List identity, couple, creator, and creation time are immutable'
      using errcode = '23514';
  end if;

  if not exists (
    select 1
    from public.couple_members
    where couple_id = new.couple_id and user_id = new.created_by
  ) then
    raise exception 'List creator must belong to the list couple'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create or replace function private.enforce_task_integrity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and (
    new.id is distinct from old.id
    or new.couple_id is distinct from old.couple_id
    or new.created_by is distinct from old.created_by
    or new.created_at is distinct from old.created_at
  ) then
    raise exception 'Task identity, couple, creator, and creation time are immutable'
      using errcode = '23514';
  end if;

  if not exists (
    select 1
    from public.couple_members
    where couple_id = new.couple_id and user_id = new.created_by
  ) then
    raise exception 'Task creator must belong to the task couple'
      using errcode = '23514';
  end if;

  if new.assignee_user_id is not null and not exists (
    select 1
    from public.couple_members
    where couple_id = new.couple_id and user_id = new.assignee_user_id
  ) then
    raise exception 'Task assignee must belong to the task couple'
      using errcode = '23514';
  end if;

  if new.completed_by is not null and not exists (
    select 1
    from public.couple_members
    where couple_id = new.couple_id and user_id = new.completed_by
  ) then
    raise exception 'Task completer must belong to the task couple'
      using errcode = '23514';
  end if;

  if new.list_id is not null and not exists (
    select 1
    from public.lists
    where id = new.list_id and couple_id = new.couple_id
  ) then
    raise exception 'Task list must belong to the task couple'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create or replace function private.enforce_device_token_integrity()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.id is distinct from old.id
    or new.user_id is distinct from old.user_id
    or new.created_at is distinct from old.created_at
  then
    raise exception 'Device token identity, owner, and creation time are immutable'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger profiles_enforce_integrity
before update on public.profiles
for each row execute function private.enforce_profile_integrity();

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function private.set_updated_at();

create trigger couples_set_updated_at
before update on public.couples
for each row execute function private.set_updated_at();

create trigger couple_members_enforce_two_members
before insert on public.couple_members
for each row execute function private.enforce_two_members();

create trigger couple_invites_enforce_integrity
before insert or update on public.couple_invites
for each row execute function private.enforce_invite_integrity();

create trigger lists_enforce_integrity
before insert or update on public.lists
for each row execute function private.enforce_list_integrity();

create trigger lists_set_updated_at
before update on public.lists
for each row execute function private.set_updated_at();

create trigger tasks_enforce_integrity
before insert or update on public.tasks
for each row execute function private.enforce_task_integrity();

create trigger tasks_set_updated_at
before update on public.tasks
for each row execute function private.set_updated_at();

create trigger notification_preferences_set_updated_at
before update on public.notification_preferences
for each row execute function private.set_updated_at();

create trigger device_tokens_set_updated_at
before update on public.device_tokens
for each row execute function private.set_updated_at();

create trigger device_tokens_enforce_integrity
before update on public.device_tokens
for each row execute function private.enforce_device_token_integrity();

-- SECURITY DEFINER helpers prevent recursive RLS evaluation while exposing only booleans.
create or replace function private.is_couple_member(target_couple_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.couple_members
    where couple_id = target_couple_id
      and user_id = (select auth.uid())
  );
$$;

create or replace function private.shares_couple(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.couple_members viewer
    join public.couple_members target using (couple_id)
    where viewer.user_id = (select auth.uid())
      and target.user_id = target_user_id
  );
$$;

revoke all on function private.set_updated_at() from public;
revoke all on function private.enforce_profile_integrity() from public;
revoke all on function private.enforce_two_members() from public;
revoke all on function private.enforce_invite_integrity() from public;
revoke all on function private.enforce_list_integrity() from public;
revoke all on function private.enforce_task_integrity() from public;
revoke all on function private.enforce_device_token_integrity() from public;
revoke all on function private.is_couple_member(uuid) from public;
revoke all on function private.shares_couple(uuid) from public;
grant execute on function private.is_couple_member(uuid) to authenticated;
grant execute on function private.shares_couple(uuid) to authenticated;

-- Data API access is explicit. The anon role receives no table privileges.
revoke all on all tables in schema public from anon, authenticated;

grant select, insert, update on table public.profiles to authenticated;
grant select on table public.couples to authenticated;
grant select on table public.couple_members to authenticated;
grant select (
  id,
  couple_id,
  created_by,
  expires_at,
  accepted_by,
  accepted_at,
  revoked_at,
  created_at
) on table public.couple_invites to authenticated;
grant select, insert, update on table public.lists to authenticated;
grant select, insert, update on table public.tasks to authenticated;
grant select, insert, update on table public.notification_preferences to authenticated;
grant select, insert, update, delete on table public.device_tokens to authenticated;
grant select on table public.notification_deliveries to authenticated;

alter table public.profiles enable row level security;
alter table public.couples enable row level security;
alter table public.couple_members enable row level security;
alter table public.couple_invites enable row level security;
alter table public.lists enable row level security;
alter table public.tasks enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.device_tokens enable row level security;
alter table public.notification_deliveries enable row level security;

create policy profiles_select_shared_couple
on public.profiles
for select
to authenticated
using (id = (select auth.uid()) or private.shares_couple(id));

create policy profiles_insert_own
on public.profiles
for insert
to authenticated
with check (id = (select auth.uid()));

create policy profiles_update_own
on public.profiles
for update
to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy couples_select_member
on public.couples
for select
to authenticated
using (private.is_couple_member(id));

create policy couple_members_select_member
on public.couple_members
for select
to authenticated
using (private.is_couple_member(couple_id));

create policy couple_invites_select_member
on public.couple_invites
for select
to authenticated
using (private.is_couple_member(couple_id));

create policy lists_select_member
on public.lists
for select
to authenticated
using (private.is_couple_member(couple_id));

create policy lists_insert_member
on public.lists
for insert
to authenticated
with check (
  private.is_couple_member(couple_id)
  and created_by = (select auth.uid())
);

create policy lists_update_member
on public.lists
for update
to authenticated
using (private.is_couple_member(couple_id))
with check (private.is_couple_member(couple_id));

create policy tasks_select_member
on public.tasks
for select
to authenticated
using (private.is_couple_member(couple_id));

create policy tasks_insert_member
on public.tasks
for insert
to authenticated
with check (
  private.is_couple_member(couple_id)
  and created_by = (select auth.uid())
);

create policy tasks_update_member
on public.tasks
for update
to authenticated
using (private.is_couple_member(couple_id))
with check (private.is_couple_member(couple_id));

create policy notification_preferences_select_own
on public.notification_preferences
for select
to authenticated
using (user_id = (select auth.uid()));

create policy notification_preferences_insert_own
on public.notification_preferences
for insert
to authenticated
with check (user_id = (select auth.uid()));

create policy notification_preferences_update_own
on public.notification_preferences
for update
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy device_tokens_select_own
on public.device_tokens
for select
to authenticated
using (user_id = (select auth.uid()));

create policy device_tokens_insert_own
on public.device_tokens
for insert
to authenticated
with check (user_id = (select auth.uid()));

create policy device_tokens_update_own
on public.device_tokens
for update
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy device_tokens_delete_own
on public.device_tokens
for delete
to authenticated
using (user_id = (select auth.uid()));

create policy notification_deliveries_select_own
on public.notification_deliveries
for select
to authenticated
using (user_id = (select auth.uid()));

-- Realtime is limited to shared UI state; secrets and delivery data are excluded.
alter table public.profiles replica identity full;
alter table public.couples replica identity full;
alter table public.couple_members replica identity full;
alter table public.lists replica identity full;
alter table public.tasks replica identity full;

do $$
declare
  realtime_table text;
begin
  foreach realtime_table in array array[
    'profiles',
    'couples',
    'couple_members',
    'lists',
    'tasks'
  ]
  loop
    if not exists (
      select 1
      from pg_catalog.pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = realtime_table
    ) then
      execute format(
        'alter publication supabase_realtime add table public.%I',
        realtime_table
      );
    end if;
  end loop;
end;
$$;
