import os
import json
import shutil
import numpy as np
import coremltools as ct

try:
    import soundfile as sf
except ImportError:
    raise ImportError("pip install soundfile")

ACCENT_DIR = "test_accents"
MITIGATED_DIR = "test_accents_mitigated"
MODEL_PATH = "models/SpeechEnhancer.mlpackage"
TARGET_SR = 16000
CHUNK_SAMPLES = TARGET_SR * 4


def enhance_audio(model, audio, sr):
    if sr != TARGET_SR:
        from scipy.signal import resample
        audio = resample(audio, int(len(audio) * TARGET_SR / sr)).astype(np.float32)
        sr = TARGET_SR

    length = len(audio)
    padded_length = ((length + CHUNK_SAMPLES - 1) // CHUNK_SAMPLES) * CHUNK_SAMPLES
    padded = np.zeros(padded_length, dtype=np.float32)
    padded[:length] = audio

    enhanced = np.zeros(padded_length, dtype=np.float32)
    for start in range(0, padded_length, CHUNK_SAMPLES):
        chunk = padded[start:start + CHUNK_SAMPLES].reshape(1, 1, CHUNK_SAMPLES)
        out = model.predict({"audio": chunk})["enhanced"]
        enhanced[start:start + CHUNK_SAMPLES] = out.flatten()

    return enhanced[:length], sr


def main():
    os.makedirs(MITIGATED_DIR, exist_ok=True)

    print("Loading enhancement model...")
    model = ct.models.MLModel(MODEL_PATH)

    labels_path = os.path.join(ACCENT_DIR, "accent_labels.json")
    with open(labels_path) as f:
        labels = json.load(f)

    print("Applying speech enhancement to accent audio...\n")
    for entry in labels:
        filename = entry["file"]
        src = os.path.join(ACCENT_DIR, filename)
        dst = os.path.join(MITIGATED_DIR, filename)

        audio, sr = sf.read(src)
        if audio.ndim > 1:
            audio = audio[:, 0]
        audio = audio.astype(np.float32)

        enhanced, new_sr = enhance_audio(model, audio, sr)
        sf.write(dst, enhanced, new_sr)
        print(f"  {filename}: enhanced ({sr} Hz -> {new_sr} Hz)")

    shutil.copy(labels_path, os.path.join(MITIGATED_DIR, "accent_labels.json"))
    print(f"\nMitigated audio saved to {MITIGATED_DIR}/")
    print("Run: swift run Aura --fairness-speech test_accents_mitigated")


if __name__ == "__main__":
    main()
