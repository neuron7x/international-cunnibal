from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BIB_DIR = ROOT / "docs" / "bibliography"
ARCHIVE_DIR = ROOT / "docs" / "archive"
CANONICAL_FILE = BIB_DIR / "REFERENCES.bib"


ENTRY_RE = re.compile(r"@\w+\s*{\s*([^,]+)", re.IGNORECASE)
DOI_RE = re.compile(r"doi\s*=\s*[{\"]([^}\"]+)[}\"]?", re.IGNORECASE)


def find_extra_bib_files() -> list[Path]:
    extras: list[Path] = []
    for path in ROOT.rglob("*.bib"):
        if ARCHIVE_DIR in path.parents:
            continue
        if BIB_DIR in path.parents and path.name == CANONICAL_FILE.name:
            continue
        extras.append(path)
    return extras


def collect_dois(bib_file: Path) -> list[tuple[str, str]]:
    dois: list[tuple[str, str]] = []
    current_key: str | None = None
    for line in bib_file.read_text(encoding="utf-8").splitlines():
        entry_match = ENTRY_RE.search(line)
        if entry_match:
            current_key = entry_match.group(1).strip()

        doi_match = DOI_RE.search(line)
        if doi_match:
            doi = doi_match.group(1).strip()
            dois.append((doi, current_key or bib_file.name))
    return dois


def check_duplicate_dois(bib_files: list[Path]) -> list[str]:
    collisions: list[str] = []
    seen: dict[str, set[str]] = {}

    for bib_file in bib_files:
        for doi, key in collect_dois(bib_file):
            seen.setdefault(doi.lower(), set()).add(key)

    for doi, keys in seen.items():
        if len(keys) > 1:
            collisions.append(f"Duplicate DOI {doi} in entries: {', '.join(sorted(keys))}")
    return collisions


def main() -> int:
    errors: list[str] = []

    if not CANONICAL_FILE.exists():
        errors.append(f"Missing canonical bibliography file: {CANONICAL_FILE}")

    extras = find_extra_bib_files()
    if extras:
        errors.append(
            "Found unexpected .bib files outside docs/bibliography (archive allowed): "
            + ", ".join(str(p) for p in sorted(extras))
        )

    bib_files = [CANONICAL_FILE] if CANONICAL_FILE.exists() else []
    duplicate_dois = check_duplicate_dois(bib_files)
    if duplicate_dois:
        errors.extend(duplicate_dois)

    if errors:
        print("Bibliography validation failed:")
        for err in errors:
            print(f"- {err}")
        return 1

    print("Bibliography validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
