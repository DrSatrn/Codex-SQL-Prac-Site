from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any, Optional

from app.core.models import Diagnostic


@dataclass
class QueryExecutionResult:
    command: Optional[str]
    columns: list[str]
    rows: list[dict[str, Any]]
    row_count: int
    truncated: bool
    execute_ms: float
    explain: Optional[dict[str, Any]] = None


class QueryEngine(ABC):
    name: str
    label: str

    @abstractmethod
    def list_datasets(self) -> list[str]:
        raise NotImplementedError

    @abstractmethod
    def lint(self, sql: str) -> list[Diagnostic]:
        raise NotImplementedError

    @abstractmethod
    def execute(
        self,
        *,
        dataset: str,
        sql: str,
        row_limit: int,
        include_explain: bool,
    ) -> QueryExecutionResult:
        raise NotImplementedError
