import json
import os
import subprocess
import numpy as np

try:
    import soundfile as sf
    from PIL import Image, ImageDraw, ImageFont, ImageEnhance
except ImportError:
    print("Install: pip install soundfile pillow")
    raise

REFERENCE_TEXT = "The quick brown fox jumps over the lazy dog. Technology makes the world a smaller place. Please turn left at the next intersection and continue for two miles."

ACCENT_DIR = "test_accents"
LIGHTING_DIR = "test_lighting"

VOICES = [
    ("Samantha", "en_US", "US_female"),
    ("Fred", "en_US", "US_male"),
    ("Daniel", "en_GB", "GB_male"),
    ("Karen", "en_AU", "AU_female"),
    ("Moira", "en_IE", "IE_female"),
    ("Rishi", "en_IN", "IN_male"),
]

BRIGHTNESS_LEVELS = [
    ("very_dark", 0.2),
    ("dark", 0.5),
    ("normal", 1.0),
    ("bright", 1.8),
    ("very_bright", 2.5),
]

OCR_TEXT_LINES = [
    "EMERGENCY EXIT",
    "Push Bar to Open",
    "Alarm Will Sound",
]


def generate_accent_audio():
    os.makedirs(ACCENT_DIR, exist_ok=True)
    labels = []

    for voice_name, locale, label in VOICES:
        filename = f"{label}.wav"
        aiff_path = os.path.join(ACCENT_DIR, f"{label}.aiff")
        wav_path = os.path.join(ACCENT_DIR, filename)

        print(f"  Generating {label} ({voice_name}, {locale})...")
        subprocess.run(["say", "-v", voice_name, "-o", aiff_path, REFERENCE_TEXT], check=True)

        audio, sr = sf.read(aiff_path)
        if audio.ndim > 1:
            audio = audio[:, 0]
        sf.write(wav_path, audio.astype(np.float32), sr)
        os.remove(aiff_path)

        labels.append({
            "file": filename,
            "voice": voice_name,
            "locale": locale,
            "accent": label,
            "reference": REFERENCE_TEXT,
        })

    with open(os.path.join(ACCENT_DIR, "accent_labels.json"), "w") as f:
        json.dump(labels, f, indent=2)

    print(f"  Created {len(labels)} accent audio files in {ACCENT_DIR}/")


def generate_lighting_images():
    os.makedirs(LIGHTING_DIR, exist_ok=True)

    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 36)
    except Exception:
        font = ImageFont.load_default()

    base_img = Image.new("RGB", (640, 480), (240, 240, 240))
    draw = ImageDraw.Draw(base_img)
    y = 80
    for line in OCR_TEXT_LINES:
        draw.text((60, y), line, fill=(20, 20, 20), font=font)
        y += 60

    labels = []
    for level_name, brightness_factor in BRIGHTNESS_LEVELS:
        filename = f"{level_name}.jpg"
        path = os.path.join(LIGHTING_DIR, filename)

        enhancer = ImageEnhance.Brightness(base_img)
        adjusted = enhancer.enhance(brightness_factor)
        adjusted.save(path)

        labels.append({
            "file": filename,
            "brightness": brightness_factor,
            "level": level_name,
            "expected_text": OCR_TEXT_LINES,
        })

    with open(os.path.join(LIGHTING_DIR, "lighting_labels.json"), "w") as f:
        json.dump(labels, f, indent=2)

    print(f"  Created {len(labels)} brightness-varied images in {LIGHTING_DIR}/")


def generate_mitigated_images():
    mitigated_dir = LIGHTING_DIR + "_mitigated"
    os.makedirs(mitigated_dir, exist_ok=True)

    labels_path = os.path.join(LIGHTING_DIR, "lighting_labels.json")
    with open(labels_path) as f:
        labels = json.load(f)

    mitigated_labels = []
    for entry in labels:
        src_path = os.path.join(LIGHTING_DIR, entry["file"])
        img = Image.open(src_path)

        brightness = ImageEnhance.Brightness(img)
        contrast = ImageEnhance.Contrast(img)

        if entry["brightness"] < 0.8:
            img = brightness.enhance(1.0 / entry["brightness"] * 0.9)
            img = ImageEnhance.Contrast(img).enhance(1.3)
        elif entry["brightness"] > 1.5:
            img = brightness.enhance(1.0 / entry["brightness"] * 1.1)
            img = ImageEnhance.Contrast(img).enhance(1.2)

        out_path = os.path.join(mitigated_dir, entry["file"])
        img.save(out_path)

        mitigated_labels.append({
            "file": entry["file"],
            "brightness": entry["brightness"],
            "level": entry["level"] + "_mitigated",
            "expected_text": entry["expected_text"],
        })

    with open(os.path.join(mitigated_dir, "lighting_labels.json"), "w") as f:
        json.dump(mitigated_labels, f, indent=2)

    print(f"  Created {len(mitigated_labels)} mitigated images in {mitigated_dir}/")


def main():
    print("Generating fairness evaluation data...\n")

    print("Accent audio (speech WER across accents):")
    generate_accent_audio()

    print("\nLighting images (OCR across brightness):")
    generate_lighting_images()

    print("\nMitigated lighting images (brightness normalization):")
    generate_mitigated_images()

    print("\nNext steps:")
    print("  1. swift run Aura --fairness-speech test_accents")
    print("  2. swift run Aura --fairness-vision test_lighting")
    print("  3. swift run Aura --fairness-vision test_lighting_mitigated")
    print("  4. python3 scripts/analyze_fairness.py")


if __name__ == "__main__":
    main()
