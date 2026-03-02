# SQL Practice Lab

A local-first SQL training site built with plain HTML/CSS/JS on the frontend and FastAPI on the backend.

## What this build delivers
- PostgreSQL as the primary dialect and execution engine (real semantics).
- SSMS-inspired query window layout.
- Monaco editor with syntax highlighting and inline squiggles.
- Error and warning diagnostics panel.
- Query result grid with row limit support.
- Query performance metrics:
  - parse/lint time
  - execution time
  - total server round-trip
  - optional `EXPLAIN ANALYZE` planning/execution values
- Session query history (browser `sessionStorage`).
- Six prebuilt practice datasets seeded with substantial data:
  - `sales_lab`
  - `hr_lab`
  - `finance_lab`
  - `healthcare_lab`
  - `logistics_lab`
  - `social_lab`

## Tech choices (and why)
- **PostgreSQL**: best free local engine for real SQL semantics and realistic performance behavior.
- **FastAPI + psycopg**: minimal, fast API layer with reliable Postgres execution.
- **Monaco Editor**: robust highlighting + diagnostics markers without using React.
- **Vanilla HTML/CSS/JS**: simple, fast, no framework overhead.

## Quick start (M-series Mac)

### 1) Start PostgreSQL
Use Docker (recommended):

```bash
make db-up
```

### 2) Create venv + install dependencies

```bash
make setup
```

### 3) Seed practice datasets

```bash
cp .env.example .env
make db-seed
```

### 4) Run the app

```bash
make run
```

Open [http://127.0.0.1:8000](http://127.0.0.1:8000) in Firefox.

## Local environment variables
Set in `.env`:

- `POSTGRES_HOST`
- `POSTGRES_PORT`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_SSLMODE`
- `DATASET_NAMES`
- `QUERY_TIMEOUT_MS`

## Notes on performance metrics
- `execute_ms` is measured around actual SQL execution on PostgreSQL.
- For `SELECT`/`WITH`, `include_explain=true` returns planner data from `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)`.
- Result rows are capped by the configured row limit for UI responsiveness.

## Adding more engines later
1. Add a new adapter under `app/engines/` implementing `QueryEngine`.
2. Register it in `app/engines/registry.py`.
3. Expose any required dataset/source config.
4. Frontend engine dropdown will populate via `/api/v1/engines`.
