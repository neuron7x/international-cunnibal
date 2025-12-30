import pathlib
import urllib.request

MODEL_URL = "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task"
OUTPUT = pathlib.Path(__file__).resolve().parent.parent / "assets" / "models" / "face_landmark.tflite"


def main() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    urllib.request.urlretrieve(MODEL_URL, OUTPUT)
    print(f"✓ Model downloaded: {OUTPUT}")


if __name__ == "__main__":
    main()
