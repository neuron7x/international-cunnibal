#!/usr/bin/env python3
import hashlib
import pathlib
import sys
import urllib.error
import urllib.request

MODEL_URL = "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task"
OUTPUT = pathlib.Path(__file__).resolve().parent.parent / "assets" / "models" / "face_landmark.tflite"
# Set to known good hash to enable verification when available.
EXPECTED_SHA256 = None


def download_model() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    print(f"Downloading model from {MODEL_URL}...")
    try:
        urllib.request.urlretrieve(MODEL_URL, OUTPUT)
    except urllib.error.URLError as exc:
        print(f"Network error downloading model: {exc}", file=sys.stderr)
        sys.exit(1)

    if EXPECTED_SHA256:
        with open(OUTPUT, "rb") as f:
            sha256 = hashlib.sha256(f.read()).hexdigest()
        if sha256 != EXPECTED_SHA256:
            print("Checksum mismatch!", file=sys.stderr)
            sys.exit(1)

    print(f"✓ Model downloaded to {OUTPUT}")


if __name__ == "__main__":
    download_model()
