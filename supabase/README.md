# Supabase development

This directory owns the reproducible backend definition for Couples Todo. The
initial migration creates the complete Phase 4 schema, server-side integrity
checks, least-privilege Data API grants, row-level security, and the Realtime
publication allow-list.

## Local workflow

Prerequisites are the Supabase CLI and a Docker-compatible local container
runtime.

```sh
supabase start
supabase db reset
```

`supabase db reset` rebuilds the local database from the committed migrations.
The seed is intentionally empty; security fixtures are transaction-scoped and
roll back after the database specification.

Create every schema change as a migration before editing it:

```sh
supabase migration new descriptive_change_name
```

After the local database has been rebuilt, regenerate Swift database types with:

```sh
./Scripts/generate-supabase-types.sh
```

The generated file is written to
`CouplesTodo/Data/Remote/Generated/DatabaseTypes.swift`. Regenerate the Xcode
project after first creating that file so it joins the application target.

## Security specification

The A/B/C isolation specification is in
`tests/database/rls_isolation.test.sql`. A and B share one couple; C belongs to a
different couple. It covers couple and task visibility, cross-couple updates and
inserts, partner profile visibility, and device-token ownership.

Run it explicitly when database test execution is desired:

```sh
supabase test db supabase/tests/database/rls_isolation.test.sql --local
```

## Remote project

Do not reuse the legacy personal backend. Create and link a fresh hosted
Supabase project, confirm its Postgres major version matches `config.toml`, then
review the pending migrations before pushing them. Keep the service-role key and
APNs credentials in server-side secrets only.
