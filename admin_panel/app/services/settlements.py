from datetime import date, datetime, time, timezone
from typing import Any
from uuid import UUID

from app.db import open_connection
from app.schemas import (
    PendingSettlementCreate,
    PendingSettlementUpdate,
    SettlementApprovalPayload,
)
from app.settings import Settings


PENDING_COLUMNS = (
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
)
JSON_COLUMNS = {"ai_payload", "scraper_payload"}

RETURNING_COLUMNS = (
    "id",
    *PENDING_COLUMNS,
    "created_at",
)
RETURNING_SQL = ", ".join(f'"{column}"' for column in RETURNING_COLUMNS)
PENDING_SQL = ", ".join(f'"{column}"' for column in PENDING_COLUMNS)
SETTLEMENT_COLUMNS = (
    "brand_name",
    "max_payout",
    "country",
    "deadline",
    "eligibility_text",
    "proof_required",
)


class SettlementService:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    def create_pending(
        self,
        payload: PendingSettlementCreate,
    ) -> tuple[dict[str, Any], int]:
        data = _dump_payload(payload)
        columns = ", ".join(f'"{column}"' for column in PENDING_COLUMNS)
        placeholders = ", ".join(f"%({column})s" for column in PENDING_COLUMNS)
        query = (
            f"""
            INSERT INTO public.pending_settlements ({columns})
            VALUES ({placeholders})
            RETURNING {RETURNING_SQL}
            """
        )

        with open_connection(self.settings) as connection:
            item = connection.execute(query, data).fetchone()
            count = _count_pending(connection)
            connection.commit()

        return item, count

    def get_next_pending(self) -> tuple[dict[str, Any] | None, int]:
        with open_connection(self.settings) as connection:
            item = _get_next_pending(connection)
            count = _count_pending(connection)

        return item, count

    def get_pending(self, pending_id: UUID) -> dict[str, Any] | None:
        query = (
            """
            SELECT {returning_columns}
            FROM public.pending_settlements
            WHERE id = %(id)s
            """
        ).format(returning_columns=RETURNING_SQL)

        with open_connection(self.settings) as connection:
            return _get_pending(connection, query, pending_id)

    def update_pending(
        self,
        pending_id: UUID,
        payload: PendingSettlementUpdate,
    ) -> tuple[dict[str, Any] | None, int]:
        data = _dump_payload(payload, exclude_unset=True)
        data = {key: value for key, value in data.items() if key in PENDING_COLUMNS}

        if not data:
            item = self.get_pending(pending_id)
            with open_connection(self.settings) as connection:
                return item, _count_pending(connection)

        with open_connection(self.settings) as connection:
            data["id"] = pending_id
            assignments = [
                f'"{column}" = %({column})s'
                for column in data
                if column != "id"
            ]
            query = (
                """
                UPDATE public.pending_settlements
                SET {assignments}
                WHERE id = %(id)s
                RETURNING {returning_columns}
                """
            ).format(assignments=", ".join(assignments), returning_columns=RETURNING_SQL)

            item = connection.execute(query, data).fetchone()
            count = _count_pending(connection)
            connection.commit()

        return item, count

    def approve_pending(
        self,
        item_id: UUID,
        payload: SettlementApprovalPayload,
    ) -> tuple[dict[str, Any] | None, int, int | None]:
        data = _dump_approval_payload(payload)
        settlement_columns = ", ".join(f'"{column}"' for column in SETTLEMENT_COLUMNS)
        placeholders = ", ".join(f"%({column})s" for column in SETTLEMENT_COLUMNS)
        lock_query = (
            """
            SELECT {pending_columns}
            FROM public.pending_settlements
            WHERE id = %(id)s
            FOR UPDATE
            """
        ).format(pending_columns=PENDING_SQL)
        insert_query = (
            """
            INSERT INTO public.settlements ({settlement_columns})
            VALUES ({placeholders})
            RETURNING version_id
            """
        ).format(settlement_columns=settlement_columns, placeholders=placeholders)

        with open_connection(self.settings) as connection:
            pending_item = connection.execute(lock_query, {"id": item_id}).fetchone()
            if pending_item is None:
                count = _count_pending(connection)
                connection.commit()
                return None, count, None

            version_row = connection.execute(insert_query, data).fetchone()
            data_version = version_row["version_id"]
            connection.execute(
                """
                UPDATE public.global_meta
                SET value = to_jsonb(%(data_version)s::bigint),
                    updated_at = now()
                WHERE key = 'data_version'
                  AND (value)::bigint < %(data_version)s
                """,
                {"data_version": data_version},
            )
            connection.execute(
                """
                DELETE FROM public.pending_settlements
                WHERE id = %(id)s
                """,
                {"id": item_id},
            )
            next_item = _get_next_pending(connection)
            count = _count_pending(connection)
            connection.commit()

        return next_item, count, data_version

    def reject_pending(self, item_id: UUID) -> tuple[dict[str, Any] | None, int, bool]:
        with open_connection(self.settings) as connection:
            delete_cursor = connection.execute(
                """
                DELETE FROM public.pending_settlements
                WHERE id = %(id)s
                """,
                {"id": item_id},
            )
            if delete_cursor.rowcount == 0:
                count = _count_pending(connection)
                connection.commit()
                return None, count, False

            next_item = _get_next_pending(connection)
            count = _count_pending(connection)
            connection.commit()

        return next_item, count, True


def _dump_payload(
    payload: PendingSettlementCreate | PendingSettlementUpdate,
    *,
    exclude_unset: bool = False,
) -> dict[str, Any]:
    data = payload.model_dump(exclude_unset=exclude_unset)

    if data.get("source_url") is not None:
        data["source_url"] = str(data["source_url"])

    json_columns = [
        column for column in JSON_COLUMNS if column in data and data[column] is not None
    ]
    if not json_columns:
        return data

    from psycopg.types.json import Jsonb

    for column in json_columns:
        data[column] = Jsonb(data[column])

    return data


def _dump_approval_payload(payload: SettlementApprovalPayload) -> dict[str, Any]:
    data = payload.model_dump()
    data["deadline"] = _deadline_to_utc_end_of_day(data["deadline"])
    return data


def _deadline_to_utc_end_of_day(value: date | None) -> datetime | None:
    if value is None:
        return None

    return datetime.combine(value, time.max, tzinfo=timezone.utc)


def _count_pending(connection: Any) -> int:
    row = connection.execute(
        "SELECT count(*) AS count FROM public.pending_settlements"
    ).fetchone()
    return row["count"]


def _get_pending(connection: Any, query: str, pending_id: UUID) -> dict[str, Any] | None:
    return connection.execute(query, {"id": pending_id}).fetchone()


def _get_next_pending(connection: Any) -> dict[str, Any] | None:
    query = (
        """
        SELECT {returning_columns}
        FROM public.pending_settlements
        ORDER BY created_at ASC, id ASC
        LIMIT 1
        """
    ).format(returning_columns=RETURNING_SQL)
    return connection.execute(query).fetchone()
