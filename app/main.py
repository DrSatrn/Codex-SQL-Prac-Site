from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from app.api.routes import router as api_router

app = FastAPI(title='SQL Practice Lab')
app.include_router(api_router)

static_dir = Path(__file__).parent / 'static'
app.mount('/', StaticFiles(directory=static_dir, html=True), name='static')
