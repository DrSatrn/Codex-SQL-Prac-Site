from __future__ import annotations

import os
from pathlib import Path

import psycopg

DATASETS = {
    'sales_lab': 'sales_lab.sql',
    'hr_lab': 'hr_lab.sql',
    'finance_lab': 'finance_lab.sql',
    'healthcare_lab': 'healthcare_lab.sql',
    'logistics_lab': 'logistics_lab.sql',
    'social_lab': 'social_lab.sql',
}

ROOT = Path(__file__).resolve().parent.parent
SCHEMA_SQL = ROOT / 'sql' / 'schema.sql'
COMMON_SQL = ROOT / 'sql' / 'seeds' / 'common.sql'
SEEDS_DIR = ROOT / 'sql' / 'seeds'


def env(name: str, default: str) -> str:
    return os.getenv(name, default)


def admin_dsn(dbname: str) -> str:
    return (
        f"host={env('POSTGRES_HOST', '127.0.0.1')} "
        f"port={env('POSTGRES_PORT', '5432')} "
        f"dbname={dbname} "
        f"user={env('POSTGRES_USER', 'postgres')} "
        f"password={env('POSTGRES_PASSWORD', 'postgres')} "
        f"sslmode={env('POSTGRES_SSLMODE', 'disable')}"
    )


def create_database_if_missing(name: str) -> None:
    with psycopg.connect(admin_dsn('postgres'), autocommit=True) as conn:
        with conn.cursor() as cur:
            cur.execute('SELECT 1 FROM pg_database WHERE datname = %s', (name,))
            exists = cur.fetchone() is not None
            if exists:
                print(f'[exists] {name}')
            else:
                cur.execute(f'CREATE DATABASE "{name}"')
                print(f'[created] {name}')


def execute_sql_file(conn: psycopg.Connection, path: Path) -> None:
    sql = path.read_text(encoding='utf-8')
    with conn.cursor() as cur:
        cur.execute(sql)


def reset_and_seed_database(name: str, seed_file: str) -> None:
    print(f'[seeding] {name}')
    with psycopg.connect(admin_dsn(name), autocommit=True) as conn:
        execute_sql_file(conn, SCHEMA_SQL)
        execute_sql_file(conn, COMMON_SQL)
        execute_sql_file(conn, SEEDS_DIR / seed_file)

        with conn.cursor() as cur:
            cur.execute('ANALYZE')

    print(f'[done] {name}')


def main() -> None:
    for dataset in DATASETS:
        create_database_if_missing(dataset)

    for dataset, seed_file in DATASETS.items():
        reset_and_seed_database(dataset, seed_file)

    print('All practice datasets are ready.')


if __name__ == '__main__':
    main()
