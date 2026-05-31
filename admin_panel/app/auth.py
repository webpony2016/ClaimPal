from secrets import compare_digest
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

    token = authorization.removeprefix("Bearer ")
    if not compare_digest(token, settings.admin_bearer_token):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid admin bearer token",
        )
