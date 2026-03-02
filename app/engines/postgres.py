from __future__ import annotations

from time import perf_counter
from typing import Any, Optional

from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool

from app.core.config import settings
from app.core.diagnostics import lint_sql
from app.core.models import Diagnostic
from app.engines.base import QueryEngine, QueryExecutionResult


class PostgresQueryEngine(QueryEngine):
    name = 'postgres'
    label = 'PostgreSQL'

    def __init__(self, datasets: list[str]):
        self._datasets = datasets
        self._pools = {
            dataset: ConnectionPool(
                conninfo=settings.dsn_for_dataset(dataset),
                min_size=0,
                max_size=4,
                open=True,
                kwargs={'autocommit': True},
            )
            for dataset in datasets
        }

    def list_datasets(self) -> list[str]:
        return self._datasets

    def lint(self, sql: str) -> list[Diagnostic]:
        return lint_sql(sql=sql, dialect='postgres')

    def execute(
        self,
        *,
        dataset: str,
        sql: str,
        row_limit: int,
        include_explain: bool,
    ) -> QueryExecutionResult:
        pool = self._pools.get(dataset)
        if not pool:
            raise ValueError(f'Unknown dataset: {dataset}')

        with pool.connection() as conn:
            with conn.cursor(row_factory=dict_row) as cur:
                cur.execute(f'SET statement_timeout = {settings.query_timeout_ms}')

                started = perf_counter()
                cur.execute(sql)
                execute_ms = round((perf_counter() - started) * 1000, 3)

                command = (cur.statusmessage or '').split(' ', 1)[0].upper() or None

                if cur.description:
                    columns = [desc.name for desc in cur.description]
                    buffered_rows = cur.fetchmany(row_limit + 1)
                    truncated = len(buffered_rows) > row_limit
                    buffered_rows = buffered_rows[:row_limit]
                    rows = [dict(row) for row in buffered_rows]
                    row_count = len(rows)
                else:
                    columns = []
                    rows = []
                    row_count = max(cur.rowcount, 0)
                    truncated = False

                explain = None
                if include_explain and command in {'SELECT', 'WITH'}:
                    explain = self._collect_explain(conn=conn, sql=sql)

                return QueryExecutionResult(
                    command=command,
                    columns=columns,
                    rows=rows,
                    row_count=row_count,
                    truncated=truncated,
                    execute_ms=execute_ms,
                    explain=explain,
                )

    def _collect_explain(self, *, conn, sql: str) -> Optional[dict[str, Any]]:
        with conn.cursor() as cur:
            cur.execute(f'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) {sql}')
            payload = cur.fetchone()

        if not payload:
            return None

        explain_json = payload[0]
        if not explain_json:
            return None

        plan = explain_json[0]
        return {
            'planning_time_ms': plan.get('Planning Time'),
            'execution_time_ms': plan.get('Execution Time'),
            'plan': plan.get('Plan'),
        }
