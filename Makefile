PYTHON ?= python3
VENV ?= .venv
PIP := $(VENV)/bin/pip
PY := $(VENV)/bin/python
UVICORN := $(VENV)/bin/uvicorn

.PHONY: setup run db-up db-seed db-reset

setup:
	$(PYTHON) -m venv $(VENV)
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

db-up:
	docker compose up -d postgres

db-seed:
	$(PY) scripts/init_practice_datasets.py

run:
	$(UVICORN) app.main:app --reload --host 127.0.0.1 --port 8000

db-reset: db-up db-seed
