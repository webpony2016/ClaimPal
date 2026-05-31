from typing import Literal

from bs4 import BeautifulSoup


def extract_readable_content(html: str) -> tuple[str, Literal["markdown", "text"]]:
    soup = BeautifulSoup(html, "html.parser")

    for tag in soup(["script", "style", "noscript", "svg"]):
        tag.decompose()

    blocks: list[str] = []
    for tag in soup.find_all(["h1", "h2", "h3", "p", "li"]):
        text = tag.get_text(" ", strip=True)
        if not text:
            continue

        if tag.name == "h1":
            blocks.append(f"# {text}")
        elif tag.name == "h2":
            blocks.append(f"## {text}")
        elif tag.name == "h3":
            blocks.append(f"### {text}")
        elif tag.name == "li":
            blocks.append(f"- {text}")
        else:
            blocks.append(text)

    if blocks:
        content = "\n\n".join(blocks).strip()
        content_type: Literal["markdown", "text"] = (
            "markdown" if any(block.startswith(("#", "-")) for block in blocks) else "text"
        )
        return content, content_type

    fallback = soup.get_text("\n", strip=True).strip()
    return fallback, "text"
