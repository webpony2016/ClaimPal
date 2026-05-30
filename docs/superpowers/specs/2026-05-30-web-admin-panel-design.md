# ClaimPal Web Admin Panel Design

Date: 2026-05-30
Status: Approved for implementation planning

## Purpose

Build a secure, single-page operations dashboard for reviewing scraped class action settlement data before publishing it into ClaimPal's production settlement catalog. The admin must be able to compare raw scraped source content with AI-sanitized structured fields, correct mistakes, approve valid rows, reject spam, and trigger the client sync version update.

This admin panel is a separate Python web project, not part of the existing Flutter Web client.

## Scope

In scope:

- A standalone `admin_panel/` FastAPI service.
- HTML/Tailwind single-page review UI.
- Bearer-token protected admin API.
- A Postgres `pending_settlements` table for unverified scraper submissions.
- Approve, reject, list, read, and save-draft operations for pending rows.
- Transactional publishing into the existing `settlements` table.
- Global data version synchronization after publish.
- Focused automated tests for auth, persistence, approval, rejection, and rollback behavior.

Out of scope:

- Multi-admin accounts, roles, or SSO.
- Full crawler implementation.
- Mobile client sync changes.
- Rich screenshot storage pipeline. The first version supports raw text, markdown, HTML snippets, and source URLs.

## Recommended Architecture

Use `FastAPI + Jinja2 + Tailwind + vanilla JavaScript + psycopg`. FastAPI provides request validation, API route structure, and straightforward automated tests. The frontend remains intentionally small: one rendered HTML page plus a static JavaScript module that calls the admin API.

Proposed directory layout:

```text
admin_panel/
  app/
    __init__.py
    main.py
    settings.py
    db.py
    schemas.py
    routes/
      __init__.py
      admin.py
    services/
      __init__.py
      settlements.py
  templates/
    review.html
  static/
    admin.js
  tests/
    test_admin_auth.py
    test_pending_pool.py
    test_approve_reject.py
  requirements.txt
```

The service connects directly to Supabase Postgres using a backend-only database URL. No database credentials are exposed to the browser.

## Data Model

Add a new `pending_settlements` table:

```sql
create table public.pending_settlements (
  id uuid primary key default gen_random_uuid(),
  source_url text,
  raw_content text not null,
  raw_content_type text not null default 'text',
  brand_name text not null,
  max_payout numeric(14,2),
  country text not null check (country in ('US', 'CA')),
  proof_required boolean not null default false,
  deadline date,
  eligibility_text text,
  ai_payload jsonb not null default '{}'::jsonb,
  scraper_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);
```

The existing `settlements` table should be extended with `country text check (country in ('US', 'CA'))` so the admin-reviewed country field is not discarded on publish. Other requested fields map to the existing live table as follows:

| Admin field | Live `settlements` field |
| --- | --- |
| Brand / Company Name | `brand_name` |
| Maximum Estimated Payout | `max_payout` |
| Country | `country` |
| Proof Required | `proof_required` |
| Final Deadline | `deadline` |
| Eligibility Criteria Summary | `eligibility_text` |

## API Design

All `/api/admin/*` endpoints require:

```http
Authorization: Bearer <ADMIN_BEARER_TOKEN>
```

Endpoints:

- `POST /api/admin/scraped-pool`
  - Used by the scraper.
  - Validates incoming raw source data and AI-parsed fields.
  - Inserts a row into `pending_settlements`.
  - Returns the inserted `id` and current pending count.

- `GET /api/admin/pending`
  - Returns the pending count and the next pending row, ordered by `created_at asc`.
  - Used on initial page load and after approve/reject.

- `GET /api/admin/pending/{id}`
  - Returns one pending row for direct review or refresh.

- `PATCH /api/admin/pending/{id}`
  - Saves reviewer edits back to `pending_settlements`.
  - Does not publish or change `data_version`.

- `POST /api/admin/approve/{id}`
  - Accepts final reviewer fields from the form.
  - Publishes the row to `settlements`.
  - Updates global version state.
  - Deletes the pending row.
  - Returns the next pending row and updated count.

- `POST /api/admin/reject/{id}`
  - Deletes the pending row.
  - Does not write to `settlements`.
  - Does not update `global_meta.data_version`.
  - Returns the next pending row and updated count.

## Publish Transaction

Approval must run in a single database transaction:

1. Lock the pending row with `select ... for update`.
2. Insert the reviewer-approved values into `public.settlements`.
3. Let the existing `settlements.version_id` sequence assign the live row version.
4. Synchronize `public.global_meta.data_version` to the inserted row's `version_id`.
5. Delete the pending row.
6. Commit.

The PRD wording says approval increments `data_version` by one. The current schema already defines `settlements.version_id` as the authoritative monotonically increasing cursor, with a trigger that keeps `global_meta.data_version == max(settlements.version_id)`. The admin implementation should preserve that invariant instead of independently incrementing `global_meta`; otherwise client delta sync could drift from live settlement row versions.

If any step fails, the transaction rolls back and the pending row remains reviewable.

## Frontend Design

The admin UI is one dense review screen:

- Header:
  - ClaimPal Operations Review title.
  - Counter badge: `Pending Review List: X items left`.
  - Optional lightweight status area for save/publish errors.

- Left column: Raw Source Data.
  - Scrollable text/markdown/HTML display.
  - Shows source URL when present.
  - Preserves whitespace for copied scraper snippets.

- Right column: AI Sanitized Form.
  - `Brand/Company Name`: text input.
  - `Maximum Estimated Payout`: numeric input with decimal support.
  - `Country`: dropdown with United States and Canada.
  - `Proof Required`: checkbox or switch.
  - `Final Deadline`: date input in `YYYY-MM-DD`.
  - `Eligibility Criteria Summary`: textarea.

- Sticky action bar below the right form:
  - Green `Approve & Publish` button.
  - Red `Reject / Spam` button.

Interaction flow:

1. Page loads and asks the admin for the bearer token if one is not already in `sessionStorage`.
2. Frontend calls `GET /api/admin/pending`.
3. Admin reviews the raw source and structured fields.
4. Admin edits fields as needed.
5. `Approve & Publish` posts the final form values to the approve endpoint.
6. `Reject / Spam` posts to the reject endpoint.
7. On success, the UI shows a short toast and loads the next pending row.
8. If no rows remain, the UI shows an empty state.

## Validation And Error Handling

Backend validation:

- Reject missing `raw_content`.
- Reject missing `brand_name`.
- Reject unsupported country values.
- Reject malformed payout values.
- Reject malformed date values.
- Use parameterized SQL for all database writes and reads.

Frontend handling:

- `401` or `403`: show an authorization error and ask for a token again.
- `404`: show that the pending item was already processed and load the next item.
- `422`: display validation errors near the corresponding form fields.
- `500`: keep the current form state and show a retryable error.

## Security

Security model for the first version:

- `ADMIN_BEARER_TOKEN` is required for all API routes under `/api/admin/*`.
- `DATABASE_URL` is only available to the backend process.
- Frontend stores the token in `sessionStorage`, not local storage.
- No service-role key or database URL is ever rendered into the page.
- CORS should be disabled or limited to the admin host.
- API responses should avoid returning secrets or stack traces.

This is enough for an internal operations tool. SSO or role-based admin accounts can be added later without changing the core review workflow.

## Testing

Automated tests should cover:

- Missing bearer token returns `401`.
- Invalid bearer token returns `401`.
- Valid scraper payload creates a pending row.
- `GET /api/admin/pending` returns count and oldest pending item.
- `PATCH /api/admin/pending/{id}` persists reviewer edits without publishing.
- `POST /api/admin/approve/{id}` inserts one live settlement, removes the pending row, and updates `global_meta.data_version` consistently with the inserted `version_id`.
- `POST /api/admin/reject/{id}` removes the pending row, leaves `settlements` unchanged, and leaves `global_meta.data_version` unchanged.
- Approval rollback keeps the pending row if the live insert or version update fails.

Manual verification should include opening the admin page, reviewing a seeded pending item, approving it, confirming the next item loads, and checking the pending counter updates.

## Implementation Notes

- Keep route handlers thin. Move database transaction logic into `app/services/settlements.py`.
- Use Pydantic models for scraper input and reviewer form input.
- Prefer one database connection helper in `app/db.py`.
- Keep frontend JavaScript small and stateful only around the current pending item, pending count, and bearer token.
- Avoid adding a frontend framework unless the dashboard grows beyond the current single-page review workflow.
