from __future__ import annotations

from time import perf_counter

from fastapi import APIRouter, HTTPException
from psycopg import Error as PsycopgError

from app.core.models import DatasetInfo, EngineInfo, LintRequest, LintResponse, QueryRequest, QueryResponse
from app.engines.registry import registry

router = APIRouter(prefix='/api/v1')


@router.get('/health')
def health() -> dict[str, str]:
    return {'status': 'ok'}


@router.get('/engines', response_model=list[EngineInfo])
def list_engines() -> list[EngineInfo]:
    payload: list[EngineInfo] = []
    for engine in registry.list():
        payload.append(EngineInfo(name=engine.name, label=engine.label, enabled=True))
    return payload


@router.get('/datasets', response_model=list[DatasetInfo])
def list_datasets(engine: str = 'postgres') -> list[DatasetInfo]:
    try:
        selected_engine = registry.get(engine)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return [DatasetInfo(name=item) for item in selected_engine.list_datasets()]


@router.post('/lint', response_model=LintResponse)
def lint_sql(request: LintRequest) -> LintResponse:
    try:
        selected_engine = registry.get(request.engine)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    started = perf_counter()
    diagnostics = selected_engine.lint(request.sql)
    lint_ms = round((perf_counter() - started) * 1000, 3)
    return LintResponse(diagnostics=diagnostics, lint_ms=lint_ms)


@router.post('/query', response_model=QueryResponse)
def run_query(request: QueryRequest) -> QueryResponse:
    try:
        selected_engine = registry.get(request.engine)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    started = perf_counter()

    parse_started = perf_counter()
    diagnostics = selected_engine.lint(request.sql)
    parse_ms = round((perf_counter() - parse_started) * 1000, 3)
    lint_ms = parse_ms

    if any(item.severity == 'error' for item in diagnostics):
        return QueryResponse(
            ok=False,
            dataset=request.dataset,
            engine=request.engine,
            diagnostics=diagnostics,
            parse_ms=parse_ms,
            lint_ms=lint_ms,
            total_ms=round((perf_counter() - started) * 1000, 3),
            error='SQL contains syntax errors; query not executed.',
        )

    try:
        result = selected_engine.execute(
            dataset=request.dataset,
            sql=request.sql,
            row_limit=request.row_limit,
            include_explain=request.include_explain,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except PsycopgError as exc:
        return QueryResponse(
            ok=False,
            dataset=request.dataset,
            engine=request.engine,
            diagnostics=diagnostics,
            parse_ms=parse_ms,
            lint_ms=lint_ms,
            total_ms=round((perf_counter() - started) * 1000, 3),
            error=str(exc).strip(),
        )

    return QueryResponse(
        ok=True,
        dataset=request.dataset,
        engine=request.engine,
        command=result.command,
        columns=result.columns,
        rows=result.rows,
        row_count=result.row_count,
        truncated=result.truncated,
        diagnostics=diagnostics,
        parse_ms=parse_ms,
        lint_ms=lint_ms,
        execute_ms=result.execute_ms,
        total_ms=round((perf_counter() - started) * 1000, 3),
        explain=result.explain,
    )
