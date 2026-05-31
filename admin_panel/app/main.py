from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from app.routes.admin import router as admin_router

BASE_DIR = Path(__file__).resolve().parents[1]
templates = Jinja2Templates(directory=BASE_DIR / "templates")


def create_app() -> FastAPI:
    app = FastAPI(title="ClaimPal Admin Panel")
    app.mount("/static", StaticFiles(directory=BASE_DIR / "static"), name="static")
    app.include_router(admin_router)

    @app.get("/", response_class=HTMLResponse)
    def review_page(request: Request) -> HTMLResponse:
        return templates.TemplateResponse(request, "review.html")

    return app


app = create_app()
