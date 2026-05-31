# ClaimPal Scraper Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Implementation status (2026-05-30):** Completed in this workspace. The `scraper/` subproject, tests, fixtures, CLI, state store, structurer, publish client, first source adapter, and end-to-end pipeline have all been implemented. Remaining warnings in test output are currently non-blocking third-party/runtime warnings rather than functional failures.

**Goal:** Build a standalone Python scraper service that discovers settlement candidates from external sources, extracts raw source content, structures candidate fields with rules plus optional LLM assistance, deduplicates repeated content, and publishes review-ready payloads into ClaimPal's existing `admin_panel` pending queue.

**Architecture:** Add a separate `scraper/` Python subproject with focused modules for settings, source adapters, content extraction, normalization, deduplication, admin API publishing, and a thin CLI entrypoint. The scraper must never write directly to `public.pending_settlements` or `public.settlements`; all writes flow through `POST /api/admin/scraped-pool`.

**Tech Stack:** Python 3.11+, `httpx`, `feedparser`, `beautifulsoup4` or `selectolax`, Pydantic v2, pytest, tenacity, optional LLM SDK, SQLite for first-pass state storage, JSON-structured logging.

**Git policy for this session:** Do not run `git add`, `git commit`, branch operations, or push commands. Another Agent may be working on unrelated parts of the repository.

---

## File Structure

Create:

- `scraper/README.md`: Setup, run modes, environment variables, and source-specific notes.
- `scraper/requirements.txt`: Python dependencies for the scraper and tests.
- `scraper/.env`: Local placeholder configuration for admin API access, LLM access, and state storage.
- `scraper/app/__init__.py`: Package marker.
- `scraper/app/main.py`: CLI entrypoint for running one source, all sources, or dry-run execution.
- `scraper/app/settings.py`: Environment-backed settings and defaults.
- `scraper/app/models/__init__.py`: Package marker for shared models.
- `scraper/app/models/raw_item.py`: Source adapter output models.
- `scraper/app/models/normalized_item.py`: Extraction/normalization models.
- `scraper/app/models/pending_payload.py`: Final payload sent to the admin API.
- `scraper/app/sources/__init__.py`: Package marker for source adapters.
- `scraper/app/sources/base.py`: Source adapter interface and common utilities.
- `scraper/app/sources/courtlistener.py`: First reference source adapter, ideally RSS/API based.
- `scraper/app/sources/top_class_actions.py`: HTML source adapter stub.
- `scraper/app/extractors/__init__.py`: Package marker for extraction logic.
- `scraper/app/extractors/html_to_text.py`: HTML to markdown/text conversion helpers.
- `scraper/app/extractors/settlement_facts.py`: Rule-based extraction helpers for dates, amounts, country hints, and proof-required hints.
- `scraper/app/clients/__init__.py`: Package marker for HTTP and model clients.
- `scraper/app/clients/admin_api.py`: Client for `POST /api/admin/scraped-pool`.
- `scraper/app/clients/llm_client.py`: Optional model client interface and parsing helper.
- `scraper/app/services/__init__.py`: Package marker for orchestration services.
- `scraper/app/services/state_store.py`: SQLite-backed status and dedupe state storage.
- `scraper/app/services/dedupe.py`: URL/content-hash/business-similarity dedupe logic.
- `scraper/app/services/structurer.py`: Rule-plus-LLM payload construction.
- `scraper/app/services/publisher.py`: Publishing orchestration with retries and result recording.
- `scraper/app/pipelines/__init__.py`: Package marker for pipelines.
- `scraper/app/pipelines/ingest.py`: End-to-end ingestion pipeline over a source adapter.
- `scraper/app/utils/__init__.py`: Package marker for utility helpers.
- `scraper/app/utils/hashing.py`: Content normalization and hashing helpers.
- `scraper/app/utils/dates.py`: Date parsing and normalization helpers.
- `scraper/app/utils/money.py`: Money parsing and formatting helpers.
- `scraper/app/utils/logging.py`: Structured logging setup.
- `scraper/tests/conftest.py`: Shared fixtures.
- `scraper/tests/test_settings.py`: Environment/settings tests.
- `scraper/tests/test_state_store.py`: State store and dedupe state tests.
- `scraper/tests/test_admin_api.py`: Admin API client tests.
- `scraper/tests/test_structurer.py`: Rule-based and optional LLM-assisted structuring tests.
- `scraper/tests/test_pipeline.py`: End-to-end ingestion pipeline tests with fake source adapters.
- `scraper/tests/fixtures/`: Regression fixtures for feed entries and HTML snapshots.

Modify:

- `README.md`: Add the scraper implementation plan to the related design documents list.
- `docs/superpowers/specs/2026-05-30-scraper-service-design.md`: Optional future update if implementation decisions diverge from the current spec.

---

### Task 1: Scraper Project Skeleton, Settings, And Failing Tests

**Files:**

- Create: `scraper/requirements.txt`
- Create: `scraper/.env`
- Create: `scraper/README.md`
- Create: `scraper/app/__init__.py`
- Create: `scraper/app/main.py`
- Create: `scraper/app/settings.py`
- Create: `scraper/tests/conftest.py`
- Create: `scraper/tests/test_settings.py`

- [ ] **Step 1: Add Python dependencies**

Create `scraper/requirements.txt`:

```text
httpx==0.28.1
feedparser==6.0.11
beautifulsoup4==4.12.3
pydantic==2.11.5
pydantic-settings==2.9.1
pytest==8.3.5
tenacity==9.1.2
python-dateutil==2.9.0.post0
```

If a concrete LLM SDK is selected later, add it in a separate change after the provider decision is locked.

- [ ] **Step 2: Add placeholder environment variables**

Create `scraper/.env`:

```env
ADMIN_API_BASE_URL=http://127.0.0.1:8008
ADMIN_BEARER_TOKEN=replace-with-admin-token
LLM_API_KEY=replace-with-llm-key
SCRAPER_STATE_DB_URL=sqlite:///scraper_state.db
REQUEST_TIMEOUT_SECONDS=20
MAX_RETRIES=3
USER_AGENT=ClaimPalScraper/0.1
```

- [ ] **Step 3: Add failing settings tests first**

Create `scraper/tests/test_settings.py` with tests that assert:

- `ADMIN_API_BASE_URL` is required.
- `ADMIN_BEARER_TOKEN` is required.
- `SCRAPER_STATE_DB_URL` defaults correctly when omitted, if a default is allowed.
- `REQUEST_TIMEOUT_SECONDS` and `MAX_RETRIES` are parsed as integers.

- [ ] **Step 4: Add app package skeleton and settings model**

Create:

- `scraper/app/__init__.py`
- `scraper/app/settings.py`
- `scraper/app/main.py`

Implement `Settings` with `pydantic-settings` and a small CLI stub that can print selected settings in dry-run/debug mode.

- [ ] **Step 5: Run settings tests and make them pass**

Run in `scraper/`:

```bash
python -m pytest tests/test_settings.py -q
```

Expected: settings tests pass and the package imports cleanly.

- [ ] **Step 6: Check worktree without staging**

Run:

```bash
git status --short
```

Expected: `scraper/` files appear as unstaged changes. Do not stage or commit.

---

### Task 2: Shared Data Models And Validation

**Files:**

- Create: `scraper/app/models/__init__.py`
- Create: `scraper/app/models/raw_item.py`
- Create: `scraper/app/models/normalized_item.py`
- Create: `scraper/app/models/pending_payload.py`
- Create: `scraper/tests/test_structurer.py`

- [ ] **Step 1: Add `RawItem` model**

Define a model for source adapter output with fields such as:

- `source`
- `source_url`
- `title`
- `published_at`
- `list_url`
- `raw_html`
- `raw_text`
- `metadata`

- [ ] **Step 2: Add `NormalizedItem` model**

Define a model for extracted and normalized source content with fields such as:

- `source`
- `source_url`
- `title`
- `raw_content`
- `raw_content_type`
- `published_at`
- `scraped_at`
- `country_hint`
- `fingerprint`
- `metadata`

- [ ] **Step 3: Add `PendingPayload` model**

Mirror the backend `PendingSettlementCreate` contract. Validate:

- `raw_content` is non-empty.
- `brand_name` is non-empty.
- `country` is `US` or `CA`.
- `raw_content_type` is `text`, `html`, or `markdown`.
- `max_payout` is non-negative when provided.

- [ ] **Step 4: Add model validation tests**

Add tests that intentionally fail on:

- empty `raw_content`
- invalid `country`
- negative `max_payout`
- unsupported `raw_content_type`

- [ ] **Step 5: Run tests for model validation**

Run:

```bash
python -m pytest tests/test_structurer.py -q
```

Expected: validation behavior matches the admin API contract.

---

### Task 3: State Store And First-Pass Deduplication

**Files:**

- Create: `scraper/app/services/state_store.py`
- Create: `scraper/app/services/dedupe.py`
- Create: `scraper/app/utils/hashing.py`
- Create: `scraper/tests/test_state_store.py`

- [ ] **Step 1: Create a lightweight state schema**

Use SQLite for the first pass. Store at least:

- `source_url`
- `content_hash`
- `status`
- `first_seen_at`
- `last_seen_at`
- `admin_pending_id`
- `error_message`

Add a helper that initializes the table on first run.

- [ ] **Step 2: Implement URL and content-hash lookup helpers**

Add service methods to:

- check whether a URL has already been seen
- check whether a content hash already exists
- upsert a record after success, skip, or failure

- [ ] **Step 3: Implement content normalization and hashing**

Normalize title + source + body text into a consistent fingerprint before hashing so trivial whitespace or tracking-parameter changes do not cause duplicate records.

- [ ] **Step 4: Add dedupe decision helper**

Implement a first-pass decision API that returns one of:

- `new`
- `duplicate_url`
- `duplicate_content`
- `retryable_failed_item`

- [ ] **Step 5: Add state store and dedupe tests**

Test cases should cover:

- repeated identical URL
- changed tracking parameters with same normalized content
- first-time item insertion
- retryable failures not being permanently blocked

- [ ] **Step 6: Run state store tests**

Run:

```bash
python -m pytest tests/test_state_store.py -q
```

Expected: dedupe decisions are deterministic and recoverable.

---

### Task 4: Admin API Client And Publish Contract

**Files:**

- Create: `scraper/app/clients/__init__.py`
- Create: `scraper/app/clients/admin_api.py`
- Create: `scraper/tests/test_admin_api.py`

- [ ] **Step 1: Add a thin HTTP client for admin publishing**

Implement a client with:

- base URL from settings
- bearer token auth header
- configurable timeout
- `publish_pending(payload: PendingPayload)` method

- [ ] **Step 2: Handle response categories explicitly**

Map responses as follows:

- `201`: success, return parsed response body
- `401`: configuration/auth failure, surface a non-retryable exception
- `422`: payload validation failure, surface a non-retryable exception with body context
- `5xx`: retryable publish failure

- [ ] **Step 3: Add client tests**

Test with mocked responses for:

- successful publish
- unauthorized token
- validation failure
- server error

- [ ] **Step 4: Add retry wrapper policy at the publisher layer, not the raw client**

Keep the raw client thin. Retries belong in orchestration, so response semantics stay clear and testable.

- [ ] **Step 5: Run admin API tests**

Run:

```bash
python -m pytest tests/test_admin_api.py -q
```

Expected: publish error behavior is explicit and stable.

---

### Task 5: Extraction Utilities And Rule-Based Fact Parsing

**Files:**

- Create: `scraper/app/extractors/__init__.py`
- Create: `scraper/app/extractors/html_to_text.py`
- Create: `scraper/app/extractors/settlement_facts.py`
- Create: `scraper/app/utils/dates.py`
- Create: `scraper/app/utils/money.py`
- Update: `scraper/tests/test_structurer.py`
- Create: `scraper/tests/fixtures/`

- [ ] **Step 1: Add HTML-to-text/markdown conversion helper**

Implement a small extractor that:

- removes script/style noise
- preserves headings and paragraphs where possible
- returns markdown when structure can be preserved
- falls back to plain text otherwise

- [ ] **Step 2: Add date parsing helper**

Support common settlement deadline patterns such as:

- `August 14, 2026`
- `2026-08-14`
- `Claim deadline: 08/14/2026`

Return normalized ISO date strings or Python `date` objects.

- [ ] **Step 3: Add money parsing helper**

Recognize patterns such as:

- `$35`
- `$35.00`
- `up to $350`
- `maximum payout of 25 CAD`

Prefer normalized decimal output and avoid guessing when multiple conflicting values appear.

- [ ] **Step 4: Add proof-required and country heuristics**

Infer:

- `proof_required` from terms such as `receipt required`, `proof of purchase required`, or explicit no-proof-needed phrases
- `country` from source context and text hints, limited to `US` and `CA`

- [ ] **Step 5: Add fixture-based extraction tests**

Use saved HTML/feed fragments to test:

- extraction stability
- date parsing
- amount parsing
- country hints
- proof-required hints

- [ ] **Step 6: Run extraction tests**

Run:

```bash
python -m pytest tests/test_structurer.py -q
```

Expected: rule helpers are stable before any LLM integration is added.

---

### Task 6: Structurer Service With Optional LLM Enrichment

**Files:**

- Create: `scraper/app/clients/llm_client.py`
- Create: `scraper/app/services/structurer.py`
- Update: `scraper/tests/test_structurer.py`

- [ ] **Step 1: Implement rule-only payload generation first**

From `NormalizedItem`, produce a `PendingPayload` using:

- title and source hints for `brand_name`
- rule-based amount extraction for `max_payout`
- country heuristics for `country`
- rule-based date extraction for `deadline`
- excerpt summarization for `eligibility_text`

- [ ] **Step 2: Preserve model-independent audit context**

Always populate:

- `scraper_payload.source`
- `scraper_payload.content_hash`
- `scraper_payload.fetched_at`
- `scraper_payload.title`
- `scraper_payload.published_at`

Even when LLM integration is disabled.

- [ ] **Step 3: Add optional LLM client abstraction**

Provide an interface for model-assisted extraction without binding the whole pipeline to a specific vendor yet. If no `LLM_API_KEY` is configured, the pipeline must continue in rule-only mode.

- [ ] **Step 4: Merge LLM output conservatively**

LLM-assisted fields must be validated and should only override rule outputs when:

- the result passes schema validation
- confidence is acceptable
- the value is not clearly contradictory to deterministic extraction

- [ ] **Step 5: Record `ai_payload` consistently**

Include fields such as:

- `model`
- `confidence`
- `prompt_version`
- `warnings`
- `evidence`

When no LLM is used, `ai_payload` should still exist and clearly state that the payload was generated by rule-based extraction.

- [ ] **Step 6: Add structurer tests**

Cover:

- rule-only mode
- no-LLM configured mode
- valid LLM override mode
- invalid LLM output ignored mode

- [ ] **Step 7: Run structurer tests**

Run:

```bash
python -m pytest tests/test_structurer.py -q
```

Expected: rule-first behavior remains deterministic, with LLM assistance as a bounded enhancement rather than a hard dependency.

---

### Task 7: Source Adapter Base Class And First Real Source

**Files:**

- Create: `scraper/app/sources/__init__.py`
- Create: `scraper/app/sources/base.py`
- Create: `scraper/app/sources/courtlistener.py`
- Create: `scraper/app/sources/top_class_actions.py`
- Update: `scraper/tests/test_pipeline.py`
- Create: `scraper/tests/fixtures/courtlistener/`

- [ ] **Step 1: Define a source adapter interface**

The base adapter should expose:

- `source_name`
- `fetch_candidates()`
- `fetch_detail(candidate)`
- optional `normalize_candidate()` helper

- [ ] **Step 2: Implement the first production-ready source using RSS/API**

Prefer `CourtListener` as the first real source because RSS/API content is usually more stable than arbitrary HTML pages.

The first adapter should:

- fetch a small recent batch
- normalize feed entries into `RawItem`
- fetch detail content when needed
- retain list/feed URL metadata

- [ ] **Step 3: Add HTML source stub for future expansion**

Add `top_class_actions.py` as a non-production stub or minimal parser so the project layout already supports both structured and HTML-based sources.

- [ ] **Step 4: Add adapter tests with fixture feeds**

Test:

- feed parsing
- empty feed handling
- malformed entry skipping
- detail fetch fallback behavior

- [ ] **Step 5: Run pipeline/source tests**

Run:

```bash
python -m pytest tests/test_pipeline.py -q
```

Expected: one source can reliably emit normalized candidate items.

---

### Task 8: Ingestion Pipeline And Publisher Orchestration

**Files:**

- Create: `scraper/app/services/publisher.py`
- Create: `scraper/app/pipelines/__init__.py`
- Create: `scraper/app/pipelines/ingest.py`
- Update: `scraper/app/main.py`
- Update: `scraper/tests/test_pipeline.py`

- [ ] **Step 1: Implement end-to-end ingestion flow**

For each candidate:

1. fetch detail
2. extract readable content
3. normalize
4. dedupe
5. structure
6. publish to admin API
7. record final state

- [ ] **Step 2: Keep item failures isolated**

A single candidate failure must not abort the whole run. Collect per-item results and summarize them at the end.

- [ ] **Step 3: Add publisher-level retry policy**

Use `tenacity` or equivalent to retry transient network and `5xx` failures, but do not retry:

- `401`
- `422`
- deterministic parsing failures

- [ ] **Step 4: Add result summary**

At the end of a run, report at least:

- total candidates
- skipped duplicates
- publish successes
- publish failures
- parse failures
- elapsed time

- [ ] **Step 5: Add dry-run mode**

Support a CLI flag that:

- runs extraction, dedupe, and structuring
- prints or logs the final payload
- does not call the admin API
- still records enough local status to aid debugging if desired

- [ ] **Step 6: Add pipeline tests**

Test:

- success path
- duplicate skip path
- admin API failure path
- parse failure path
- dry-run path

- [ ] **Step 7: Run pipeline tests**

Run:

```bash
python -m pytest tests/test_pipeline.py -q
```

Expected: the pipeline handles mixed-success batches without falling over dramatically at the first pothole.

---

### Task 9: CLI, Logging, And Operational Documentation

**Files:**

- Update: `scraper/app/main.py`
- Create: `scraper/app/utils/logging.py`
- Update: `scraper/README.md`

- [ ] **Step 1: Add a small CLI interface**

Support commands or flags such as:

- run one source
- run all sources
- dry-run
- max-items override
- verbose logging

- [ ] **Step 2: Add structured logging**

Emit JSON or clearly structured logs for events such as:

- `candidate_discovered`
- `detail_fetched`
- `duplicate_skipped`
- `payload_built`
- `publish_success`
- `publish_failed`

- [ ] **Step 3: Document local setup and usage**

In `scraper/README.md`, document:

- dependency installation
- `.env` variables
- dry-run usage
- source selection
- how to point at local `admin_panel`
- how to inspect the local SQLite state file

- [ ] **Step 4: Add smoke-test instructions**

Document a local validation flow:

1. start `admin_panel`
2. run scraper in dry-run mode
3. run scraper in publish mode
4. open admin UI
5. verify a pending item appears

- [ ] **Step 5: Perform one local smoke test**

Run the scraper against a fake or fixture-backed source first, then against the real first source if external access is acceptable.

Expected: at least one payload reaches `/api/admin/scraped-pool` and becomes visible in the admin review queue.

---

### Task 10: Regression Fixtures, Stability, And Follow-Up Backlog

**Files:**

- Update: `scraper/tests/fixtures/`
- Update: `scraper/README.md`
- Optional future update: `docs/superpowers/specs/2026-05-30-scraper-service-design.md`

- [ ] **Step 1: Save source-specific regression fixtures**

Preserve representative samples for each source:

- feed entry JSON/XML
- detail HTML snapshot
- expected extracted text
- expected structured fields

- [ ] **Step 2: Add a backlog section for future work**

Track follow-ups such as:

- multi-source scheduling
- stronger business-similarity dedupe
- raw HTML snapshot archiving
- per-source rate limits
- alerting and dashboards
- richer eligibility summarization

- [ ] **Step 3: Reconcile implementation with spec**

If the implementation makes concrete tradeoffs—such as selecting `beautifulsoup4` over `selectolax`, or CourtListener-only support for the first milestone—update the scraper spec to reflect those choices.

- [ ] **Step 4: Run the full scraper test suite**

Run:

```bash
python -m pytest -q
```

Expected: tests for settings, models, state, client, structurer, and pipeline all pass.

---

## Recommended Implementation Order

To minimize risk and keep progress observable, implement in this order:

1. project skeleton and settings
2. shared models
3. state store and dedupe
4. admin API client
5. extraction utilities
6. structurer
7. first stable source adapter
8. end-to-end pipeline
9. CLI and logging
10. regression fixtures and smoke testing

This order intentionally delays LLM complexity until the deterministic plumbing is already working.

## Acceptance Criteria

The scraper implementation is considered successful for v1 when all of the following are true:

- A standalone `scraper/` project exists and can be run locally.
- One stable source adapter produces candidate items end-to-end.
- The pipeline extracts readable `raw_content` and builds valid admin payloads.
- Duplicate URLs and duplicate content hashes are skipped.
- Successful publishes reach `POST /api/admin/scraped-pool`.
- Failed publishes are classified and logged correctly.
- The admin UI can display at least one scraper-produced pending item.
- The full scraper test suite passes.

## Risks And Watchpoints

- HTML source layouts may change without notice and break parsers.
- Multiple money/date values in a single page may cause ambiguous extraction.
- Over-eager LLM overrides may reduce determinism if not tightly validated.
- Missing or weak dedupe can spam the human review queue.
- Overly aggressive retries may annoy upstream sites or duplicate submissions.

## Notes For Future Expansion

After the first milestone is stable, likely next upgrades are:

- additional RSS/API sources
- production-ready HTML adapters
- richer semantic dedupe
- scheduled runs
- alerting and job dashboards
- optional snapshot storage for legal or audit review

## Summary

This plan turns the scraper design into a staged implementation roadmap: start with a deterministic Python project skeleton, model the admin payload contract, add stateful dedupe, integrate a stable first source, and only then layer in optional LLM enrichment and broader source coverage. The end result should be a boringly reliable ingestion pipeline—which, in infrastructure terms, is basically a compliment.