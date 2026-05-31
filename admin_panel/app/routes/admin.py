from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

from app.auth import require_admin_token
from app.schemas import (
    ApprovalResponse,
    PendingItemResponse,
    PendingSettlementCreate,
    PendingSettlementRead,
    PendingSettlementUpdate,
    SettlementApprovalPayload,
)
from app.services.settlements import SettlementService
from app.settings import Settings, get_settings

router = APIRouter(
    prefix="/api/admin",
    dependencies=[Depends(require_admin_token)],
)


def get_settlement_service(settings: Annotated[Settings, Depends(get_settings)]) -> SettlementService:
    return SettlementService(settings)


@router.post(
    "/scraped-pool",
    response_model=PendingItemResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_pending(
    payload: PendingSettlementCreate,
    service: Annotated[SettlementService, Depends(get_settlement_service)],
) -> PendingItemResponse:
    item, count = service.create_pending(payload)
    return PendingItemResponse(item=item, count=count)


@router.get("/pending", response_model=PendingItemResponse)
def get_next_pending(
    service: Annotated[SettlementService, Depends(get_settlement_service)],
) -> PendingItemResponse:
    item, count = service.get_next_pending()
    return PendingItemResponse(item=item, count=count)


@router.get("/pending/{pending_id}", response_model=PendingSettlementRead)
def get_pending(
    pending_id: UUID,
    service: Annotated[SettlementService, Depends(get_settlement_service)],
) -> PendingSettlementRead:
    item = service.get_pending(pending_id)
    if item is None:
        raise _pending_not_found()

    return PendingSettlementRead.model_validate(item)


@router.patch("/pending/{pending_id}", response_model=PendingItemResponse)
def update_pending(
    pending_id: UUID,
    payload: PendingSettlementUpdate,
    service: Annotated[SettlementService, Depends(get_settlement_service)],
) -> PendingItemResponse:
    item, count = service.update_pending(pending_id, payload)
    if item is None:
        raise _pending_not_found()

    return PendingItemResponse(item=item, count=count)


@router.post("/approve/{item_id}", response_model=ApprovalResponse)
def approve_pending(
    item_id: UUID,
    payload: SettlementApprovalPayload,
    service: Annotated[SettlementService, Depends(get_settlement_service)],
) -> ApprovalResponse:
    item, count, data_version = service.approve_pending(item_id, payload)
    if data_version is None:
        raise _pending_not_found()

    return ApprovalResponse(item=item, count=count, data_version=data_version)


@router.post("/reject/{item_id}", response_model=PendingItemResponse)
def reject_pending(
    item_id: UUID,
    service: Annotated[SettlementService, Depends(get_settlement_service)],
) -> PendingItemResponse:
    item, count, deleted = service.reject_pending(item_id)
    if not deleted:
        raise _pending_not_found()

    return PendingItemResponse(item=item, count=count)


def _pending_not_found() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Pending settlement not found",
    )
