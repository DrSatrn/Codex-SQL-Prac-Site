from __future__ import annotations

import re
from dataclasses import dataclass

from sqlglot import parse_one
from sqlglot.errors import ParseError

from app.core.models import Diagnostic


@dataclass
class WarningRule:
    code: str
    pattern: re.Pattern[str]
    message: str


WARNING_RULES = [
    WarningRule(
        code='W001',
        pattern=re.compile(r'\bSELECT\s+\*', re.IGNORECASE | re.MULTILINE),
        message='Avoid SELECT * in production-style queries. Prefer explicit columns.',
    ),
    WarningRule(
        code='W002',
        pattern=re.compile(r'\bDELETE\s+FROM\s+\w+\s*;?\s*$', re.IGNORECASE | re.MULTILINE),
        message='DELETE without WHERE will remove all rows from the table.',
    ),
    WarningRule(
        code='W003',
        pattern=re.compile(r'\bUPDATE\s+\w+\s+SET\b(?![\s\S]*\bWHERE\b)', re.IGNORECASE),
        message='UPDATE without WHERE will modify all rows in the table.',
    ),
]


def _line_col_from_index(text: str, index: int) -> tuple[int, int]:
    before = text[:index]
    line = before.count('\n') + 1
    last_newline = before.rfind('\n')
    if last_newline == -1:
        col = index + 1
    else:
        col = index - last_newline
    return line, max(col, 1)


def lint_sql(sql: str, dialect: str) -> list[Diagnostic]:
    diagnostics: list[Diagnostic] = []

    try:
        parse_one(sql, read=dialect)
    except ParseError as exc:
        details = getattr(exc, 'errors', None) or []
        if details:
            for detail in details:
                line = int(detail.get('line') or 1)
                col = int(detail.get('col') or 1)
                diagnostics.append(
                    Diagnostic(
                        severity='error',
                        message=detail.get('description') or str(exc),
                        line=line,
                        start_col=col,
                        end_col=col + 1,
                        code='E001',
                    )
                )
        else:
            diagnostics.append(
                Diagnostic(
                    severity='error',
                    message=str(exc),
                    line=1,
                    start_col=1,
                    end_col=2,
                    code='E001',
                )
            )

    for rule in WARNING_RULES:
        for match in rule.pattern.finditer(sql):
            line, col = _line_col_from_index(sql, match.start())
            diagnostics.append(
                Diagnostic(
                    severity='warning',
                    message=rule.message,
                    line=line,
                    start_col=col,
                    end_col=col + max(1, match.end() - match.start()),
                    code=rule.code,
                )
            )

    return diagnostics
