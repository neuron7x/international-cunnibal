#!/usr/bin/env python3
import pathlib
import re
import sys

REQUIRED_USAGE = "LandmarkPrivacyFilter"
BIO_TRACKING = pathlib.Path("lib/services/bio_tracking_service.dart")

VIDEO_EXTENSION_REGEX = re.compile(
    r"\.(mp4|mov|avi|mkv|webm|h264|hevc|mpeg|mpg)\b",
    re.IGNORECASE,
)

RECORDING_API_PATTERNS = (
    "startVideoRecording",
    "stopVideoRecording",
    "recordVideo",
)

SCAN_DIRS = [pathlib.Path("lib/services"), pathlib.Path("lib/screens")]


def main() -> int:
    failures = []

    if BIO_TRACKING.exists():
        contents = BIO_TRACKING.read_text(encoding="utf-8")
        if REQUIRED_USAGE not in contents:
            failures.append("BioTrackingService must apply LandmarkPrivacyFilter.")

    for directory in SCAN_DIRS:
        if not directory.exists():
            continue
        for file in directory.rglob("*.dart"):
            contents = file.read_text(encoding="utf-8")
            if VIDEO_EXTENSION_REGEX.search(contents):
                failures.append(f"Raw video file extension found in {file}.")
            for pattern in RECORDING_API_PATTERNS:
                if pattern in contents:
                    failures.append(
                        f"Raw video recording API '{pattern}' found in {file}."
                    )

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
