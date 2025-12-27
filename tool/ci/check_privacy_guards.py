#!/usr/bin/env python3
import pathlib
import re
import sys

REQUIRED_USAGE = "LandmarkPrivacyFilter"
BIO_TRACKING = pathlib.Path("lib/services/ui/bio_tracking_service.dart")

RAW_VIDEO_PATTERNS = (
    re.compile(r"^\s*import\s+['\"]dart:io['\"]", re.MULTILINE),
    re.compile(r"\bFile\s*\(", re.MULTILINE),
    re.compile(r"\bwriteAsBytes\s*\(", re.MULTILINE),
    re.compile(r"\bwriteAsString\s*\(", re.MULTILINE),
)

VIDEO_EXTENSION_RE = re.compile(r"\.(mp4|mov|avi|mkv|webm|m4v|hevc)\b", re.IGNORECASE)

FORBIDDEN_DIRS = [
    pathlib.Path("lib/core"),
    pathlib.Path("lib/services"),
    pathlib.Path("lib/services/ui"),
    pathlib.Path("lib/screens"),
]


def main() -> int:
    failures = []

    if BIO_TRACKING.exists():
        contents = BIO_TRACKING.read_text(encoding="utf-8")
        if REQUIRED_USAGE not in contents:
            failures.append("BioTrackingService must apply LandmarkPrivacyFilter.")

    scanned_files = set()
    for directory in FORBIDDEN_DIRS:
        if not directory.exists():
            continue
        for file in directory.rglob("*.dart"):
            scanned_files.add(file)
    for file in sorted(scanned_files):
        contents = file.read_text(encoding="utf-8")
        if VIDEO_EXTENSION_RE.search(contents):
            failures.append(
                f"Video extension reference found in forbidden zone: {file}."
            )
        for pattern in RAW_VIDEO_PATTERNS:
            if pattern.search(contents):
                failures.append(
                    f"Raw video persistence pattern '{pattern.pattern}' found in {file}."
                )

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
