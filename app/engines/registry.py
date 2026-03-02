from __future__ import annotations

from app.core.config import settings
from app.engines.base import QueryEngine
from app.engines.postgres import PostgresQueryEngine


class EngineRegistry:
    def __init__(self) -> None:
        self._engines: dict[str, QueryEngine] = {
            'postgres': PostgresQueryEngine(datasets=settings.datasets)
        }

    def get(self, engine_name: str) -> QueryEngine:
        engine = self._engines.get(engine_name)
        if not engine:
            raise ValueError(f'Unsupported engine: {engine_name}')
        return engine

    def list(self) -> list[QueryEngine]:
        return list(self._engines.values())


registry = EngineRegistry()
