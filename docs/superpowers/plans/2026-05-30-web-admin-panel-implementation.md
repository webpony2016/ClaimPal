# ClaimPal Web Admin Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone FastAPI + Tailwind Web Admin dashboard for reviewing scraped settlement data, approving valid items into `settlements`, rejecting spam, and preserving the ClaimPal data-version sync invariant.

**Architecture:** Add a separate `admin_panel/` Python service with focused modules for settings, authentication, database access, schemas, routes, and settlement publishing. Add a Supabase migration for `pending_settlements` and `settlements.country`. The UI is a single Jinja2-rendered page with vanilla JavaScript calling bearer-token protected JSON APIs.

**Tech Stack:** Python 3.11+, FastAPI, Jinja2, psycopg 3, Pydantic Settings, pytest, Supabase Postgres, Tailwind CDN for the first internal-admin version.

**Git policy for this session:** Do not run `git add`, `git commit`, branch operations, or push commands. Another Agent is working on mobile code in this repository.

---

## File Structure

Create:

- `admin_panel/requirements.txt`: Python dependencies for the admin service and tests.
- `admin_panel/app/__init__.py`: Package marker.
- `admin_panel/app/main.py`: FastAPI app factory, template route, static mounting, router registration.
- `admin_panel/app/settings.py`: Environment-backed configuration.
- `admin_panel/app/auth.py`: Bearer token dependency for admin APIs.
- `admin_panel/app/db.py`: psycopg connection helper.
- `admin_panel/app/schemas.py`: Pydantic request/response models.
- `admin_panel/app/routes/__init__.py`: Route package marker.
- `admin_panel/app/routes/admin.py`: Admin API route handlers.
- `admin_panel/app/services/__init__.py`: Service package marker.
- `admin_panel/app/services/settlements.py`: Database operations and approval transaction.
- `admin_panel/templates/review.html`: Single-page admin UI.
- `admin_panel/static/admin.js`: Browser-side token handling, loading, form binding, approve/reject actions.
- `admin_panel/tests/conftest.py`: Test app setup and dependency overrides.
- `admin_panel/tests/test_admin_auth.py`: Bearer auth tests.
- `admin_panel/tests/test_pending_pool.py`: Scraper pool/list/update tests.
- `admin_panel/tests/test_approve_reject.py`: Approval/rejection service tests.
- `supabase/migrations/20260530190000_admin_pending_settlements.sql`: Forward migration for pending pool and live country field.
- `supabase/rollback/20260530190000_admin_pending_settlements_down.sql`: Manual rollback script.

Modify:

- `supabase/README.md`: Add a short section documenting pending review rows and admin publishing.

---

### Task 1: Admin Service Skeleton And Auth

**Files:**

- Create: `admin_panel/requirements.txt`
- Create: `admin_panel/app/__init__.py`
- Create: `admin_panel/app/main.py`
- Create: `admin_panel/app/settings.py`
- Create: `admin_panel/app/auth.py`
- Create: `admin_panel/app/routes/__init__.py`
- Create: `admin_panel/app/routes/admin.py`
- Create: `admin_panel/templates/review.html`
- Create: `admin_panel/static/admin.js`
- Create: `admin_panel/tests/conftest.py`
- Create: `admin_panel/tests/test_admin_auth.py`

- [ ] **Step 1: Add Python dependencies**

Create `admin_panel/requirements.txt`:

```text
fastapi==0.115.6
uvicorn[standard]==0.32.1
jinja2==3.1.4
pydantic-settings==2.6.1
psycopg[binary]==3.2.3
pytest==8.3.4
httpx==0.28.1
```

- [ ] **Step 2: Add failing auth tests**

Create `admin_panel/tests/test_admin_auth.py`:

```python
from fastapi.testclient import TestClient


def test_admin_api_requires_bearer_token(client: TestClient) -> None:
    response = client.get("/api/admin/pending")

    assert response.status_code == 401
    assert response.json() == {"detail": "Missing admin bearer token"}


def test_admin_api_rejects_invalid_bearer_token(client: TestClient) -> None:
    response = client.get(
        "/api/admin/pending",
        headers={"Authorization": "Bearer wrong-token"},
    )

    assert response.status_code == 401
    assert response.json() == {"detail": "Invalid admin bearer token"}
```

Create `admin_panel/tests/conftest.py`:

```python
from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.settings import Settings, get_settings


@pytest.fixture()
def client() -> Generator[TestClient, None, None]:
    app = create_app()

    def test_settings() -> Settings:
        return Settings(
            admin_bearer_token="test-admin-token",
            database_url="postgresql://postgres:postgres@localhost:54322/postgres",
        )

    app.dependency_overrides[get_settings] = test_settings

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()
```

- [ ] **Step 3: Run auth tests and verify they fail because the app does not exist**

Run:

```bash
cd admin_panel
python -m pytest tests/test_admin_auth.py -q
```

Expected:

```text
ModuleNotFoundError: No module named 'app'
```

- [ ] **Step 4: Implement settings, auth dependency, app factory, and an empty queue route**

Create `admin_panel/app/__init__.py`:

```python
"""ClaimPal admin panel package."""
```

Create `admin_panel/app/settings.py`:

```python
from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    admin_bearer_token: str = Field(alias="ADMIN_BEARER_TOKEN")
    database_url: str = Field(alias="DATABASE_URL")

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    return Settings()
```

Create `admin_panel/app/auth.py`:

```python
from typing import Annotated

from fastapi import Depends, Header, HTTPException, status

from app.settings import Settings, get_settings


def require_admin_token(
    authorization: Annotated[str | None, Header()] = None,
    settings: Settings = Depends(get_settings),
) -> None:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing admin bearer token",
        )

    token = authorization.removeprefix("Bearer ").strip()
    if token != settings.admin_bearer_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid admin bearer token",
        )
```

Create `admin_panel/app/routes/__init__.py`:

```python
"""Route modules for the ClaimPal admin panel."""
```

Create `admin_panel/app/routes/admin.py`:

```python
from fastapi import APIRouter, Depends

from app.auth import require_admin_token

router = APIRouter(
    prefix="/api/admin",
    dependencies=[Depends(require_admin_token)],
)


@router.get("/pending")
def get_pending_empty_queue() -> dict[str, object]:
    return {"count": 0, "item": None}
```

Create `admin_panel/app/main.py`:

```python
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from app.routes.admin import router as admin_router

templates = Jinja2Templates(directory="templates")


def create_app() -> FastAPI:
    app = FastAPI(title="ClaimPal Admin Panel")
    app.mount("/static", StaticFiles(directory="static"), name="static")
    app.include_router(admin_router)

    @app.get("/", response_class=HTMLResponse)
    def review_page(request: Request) -> HTMLResponse:
        return templates.TemplateResponse("review.html", {"request": request})

    return app


app = create_app()
```

Create `admin_panel/templates/review.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>ClaimPal Operations Review</title>
    <script src="https://cdn.tailwindcss.com"></script>
  </head>
  <body class="bg-slate-50 text-slate-950">
    <main id="app" class="min-h-screen"></main>
    <script src="/static/admin.js"></script>
  </body>
</html>
```

Create `admin_panel/static/admin.js`:

```javascript
document.getElementById("app").innerHTML = `
  <section class="mx-auto flex min-h-screen max-w-7xl items-center justify-center p-6">
    <div class="rounded border border-slate-200 bg-white p-6 shadow-sm">
      <h1 class="text-xl font-semibold">ClaimPal Operations Review</h1>
      <p class="mt-2 text-sm text-slate-600">Admin API is ready.</p>
    </div>
  </section>
`;
```

- [ ] **Step 5: Run auth tests and verify they pass**

Run:

```bash
cd admin_panel
python -m pytest tests/test_admin_auth.py -q
```

Expected:

```text
2 passed
```

- [ ] **Step 6: Check worktree without staging**

Run:

```bash
git status --short
```

Expected: created files are visible as unstaged changes. Do not stage or commit.

---

### Task 2: Database Migration For Pending Review Pool

**Files:**

- Create: `supabase/migrations/20260530190000_admin_pending_settlements.sql`
- Create: `supabase/rollback/20260530190000_admin_pending_settlements_down.sql`
- Modify: `supabase/README.md`

- [ ] **Step 1: Add forward migration**

Create `supabase/migrations/20260530190000_admin_pending_settlements.sql`:

```sql
-- =====================================================================
-- ClaimPal admin review pool
-- Adds pending scraped settlement review rows and live settlement country.
-- =====================================================================

begin;

create extension if not exists "pgcrypto";

alter table public.settlements
  add column if not exists country text;

alter table public.settlements
  drop constraint if exists settlements_country_check;

alter table public.settlements
  add constraint settlements_country_check
  check (country is null or country in ('US', 'CA'));

create table if not exists public.pending_settlements (
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
  created_at timestamptz not null default now()
);

create index if not exists pending_settlements_created_at_idx
  on public.pending_settlements (created_at);

alter table public.pending_settlements enable row level security;

drop policy if exists "pending_settlements_no_client_access" on public.pending_settlements;
create policy "pending_settlements_no_client_access"
  on public.pending_settlements
  for all
  to authenticated
  using (false)
  with check (false);

commit;
```

- [ ] **Step 2: Add rollback script**

Create `supabase/rollback/20260530190000_admin_pending_settlements_down.sql`:

```sql
begin;

drop table if exists public.pending_settlements;

alter table public.settlements
  drop constraint if exists settlements_country_check;

alter table public.settlements
  drop column if exists country;

commit;
```

- [ ] **Step 3: Document admin review tables**

Add this section to `supabase/README.md` after the "4 张表" section:

```markdown
### Admin review pool

The Web Admin panel uses `pending_settlements` as a temporary review queue for scraper output. Scrapers write raw source content, source URL, AI-parsed fields, and metadata into this table through the admin API. Human approval publishes a row into `settlements` and removes it from `pending_settlements`; rejection only removes the pending row.

The live `settlements.country` column stores `US` or `CA` so the admin-reviewed country selector is preserved for client filtering and regional presentation.
```

- [ ] **Step 4: Validate migration syntax against local Supabase if available**

Run:

```bash
npx supabase migration up
```

Expected:

```text
Finished supabase migration up.
```

If local Supabase is not running, run:

```bash
npx supabase start
npx supabase migration up
```

Expected: Supabase starts, then migration succeeds. Do not stage or commit.

---

### Task 3: Schemas And Pending Pool CRUD

**Files:**

- Create: `admin_panel/app/db.py`
- Create: `admin_panel/app/schemas.py`
- Create: `admin_panel/app/services/__init__.py`
- Create: `admin_panel/app/services/settlements.py`
- Modify: `admin_panel/app/routes/admin.py`
- Create: `admin_panel/tests/test_pending_pool.py`

- [ ] **Step 1: Add failing pending pool tests with a fake service**

Create `admin_panel/tests/test_pending_pool.py`:

```python
from copy import deepcopy
from uuid import UUID

from fastapi.testclient import TestClient

from app.routes.admin import get_settlement_service


class FakeSettlementService:
    def __init__(self) -> None:
        self.items: list[dict[str, object]] = []

    def create_pending(self, payload):
        item = payload.model_dump()
        item["id"] = "11111111-1111-1111-1111-111111111111"
        item["created_at"] = "2026-05-30T18:00:00Z"
        self.items.append(deepcopy(item))
        return item, len(self.items)

    def get_next_pending(self):
        return (self.items[0] if self.items else None), len(self.items)

    def get_pending(self, item_id: UUID):
        for item in self.items:
            if item["id"] == str(item_id):
                return item
        return None

    def update_pending(self, item_id: UUID, payload):
        for item in self.items:
            if item["id"] == str(item_id):
                item.update(payload.model_dump(exclude_unset=True))
                return item
        return None


def override_service(fake: FakeSettlementService):
    def dependency() -> FakeSettlementService:
        return fake

    return dependency


def auth_headers() -> dict[str, str]:
    return {"Authorization": "Bearer test-admin-token"}


def valid_payload() -> dict[str, object]:
    return {
        "source_url": "https://topclassactions.com/example/apple",
        "raw_content": "Apple settlement raw text",
        "raw_content_type": "text",
        "brand_name": "Apple",
        "max_payout": "35.00",
        "country": "US",
        "proof_required": False,
        "deadline": "2026-08-14",
        "eligibility_text": "US retail employees with qualifying bag checks.",
        "ai_payload": {"confidence": 0.92},
        "scraper_payload": {"source": "topclassactions"},
    }


def test_scraped_pool_creates_pending_item(client: TestClient) -> None:
    fake = FakeSettlementService()
    client.app.dependency_overrides[get_settlement_service] = override_service(fake)

    response = client.post(
        "/api/admin/scraped-pool",
        json=valid_payload(),
        headers=auth_headers(),
    )

    assert response.status_code == 201
    assert response.json()["count"] == 1
    assert response.json()["item"]["brand_name"] == "Apple"
    assert response.json()["item"]["source_url"] == "https://topclassactions.com/example/apple"


def test_get_pending_returns_count_and_oldest_item(client: TestClient) -> None:
    fake = FakeSettlementService()
    fake.create_pending_payload = valid_payload()
    client.app.dependency_overrides[get_settlement_service] = override_service(fake)
    client.post("/api/admin/scraped-pool", json=valid_payload(), headers=auth_headers())

    response = client.get("/api/admin/pending", headers=auth_headers())

    assert response.status_code == 200
    assert response.json()["count"] == 1
    assert response.json()["item"]["brand_name"] == "Apple"


def test_patch_pending_updates_reviewer_fields(client: TestClient) -> None:
    fake = FakeSettlementService()
    client.app.dependency_overrides[get_settlement_service] = override_service(fake)
    client.post("/api/admin/scraped-pool", json=valid_payload(), headers=auth_headers())

    response = client.patch(
        "/api/admin/pending/11111111-1111-1111-1111-111111111111",
        json={"brand_name": "Apple Inc.", "max_payout": "40.00"},
        headers=auth_headers(),
    )

    assert response.status_code == 200
    assert response.json()["item"]["brand_name"] == "Apple Inc."
    assert response.json()["item"]["max_payout"] == "40.00"
```

- [ ] **Step 2: Run pending pool tests and verify they fail because schemas/routes are missing**

Run:

```bash
cd admin_panel
python -m pytest tests/test_pending_pool.py -q
```

Expected:

```text
ImportError: cannot import name 'get_settlement_service'
```

- [ ] **Step 3: Add schemas**

Create `admin_panel/app/schemas.py`:

```python
from datetime import date, datetime
from decimal import Decimal
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel, Field, HttpUrl


CountryCode = Literal["US", "CA"]
RawContentType = Literal["text", "html", "markdown"]


class PendingSettlementCreate(BaseModel):
    source_url: HttpUrl | None = None
    raw_content: str = Field(min_length=1)
    raw_content_type: RawContentType = "text"
    brand_name: str = Field(min_length=1)
    max_payout: Decimal | None = None
    country: CountryCode
    proof_required: bool = False
    deadline: date | None = None
    eligibility_text: str | None = None
    ai_payload: dict[str, Any] = Field(default_factory=dict)
    scraper_payload: dict[str, Any] = Field(default_factory=dict)


class PendingSettlementUpdate(BaseModel):
    source_url: HttpUrl | None = None
    raw_content: str | None = Field(default=None, min_length=1)
    raw_content_type: RawContentType | None = None
    brand_name: str | None = Field(default=None, min_length=1)
    max_payout: Decimal | None = None
    country: CountryCode | None = None
    proof_required: bool | None = None
    deadline: date | None = None
    eligibility_text: str | None = None
    ai_payload: dict[str, Any] | None = None
    scraper_payload: dict[str, Any] | None = None


class PendingSettlementRead(BaseModel):
    id: UUID | str
    source_url: str | None
    raw_content: str
    raw_content_type: str
    brand_name: str
    max_payout: Decimal | str | None
    country: str
    proof_required: bool
    deadline: date | str | None
    eligibility_text: str | None
    ai_payload: dict[str, Any]
    scraper_payload: dict[str, Any]
    created_at: datetime | str


class PendingItemResponse(BaseModel):
    item: PendingSettlementRead | None
    count: int
```

- [ ] **Step 4: Add database helper and service methods**

Create `admin_panel/app/db.py`:

```python
from collections.abc import Iterator

import psycopg
from psycopg.rows import dict_row

from app.settings import Settings


def open_connection(settings: Settings) -> Iterator[psycopg.Connection]:
    with psycopg.connect(settings.database_url, row_factory=dict_row) as connection:
        yield connection
```

Create `admin_panel/app/services/__init__.py`:

```python
"""Service layer for ClaimPal admin operations."""
```

Create `admin_panel/app/services/settlements.py`:

```python
from typing import Any
from uuid import UUID

from psycopg import Connection

from app.schemas import PendingSettlementCreate, PendingSettlementUpdate


PENDING_COLUMNS = """
  id,
  source_url,
  raw_content,
  raw_content_type,
  brand_name,
  max_payout,
  country,
  proof_required,
  deadline,
  eligibility_text,
  ai_payload,
  scraper_payload,
  created_at
"""


class SettlementService:
    def __init__(self, connection: Connection) -> None:
        self.connection = connection

    def create_pending(self, payload: PendingSettlementCreate) -> tuple[dict[str, Any], int]:
        with self.connection.cursor() as cursor:
            cursor.execute(
                f"""
                insert into public.pending_settlements (
                  source_url,
                  raw_content,
                  raw_content_type,
                  brand_name,
                  max_payout,
                  country,
                  proof_required,
                  deadline,
                  eligibility_text,
                  ai_payload,
                  scraper_payload
                )
                values (
                  %(source_url)s,
                  %(raw_content)s,
                  %(raw_content_type)s,
                  %(brand_name)s,
                  %(max_payout)s,
                  %(country)s,
                  %(proof_required)s,
                  %(deadline)s,
                  %(eligibility_text)s,
                  %(ai_payload)s,
                  %(scraper_payload)s
                )
                returning {PENDING_COLUMNS}
                """,
                payload.model_dump(mode="json"),
            )
            item = cursor.fetchone()
            cursor.execute("select count(*) as count from public.pending_settlements")
            count = int(cursor.fetchone()["count"])
        self.connection.commit()
        return item, count

    def get_next_pending(self) -> tuple[dict[str, Any] | None, int]:
        with self.connection.cursor() as cursor:
            cursor.execute("select count(*) as count from public.pending_settlements")
            count = int(cursor.fetchone()["count"])
            cursor.execute(
                f"""
                select {PENDING_COLUMNS}
                from public.pending_settlements
                order by created_at asc
                limit 1
                """
            )
            item = cursor.fetchone()
        return item, count

    def get_pending(self, item_id: UUID) -> dict[str, Any] | None:
        with self.connection.cursor() as cursor:
            cursor.execute(
                f"""
                select {PENDING_COLUMNS}
                from public.pending_settlements
                where id = %(id)s
                """,
                {"id": item_id},
            )
            return cursor.fetchone()

    def update_pending(
        self,
        item_id: UUID,
        payload: PendingSettlementUpdate,
    ) -> dict[str, Any] | None:
        updates = payload.model_dump(mode="json", exclude_unset=True)
        if not updates:
            return self.get_pending(item_id)

        allowed_columns = {
            "source_url",
            "raw_content",
            "raw_content_type",
            "brand_name",
            "max_payout",
            "country",
            "proof_required",
            "deadline",
            "eligibility_text",
            "ai_payload",
            "scraper_payload",
        }
        assignments = [
            f"{column} = %({column})s"
            for column in updates
            if column in allowed_columns
        ]
        updates["id"] = item_id

        with self.connection.cursor() as cursor:
            cursor.execute(
                f"""
                update public.pending_settlements
                set {", ".join(assignments)}
                where id = %(id)s
                returning {PENDING_COLUMNS}
                """,
                updates,
            )
            item = cursor.fetchone()
        self.connection.commit()
        return item
```

- [ ] **Step 5: Replace the empty queue route with CRUD endpoints**

Modify `admin_panel/app/routes/admin.py`:

```python
from collections.abc import Iterator
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from psycopg import Connection

from app.auth import require_admin_token
from app.db import open_connection
from app.schemas import (
    PendingItemResponse,
    PendingSettlementCreate,
    PendingSettlementRead,
    PendingSettlementUpdate,
)
from app.services.settlements import SettlementService
from app.settings import Settings, get_settings

router = APIRouter(
    prefix="/api/admin",
    dependencies=[Depends(require_admin_token)],
)


def get_connection(settings: Settings = Depends(get_settings)) -> Iterator[Connection]:
    yield from open_connection(settings)


def get_settlement_service(
    connection: Connection = Depends(get_connection),
) -> SettlementService:
    return SettlementService(connection)


@router.post(
    "/scraped-pool",
    response_model=PendingItemResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_scraped_pool_item(
    payload: PendingSettlementCreate,
    service: SettlementService = Depends(get_settlement_service),
) -> PendingItemResponse:
    item, count = service.create_pending(payload)
    return PendingItemResponse(item=PendingSettlementRead.model_validate(item), count=count)


@router.get("/pending", response_model=PendingItemResponse)
def get_next_pending_item(
    service: SettlementService = Depends(get_settlement_service),
) -> PendingItemResponse:
    item, count = service.get_next_pending()
    return PendingItemResponse(
        item=PendingSettlementRead.model_validate(item) if item else None,
        count=count,
    )


@router.get("/pending/{item_id}", response_model=PendingSettlementRead)
def get_pending_item(
    item_id: UUID,
    service: SettlementService = Depends(get_settlement_service),
) -> PendingSettlementRead:
    item = service.get_pending(item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Pending settlement not found")
    return PendingSettlementRead.model_validate(item)


@router.patch("/pending/{item_id}", response_model=PendingItemResponse)
def update_pending_item(
    item_id: UUID,
    payload: PendingSettlementUpdate,
    service: SettlementService = Depends(get_settlement_service),
) -> PendingItemResponse:
    item = service.update_pending(item_id, payload)
    if not item:
        raise HTTPException(status_code=404, detail="Pending settlement not found")
    _, count = service.get_next_pending()
    return PendingItemResponse(item=PendingSettlementRead.model_validate(item), count=count)
```

- [ ] **Step 6: Run pending pool tests and verify they pass**

Run:

```bash
cd admin_panel
python -m pytest tests/test_pending_pool.py -q
```

Expected:

```text
3 passed
```

---

### Task 4: Approval And Rejection Transactions

**Files:**

- Modify: `admin_panel/app/schemas.py`
- Modify: `admin_panel/app/services/settlements.py`
- Modify: `admin_panel/app/routes/admin.py`
- Create: `admin_panel/tests/test_approve_reject.py`

- [ ] **Step 1: Add failing approve/reject tests with a fake service**

Create `admin_panel/tests/test_approve_reject.py`:

```python
from copy import deepcopy
from uuid import UUID

from fastapi.testclient import TestClient

from app.routes.admin import get_settlement_service


class FakePublishService:
    def __init__(self) -> None:
        self.pending = {
            "11111111-1111-1111-1111-111111111111": {
                "id": "11111111-1111-1111-1111-111111111111",
                "source_url": "https://topclassactions.com/example/apple",
                "raw_content": "Apple raw text",
                "raw_content_type": "text",
                "brand_name": "Apple",
                "max_payout": "35.00",
                "country": "US",
                "proof_required": False,
                "deadline": "2026-08-14",
                "eligibility_text": "Eligible workers.",
                "ai_payload": {},
                "scraper_payload": {},
                "created_at": "2026-05-30T18:00:00Z",
            }
        }
        self.live_rows: list[dict[str, object]] = []
        self.version = 102

    def approve_pending(self, item_id: UUID, payload):
        item = self.pending.pop(str(item_id), None)
        if not item:
            return None, len(self.pending), None
        live = deepcopy(item)
        live.update(payload.model_dump(mode="json"))
        self.version += 1
        live["version_id"] = self.version
        self.live_rows.append(live)
        return None, len(self.pending), self.version

    def reject_pending(self, item_id: UUID):
        item = self.pending.pop(str(item_id), None)
        if not item:
            return None, len(self.pending)
        return None, len(self.pending)


def override_service(fake: FakePublishService):
    def dependency() -> FakePublishService:
        return fake

    return dependency


def auth_headers() -> dict[str, str]:
    return {"Authorization": "Bearer test-admin-token"}


def final_form() -> dict[str, object]:
    return {
        "brand_name": "Apple Inc.",
        "max_payout": "35.00",
        "country": "US",
        "proof_required": False,
        "deadline": "2026-08-14",
        "eligibility_text": "US retail employees with qualifying bag checks.",
    }


def test_approve_publishes_and_returns_next_item(client: TestClient) -> None:
    fake = FakePublishService()
    client.app.dependency_overrides[get_settlement_service] = override_service(fake)

    response = client.post(
        "/api/admin/approve/11111111-1111-1111-1111-111111111111",
        json=final_form(),
        headers=auth_headers(),
    )

    assert response.status_code == 200
    assert response.json() == {"item": None, "count": 0, "data_version": 103}
    assert fake.live_rows[0]["brand_name"] == "Apple Inc."
    assert fake.pending == {}


def test_reject_drops_pending_without_publishing(client: TestClient) -> None:
    fake = FakePublishService()
    client.app.dependency_overrides[get_settlement_service] = override_service(fake)

    response = client.post(
        "/api/admin/reject/11111111-1111-1111-1111-111111111111",
        headers=auth_headers(),
    )

    assert response.status_code == 200
    assert response.json() == {"item": None, "count": 0}
    assert fake.live_rows == []
    assert fake.version == 102
```

- [ ] **Step 2: Run approve/reject tests and verify they fail because endpoints are missing**

Run:

```bash
cd admin_panel
python -m pytest tests/test_approve_reject.py -q
```

Expected:

```text
2 failed
```

The failures should be `404 Not Found` for the approve and reject routes.

- [ ] **Step 3: Add approval schemas**

Append to `admin_panel/app/schemas.py`:

```python
class SettlementApprovalPayload(BaseModel):
    brand_name: str = Field(min_length=1)
    max_payout: Decimal | None = None
    country: CountryCode
    proof_required: bool = False
    deadline: date | None = None
    eligibility_text: str | None = None


class ApprovalResponse(PendingItemResponse):
    data_version: int
```

- [ ] **Step 4: Add approve and reject service methods**

Append these methods inside `SettlementService` in `admin_panel/app/services/settlements.py`:

```python
    def approve_pending(
        self,
        item_id: UUID,
        payload: SettlementApprovalPayload,
    ) -> tuple[dict[str, Any] | None, int, int | None]:
        with self.connection.transaction():
            with self.connection.cursor() as cursor:
                cursor.execute(
                    f"""
                    select {PENDING_COLUMNS}
                    from public.pending_settlements
                    where id = %(id)s
                    for update
                    """,
                    {"id": item_id},
                )
                pending = cursor.fetchone()
                if not pending:
                    return None, self._pending_count(cursor), None

                cursor.execute(
                    """
                    insert into public.settlements (
                      brand_name,
                      max_payout,
                      country,
                      deadline,
                      eligibility_text,
                      proof_required
                    )
                    values (
                      %(brand_name)s,
                      %(max_payout)s,
                      %(country)s,
                      %(deadline)s,
                      %(eligibility_text)s,
                      %(proof_required)s
                    )
                    returning version_id
                    """,
                    payload.model_dump(mode="json"),
                )
                version_id = int(cursor.fetchone()["version_id"])

                cursor.execute(
                    """
                    update public.global_meta
                    set value = to_jsonb(%(version_id)s::bigint),
                        updated_at = now()
                    where key = 'data_version'
                      and (value)::bigint < %(version_id)s
                    """,
                    {"version_id": version_id},
                )

                cursor.execute(
                    "delete from public.pending_settlements where id = %(id)s",
                    {"id": item_id},
                )

                next_item = self._next_pending(cursor)
                count = self._pending_count(cursor)

        return next_item, count, version_id

    def reject_pending(self, item_id: UUID) -> tuple[dict[str, Any] | None, int]:
        with self.connection.transaction():
            with self.connection.cursor() as cursor:
                cursor.execute(
                    "delete from public.pending_settlements where id = %(id)s",
                    {"id": item_id},
                )
                if cursor.rowcount == 0:
                    return None, self._pending_count(cursor)
                next_item = self._next_pending(cursor)
                count = self._pending_count(cursor)
        return next_item, count

    def _pending_count(self, cursor) -> int:
        cursor.execute("select count(*) as count from public.pending_settlements")
        return int(cursor.fetchone()["count"])

    def _next_pending(self, cursor) -> dict[str, Any] | None:
        cursor.execute(
            f"""
            select {PENDING_COLUMNS}
            from public.pending_settlements
            order by created_at asc
            limit 1
            """
        )
        return cursor.fetchone()
```

Also update the import line at the top of `admin_panel/app/services/settlements.py`:

```python
from app.schemas import (
    PendingSettlementCreate,
    PendingSettlementUpdate,
    SettlementApprovalPayload,
)
```

- [ ] **Step 5: Add approve and reject routes**

Append to `admin_panel/app/routes/admin.py`:

```python
@router.post("/approve/{item_id}", response_model=ApprovalResponse)
def approve_pending_item(
    item_id: UUID,
    payload: SettlementApprovalPayload,
    service: SettlementService = Depends(get_settlement_service),
) -> ApprovalResponse:
    item, count, data_version = service.approve_pending(item_id, payload)
    if data_version is None:
        raise HTTPException(status_code=404, detail="Pending settlement not found")
    return ApprovalResponse(
        item=PendingSettlementRead.model_validate(item) if item else None,
        count=count,
        data_version=data_version,
    )


@router.post("/reject/{item_id}", response_model=PendingItemResponse)
def reject_pending_item(
    item_id: UUID,
    service: SettlementService = Depends(get_settlement_service),
) -> PendingItemResponse:
    item, count = service.reject_pending(item_id)
    return PendingItemResponse(
        item=PendingSettlementRead.model_validate(item) if item else None,
        count=count,
    )
```

Update the schema imports in `admin_panel/app/routes/admin.py`:

```python
from app.schemas import (
    ApprovalResponse,
    PendingItemResponse,
    PendingSettlementCreate,
    PendingSettlementRead,
    PendingSettlementUpdate,
    SettlementApprovalPayload,
)
```

- [ ] **Step 6: Run approve/reject tests and verify they pass**

Run:

```bash
cd admin_panel
python -m pytest tests/test_approve_reject.py -q
```

Expected:

```text
2 passed
```

---

### Task 5: Single-Page Review UI

**Files:**

- Modify: `admin_panel/templates/review.html`
- Modify: `admin_panel/static/admin.js`

- [ ] **Step 1: Replace the minimal template with the two-column layout**

Replace `admin_panel/templates/review.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>ClaimPal Operations Review</title>
    <script src="https://cdn.tailwindcss.com"></script>
  </head>
  <body class="bg-slate-50 text-slate-950">
    <div class="min-h-screen">
      <header class="sticky top-0 z-20 border-b border-slate-200 bg-white">
        <div class="mx-auto flex max-w-7xl items-center justify-between px-4 py-3">
          <div>
            <h1 class="text-lg font-semibold text-slate-950">ClaimPal Operations Review</h1>
            <p class="text-xs text-slate-500">Human-in-the-loop settlement publishing</p>
          </div>
          <div id="pendingBadge" class="rounded-full bg-emerald-50 px-3 py-1 text-sm font-semibold text-emerald-700">
            Pending Review List: 0 items left
          </div>
        </div>
      </header>

      <main class="mx-auto grid max-w-7xl gap-4 px-4 py-4 lg:grid-cols-2">
        <section class="min-h-[calc(100vh-112px)] rounded border border-slate-200 bg-white">
          <div class="border-b border-slate-200 p-4">
            <div class="flex items-center justify-between gap-4">
              <h2 class="text-sm font-semibold uppercase tracking-wide text-slate-700">Raw Source Data</h2>
              <a
                id="sourceLink"
                href="#"
                target="_blank"
                rel="noreferrer"
                class="hidden text-sm font-semibold text-blue-800 hover:text-blue-950"
              >
                Open original source
              </a>
            </div>
            <div id="sourceUrl" class="mt-3 hidden truncate rounded border border-slate-200 bg-slate-50 px-3 py-2 text-xs text-slate-600"></div>
          </div>
          <pre id="rawContent" class="h-[calc(100vh-190px)] overflow-auto whitespace-pre-wrap bg-slate-950 p-4 text-sm leading-6 text-slate-100"></pre>
        </section>

        <section class="min-h-[calc(100vh-112px)] rounded border border-slate-200 bg-white">
          <form id="reviewForm" class="flex min-h-[calc(100vh-112px)] flex-col">
            <div class="space-y-4 p-4">
              <h2 class="text-sm font-semibold uppercase tracking-wide text-slate-700">AI Sanitized Form</h2>

              <div class="grid gap-4 md:grid-cols-2">
                <label class="block text-sm font-medium text-slate-700">
                  Brand/Company Name
                  <input id="brandName" name="brand_name" required class="mt-1 w-full rounded border border-slate-300 px-3 py-2 text-sm" />
                </label>

                <label class="block text-sm font-medium text-slate-700">
                  Maximum Estimated Payout
                  <input id="maxPayout" name="max_payout" type="number" step="0.01" min="0" class="mt-1 w-full rounded border border-slate-300 px-3 py-2 text-sm" />
                </label>

                <label class="block text-sm font-medium text-slate-700">
                  Country
                  <select id="country" name="country" required class="mt-1 w-full rounded border border-slate-300 px-3 py-2 text-sm">
                    <option value="US">United States</option>
                    <option value="CA">Canada</option>
                  </select>
                </label>

                <label class="block text-sm font-medium text-slate-700">
                  Final Deadline
                  <input id="deadline" name="deadline" type="date" class="mt-1 w-full rounded border border-slate-300 px-3 py-2 text-sm" />
                </label>
              </div>

              <label class="flex items-center gap-3 text-sm font-medium text-slate-700">
                <input id="proofRequired" name="proof_required" type="checkbox" class="h-5 w-5 rounded border-slate-300 text-emerald-700" />
                Proof Required
              </label>

              <label class="block text-sm font-medium text-slate-700">
                Eligibility Criteria Summary
                <textarea id="eligibilityText" name="eligibility_text" rows="8" class="mt-1 w-full rounded border border-slate-300 px-3 py-2 text-sm"></textarea>
              </label>

              <div id="message" class="hidden rounded border px-3 py-2 text-sm"></div>
            </div>

            <div class="sticky bottom-0 mt-auto grid grid-cols-2 gap-3 border-t border-slate-200 bg-white p-4">
              <button id="approveButton" type="submit" class="rounded bg-emerald-700 px-4 py-3 text-sm font-semibold text-white hover:bg-emerald-800">
                Approve &amp; Publish
              </button>
              <button id="rejectButton" type="button" class="rounded bg-red-700 px-4 py-3 text-sm font-semibold text-white hover:bg-red-800">
                Reject / Spam
              </button>
            </div>
          </form>
        </section>
      </main>
    </div>

    <script src="/static/admin.js"></script>
  </body>
</html>
```

- [ ] **Step 2: Add frontend state and API calls**

Replace `admin_panel/static/admin.js`:

```javascript
const state = {
  token: sessionStorage.getItem("claimpal_admin_token") || "",
  currentItem: null,
};

const elements = {
  pendingBadge: document.getElementById("pendingBadge"),
  sourceLink: document.getElementById("sourceLink"),
  sourceUrl: document.getElementById("sourceUrl"),
  rawContent: document.getElementById("rawContent"),
  reviewForm: document.getElementById("reviewForm"),
  brandName: document.getElementById("brandName"),
  maxPayout: document.getElementById("maxPayout"),
  country: document.getElementById("country"),
  proofRequired: document.getElementById("proofRequired"),
  deadline: document.getElementById("deadline"),
  eligibilityText: document.getElementById("eligibilityText"),
  message: document.getElementById("message"),
  approveButton: document.getElementById("approveButton"),
  rejectButton: document.getElementById("rejectButton"),
};

function ensureToken() {
  if (state.token) return;
  const enteredToken = window.prompt("Enter ClaimPal admin bearer token");
  if (!enteredToken) {
    showMessage("Admin token is required to load the review queue.", "error");
    return;
  }
  state.token = enteredToken;
  sessionStorage.setItem("claimpal_admin_token", enteredToken);
}

async function apiFetch(path, options = {}) {
  ensureToken();
  const response = await fetch(path, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${state.token}`,
      ...(options.headers || {}),
    },
  });

  if (response.status === 401 || response.status === 403) {
    sessionStorage.removeItem("claimpal_admin_token");
    state.token = "";
    throw new Error("Authorization failed. Re-enter the admin token.");
  }

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(payload.detail || "Request failed.");
  }
  return payload;
}

function showMessage(text, kind = "success") {
  elements.message.textContent = text;
  elements.message.className =
    kind === "error"
      ? "rounded border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800"
      : "rounded border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800";
}

function setBusy(isBusy) {
  elements.approveButton.disabled = isBusy;
  elements.rejectButton.disabled = isBusy;
  elements.approveButton.classList.toggle("opacity-60", isBusy);
  elements.rejectButton.classList.toggle("opacity-60", isBusy);
}

function renderQueue(payload) {
  elements.pendingBadge.textContent = `Pending Review List: ${payload.count} items left`;
  state.currentItem = payload.item;

  if (!payload.item) {
    elements.rawContent.textContent = "No pending settlements.";
    elements.reviewForm.reset();
    elements.sourceLink.classList.add("hidden");
    elements.sourceUrl.classList.add("hidden");
    setBusy(true);
    showMessage("Review queue is empty.", "success");
    return;
  }

  setBusy(false);
  const item = payload.item;
  elements.rawContent.textContent = item.raw_content || "";
  elements.brandName.value = item.brand_name || "";
  elements.maxPayout.value = item.max_payout || "";
  elements.country.value = item.country || "US";
  elements.proofRequired.checked = Boolean(item.proof_required);
  elements.deadline.value = item.deadline || "";
  elements.eligibilityText.value = item.eligibility_text || "";

  if (item.source_url) {
    elements.sourceLink.href = item.source_url;
    elements.sourceLink.classList.remove("hidden");
    elements.sourceUrl.textContent = `Source URL: ${item.source_url}`;
    elements.sourceUrl.classList.remove("hidden");
  } else {
    elements.sourceLink.classList.add("hidden");
    elements.sourceUrl.classList.add("hidden");
  }
}

function collectFormPayload() {
  return {
    brand_name: elements.brandName.value.trim(),
    max_payout: elements.maxPayout.value || null,
    country: elements.country.value,
    proof_required: elements.proofRequired.checked,
    deadline: elements.deadline.value || null,
    eligibility_text: elements.eligibilityText.value.trim() || null,
  };
}

async function loadPending() {
  try {
    setBusy(true);
    const payload = await apiFetch("/api/admin/pending");
    renderQueue(payload);
  } catch (error) {
    showMessage(error.message, "error");
  } finally {
    if (state.currentItem) setBusy(false);
  }
}

elements.reviewForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  if (!state.currentItem) return;

  try {
    setBusy(true);
    const payload = await apiFetch(`/api/admin/approve/${state.currentItem.id}`, {
      method: "POST",
      body: JSON.stringify(collectFormPayload()),
    });
    showMessage(`Published. Data version is now ${payload.data_version}.`, "success");
    renderQueue(payload);
  } catch (error) {
    showMessage(error.message, "error");
  } finally {
    if (state.currentItem) setBusy(false);
  }
});

elements.rejectButton.addEventListener("click", async () => {
  if (!state.currentItem) return;

  try {
    setBusy(true);
    const payload = await apiFetch(`/api/admin/reject/${state.currentItem.id}`, {
      method: "POST",
    });
    showMessage("Rejected pending settlement.", "success");
    renderQueue(payload);
  } catch (error) {
    showMessage(error.message, "error");
  } finally {
    if (state.currentItem) setBusy(false);
  }
});

loadPending();
```

- [ ] **Step 3: Start the admin server for manual UI verification**

Run:

```bash
cd admin_panel
uvicorn app.main:app --reload --port 8008
```

Expected:

```text
Uvicorn running on http://127.0.0.1:8008
```

- [ ] **Step 4: Open and inspect the UI**

Open:

```text
http://127.0.0.1:8008
```

Expected:

- Header shows `ClaimPal Operations Review`.
- Badge shows `Pending Review List: 0 items left` until data is loaded.
- Left column has `Open original source` behavior when a row contains `source_url`.
- Right column has the six required editable fields.
- Sticky green and red buttons are visible at the bottom of the right column.

---

### Task 6: Integration Verification Against Local Supabase

**Files:**

- No new files required.

- [ ] **Step 1: Start Supabase and apply migrations**

Run:

```bash
npx supabase start
npx supabase migration up
```

Expected:

```text
Finished supabase migration up.
```

- [ ] **Step 2: Start admin server with local environment**

Run from `admin_panel/`:

```bash
set ADMIN_BEARER_TOKEN=dev-admin-token
set DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres
uvicorn app.main:app --port 8008
```

Expected:

```text
Uvicorn running on http://127.0.0.1:8008
```

- [ ] **Step 3: Push a pending scraper payload**

Run:

```bash
curl -X POST http://127.0.0.1:8008/api/admin/scraped-pool ^
  -H "Authorization: Bearer dev-admin-token" ^
  -H "Content-Type: application/json" ^
  -d "{\"source_url\":\"https://topclassactions.com/example/apple\",\"raw_content\":\"Apple raw settlement text\",\"raw_content_type\":\"text\",\"brand_name\":\"Apple\",\"max_payout\":\"35.00\",\"country\":\"US\",\"proof_required\":false,\"deadline\":\"2026-08-14\",\"eligibility_text\":\"US retail employees with qualifying bag checks.\",\"ai_payload\":{\"confidence\":0.92},\"scraper_payload\":{\"source\":\"topclassactions\"}}"
```

Expected response contains:

```json
{
  "count": 1,
  "item": {
    "brand_name": "Apple",
    "source_url": "https://topclassactions.com/example/apple"
  }
}
```

- [ ] **Step 4: Approve the pending row in the browser**

Open:

```text
http://127.0.0.1:8008
```

Enter token:

```text
dev-admin-token
```

Expected:

- The raw content appears in the left column.
- The source URL appears above the raw text.
- `Open original source` opens the source URL in a new tab.
- The AI fields are pre-filled in the right form.
- Clicking `Approve & Publish` shows a success message with the new data version.
- The pending badge changes to `Pending Review List: 0 items left`.

- [ ] **Step 5: Verify database state**

Run:

```bash
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -c "select brand_name, max_payout, country, proof_required from public.settlements where brand_name = 'Apple' order by created_at desc limit 1;"
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -c "select count(*) from public.pending_settlements;"
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -c "select value from public.global_meta where key = 'data_version';"
```

Expected:

```text
settlements contains Apple with country US
pending_settlements count is 0
global_meta.data_version is at least the inserted settlement version_id
```

- [ ] **Step 6: Run all admin tests**

Run:

```bash
cd admin_panel
python -m pytest -q
```

Expected:

```text
7 passed
```

- [ ] **Step 7: Final worktree check without Git writes**

Run:

```bash
git status --short
```

Expected: implementation files are unstaged or modified according to the current workspace state. Do not stage, commit, branch, or push in this session.

---

## Self-Review Notes

Spec coverage:

- Standalone Python admin project: Task 1.
- Bearer token security: Task 1.
- `pending_settlements` table: Task 2.
- Scraper push endpoint: Task 3.
- Pending list/read/update CRUD: Task 3.
- Approval publish transaction: Task 4.
- Reject path: Task 4.
- Two-column Tailwind UI: Task 5.
- Source URL display and original-link opening: Task 5 and Task 6.
- Pending counter badge: Task 5.
- Validation and rollback behavior: Tasks 3, 4, and 6.
- Tests: Tasks 1, 3, 4, and 6.

Type consistency:

- API payloads use `brand_name`, `max_payout`, `country`, `proof_required`, `deadline`, and `eligibility_text` consistently across schemas, service code, routes, and JavaScript.
- `source_url` is retained in pending rows and surfaced in the frontend.
- Publish version uses inserted `settlements.version_id`, preserving the existing `global_meta.data_version == max(settlements.version_id)` invariant.
