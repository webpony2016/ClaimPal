import re
from decimal import Decimal, InvalidOperation

TARGETED_PATTERNS = (
    re.compile(
        r"(?i)(?:up to|maximum payout(?: of)?|max payout(?: of)?)\s*(?:USD|CAD|\$)?\s*(\d+(?:,\d{3})*(?:\.\d{1,2})?)"
    ),
    re.compile(
        r"(?i)(?:USD|CAD|\$)\s*(\d+(?:,\d{3})*(?:\.\d{1,2})?)"
    ),
    re.compile(r"(?i)(\d+(?:,\d{3})*(?:\.\d{1,2})?)\s*(?:USD|CAD)"),
)


def parse_money_text(value: str) -> Decimal | None:
    normalized = value.replace(",", "").strip()
    try:
        return Decimal(normalized)
    except (InvalidOperation, ValueError):
        return None


def extract_money_candidates(text: str) -> list[Decimal]:
    results: list[Decimal] = []
    seen: set[Decimal] = set()

    for pattern in TARGETED_PATTERNS:
        for match in pattern.finditer(text):
            parsed = parse_money_text(match.group(1))
            if parsed is not None and parsed not in seen:
                seen.add(parsed)
                results.append(parsed)

    return results


def find_max_payout(text: str) -> Decimal | None:
    candidates = extract_money_candidates(text)
    if not candidates:
        return None
    if len(candidates) == 1:
        return candidates[0]

    targeted_candidates = []
    for pattern in TARGETED_PATTERNS[:1]:
        for match in pattern.finditer(text):
            parsed = parse_money_text(match.group(1))
            if parsed is not None:
                targeted_candidates.append(parsed)

    unique_targeted = list(dict.fromkeys(targeted_candidates))
    if len(unique_targeted) == 1:
        return unique_targeted[0]

    return None
