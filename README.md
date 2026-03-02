# SQL Practice Lab

A local SQL training site with:

- Plain HTML/CSS/JavaScript frontend
- FastAPI backend
- PostgreSQL execution engine
- Full Docker Compose runtime (app + DB + seeding)

## What this build delivers

- PostgreSQL semantics for realistic SQL behavior
- Monaco editor with syntax highlighting and inline diagnostics
- Warning/error message panel + underlined editor markers
- Performance metrics (parse/lint/execute/total + explain timing)
- Session query history in browser storage
- Six seeded datasets:
  - `sales_lab`
  - `hr_lab`
  - `finance_lab`
  - `healthcare_lab`
  - `logistics_lab`
  - `social_lab`

## Runtime model

Everything can run in containers:

- `postgres` service: database engine + persistent volume
- `seed` service: one-off dataset creation and population
- `app` service: FastAPI API + static frontend host

## Prerequisites

- Docker (OrbStack or Docker Desktop)
- Docker Compose plugin
- `make`

No host Python install is required for normal use.

## Quick start (containerized)

1. From repo root:

```bash
cp .env.example .env
```

2. Start PostgreSQL:

```bash
make up
```

3. Seed datasets (first run or whenever you want to reset/populate):

```bash
make seed
```

4. Start app container:

```bash
make run
```

5. Open in Firefox:

- [http://127.0.0.1:8000](http://127.0.0.1:8000)

## Common commands

```bash
make ps      # show container status
make logs    # tail app logs
make down    # stop containers
make reset   # drop DB volume, recreate DB, reseed
```

## Environment variables

Configured via `.env`:

- `APP_HOST`
- `APP_PORT`
- `POSTGRES_HOST`
- `POSTGRES_PORT`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_SSLMODE`
- `DATASET_NAMES`
- `QUERY_TIMEOUT_MS`

## Notes on metrics

- `execute_ms` is measured around query execution on PostgreSQL.
- For `SELECT`/`WITH`, backend also runs `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` and returns planning/execution timing.
- Row output is capped by row limit for UI responsiveness.

## Optional host-run mode (legacy)

If you want to run the app on host Python instead of Docker:

```bash
make setup-local
make run-local
```

This is optional; container mode is the default path.

## Adding more engines later

1. Add a new adapter under `app/engines/` implementing `QueryEngine`.
2. Register it in `app/engines/registry.py`.
3. Add engine-specific configuration.
4. Frontend engine list auto-populates from `/api/v1/engines`.
