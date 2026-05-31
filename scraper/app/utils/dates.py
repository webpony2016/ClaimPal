import re
from datetime import date

from dateutil import parser as date_parser

DATE_PATTERNS = (
    re.compile(
        r"(?i)(?:deadline|claim deadline|submit by|must submit by|file by)[:\s-]*"
        r"([A-Za-z]+\s+\d{1,2},\s+\d{4}|\d{4}-\d{2}-\d{2}|\d{1,2}/\d{1,2}/\d{4})"
    ),
    re.compile(r"\b([A-Za-z]+\s+\d{1,2},\s+\d{4})\b"),
    re.compile(r"\b(\d{4}-\d{2}-\d{2})\b"),
    re.compile(r"\b(\d{1,2}/\d{1,2}/\d{4})\b"),
)


def parse_date_text(value: str) -> date | None:
    try:
        return date_parser.parse(value, fuzzy=True).date()
    except (ValueError, OverflowError, TypeError):
        return None


def extract_date_candidates(text: str) -> list[date]:
    seen: set[date] = set()
    results: list[date] = []

    for pattern in DATE_PATTERNS:
        for match in pattern.finditer(text):
            parsed = parse_date_text(match.group(1))
            if parsed and parsed not in seen:
                seen.add(parsed)
                results.append(parsed)

    return results


def find_deadline(text: str) -> date | None:
    for match in DATE_PATTERNS[0].finditer(text):
        parsed = parse_date_text(match.group(1))
        if parsed is not None:
            return parsed

    candidates = extract_date_candidates(text)
    if not candidates:
        return None

    return candidates[0]
