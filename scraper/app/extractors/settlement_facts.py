import re

US_HINTS = ("united states", "u.s.", " us ", "california", "federal trade commission")
CA_HINTS = ("canada", "canadian", "ontario", "quebec", "british columbia")
PROOF_REQUIRED_HINTS = (
    "proof of purchase required",
    "receipt required",
    "must provide proof",
    "documentation required",
)
NO_PROOF_REQUIRED_HINTS = (
    "no proof required",
    "proof not required",
    "without proof of purchase",
)
BRAND_SPLIT_RE = re.compile(r"(?i)\b(?:class action|settlement|lawsuit|claim|investigation)\b")


def extract_country_hint(text: str, *, source: str = "") -> str | None:
    lowered = f" {text.casefold()} "
    source_lower = source.casefold()

    if "canlii" in source_lower:
        return "CA"

    if any(hint in lowered for hint in CA_HINTS):
        return "CA"
    if any(hint in lowered for hint in US_HINTS):
        return "US"
    if "courtlistener" in source_lower or "top_class_actions" in source_lower:
        return "US"

    return None


def extract_proof_required(text: str) -> bool | None:
    lowered = text.casefold()
    if any(hint in lowered for hint in NO_PROOF_REQUIRED_HINTS):
        return False
    if any(hint in lowered for hint in PROOF_REQUIRED_HINTS):
        return True
    return None


def extract_brand_name_from_title(title: str) -> str:
    cleaned = title.strip()
    for separator in ("|", "-", ":"):
        if separator in cleaned:
            cleaned = cleaned.split(separator, 1)[0].strip()
    match = BRAND_SPLIT_RE.split(cleaned, maxsplit=1)
    brand = match[0].strip(" -–—") if match else cleaned
    return brand or cleaned


def summarize_eligibility(text: str, *, max_length: int = 280) -> str | None:
    paragraphs = [part.strip() for part in re.split(r"\n{2,}|(?<=[.!?])\s+", text) if part.strip()]
    for paragraph in paragraphs:
        lowered = paragraph.casefold()
        if any(token in lowered for token in ("eligible", "eligibility", "class members", "customers", "residents")):
            return paragraph[:max_length]
    if not paragraphs:
        return None
    return paragraphs[0][:max_length]
