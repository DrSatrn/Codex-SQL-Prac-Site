from typing import Any, Literal, Optional

from pydantic import BaseModel, Field


Severity = Literal['error', 'warning', 'info']


class Diagnostic(BaseModel):
    severity: Severity
    message: str
    line: int = 1
    start_col: int = 1
    end_col: int = 1
    code: Optional[str] = None


class LintRequest(BaseModel):
    sql: str
    engine: str = 'postgres'


class LintResponse(BaseModel):
    diagnostics: list[Diagnostic]
    lint_ms: float


class QueryRequest(BaseModel):
    sql: str
    engine: str = 'postgres'
    dataset: str
    row_limit: int = Field(default=200, ge=1, le=5000)
    include_explain: bool = False


class QueryResponse(BaseModel):
    ok: bool
    dataset: str
    engine: str
    command: Optional[str] = None
    columns: list[str] = Field(default_factory=list)
    rows: list[dict[str, Any]] = Field(default_factory=list)
    truncated: bool = False
    row_count: int = 0
    diagnostics: list[Diagnostic] = Field(default_factory=list)
    parse_ms: float = 0
    lint_ms: float = 0
    execute_ms: float = 0
    total_ms: float = 0
    explain: Optional[dict[str, Any]] = None
    error: Optional[str] = None


class DatasetInfo(BaseModel):
    name: str


class EngineInfo(BaseModel):
    name: str
    label: str
    enabled: bool
