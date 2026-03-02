# Architecture

## Why PostgreSQL first
- PostgreSQL provides real execution semantics and realistic planner behavior while remaining free and easy to run locally.
- Query timing and `EXPLAIN ANALYZE` metrics are meaningful for real PostgreSQL work.

## Extensibility model
- Frontend sends `{ engine, dataset, sql }` to the backend.
- Backend resolves `engine` through `EngineRegistry`.
- Each engine adapter implements:
  - `lint(sql)` for diagnostics
  - `execute(dataset, sql, row_limit, include_explain)` for execution/metrics
  - `list_datasets()` for UI population
- Adding another engine later is a new adapter class and a registry entry.

## Current engine
- `postgres` adapter uses `psycopg` connection pools per dataset.
- Syntax diagnostics use SQL parsing plus warning rules.
- Runtime returns rows, columns, command, truncation signal, and timing metrics.
