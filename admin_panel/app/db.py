from collections.abc import Iterator
from contextlib import contextmanager
from typing import Any

from app.settings import Settings


@contextmanager
def open_connection(settings: Settings) -> Iterator[Any]:
    import psycopg
    from psycopg.rows import dict_row

    with psycopg.connect(settings.database_url, row_factory=dict_row) as connection:
        yield connection
