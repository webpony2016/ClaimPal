import hashlib
import re
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

TRACKING_QUERY_PREFIXES = ("utm_", "fbclid", "gclid", "mc_", "ref")
WHITESPACE_RE = re.compile(r"\s+")


def normalize_text(value: str) -> str:
    collapsed = WHITESPACE_RE.sub(" ", value.strip())
    return collapsed.casefold()


def canonicalize_url(url: str) -> str:
    split = urlsplit(url.strip())
    filtered_query = [
        (key, value)
        for key, value in parse_qsl(split.query, keep_blank_values=True)
        if not any(key.casefold().startswith(prefix) for prefix in TRACKING_QUERY_PREFIXES)
    ]
    normalized_path = split.path.rstrip("/") or "/"
    normalized_query = urlencode(sorted(filtered_query))
    return urlunsplit(
        (
            split.scheme.casefold(),
            split.netloc.casefold(),
            normalized_path,
            normalized_query,
            "",
        )
    )


def build_content_fingerprint(source: str, title: str, body: str) -> str:
    return "\n".join(
        [
            normalize_text(source),
            normalize_text(title),
            normalize_text(body),
        ]
    )


def compute_content_hash(source: str, title: str, body: str) -> str:
    fingerprint = build_content_fingerprint(source, title, body)
    digest = hashlib.sha256(fingerprint.encode("utf-8")).hexdigest()
    return f"sha256:{digest}"
