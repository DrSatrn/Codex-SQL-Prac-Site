COMPOSE ?= docker compose

PYTHON ?= python3
VENV ?= .venv
PIP := $(VENV)/bin/pip
PY := $(VENV)/bin/python
UVICORN := $(VENV)/bin/uvicorn

.PHONY: up seed run down logs ps reset \
	setup-local run-local db-up db-seed db-reset

up:
	$(COMPOSE) up -d postgres

seed:
	$(COMPOSE) run --rm seed

run:
	$(COMPOSE) up -d --build app postgres

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f app

ps:
	$(COMPOSE) ps

reset:
	$(COMPOSE) down -v
	$(COMPOSE) up -d postgres
	$(COMPOSE) run --rm seed

# Legacy local-host mode (optional)
setup-local:
	$(PYTHON) -m venv $(VENV)
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

run-local:
	$(UVICORN) app.main:app --reload --host 127.0.0.1 --port 8000

db-up: up

db-seed: seed

db-reset: reset
