import numpy as np
import json
import os
import subprocess

SAMPLE_RATE = 44100
TEST_DIR = "test_sounds"
os.makedirs(TEST_DIR, exist_ok=True)

try:
    import soundfile as sf
except ImportError:
    print("soundfile required: pip install soundfile")
    raise


def write_wav(filename, audio, sr=SAMPLE_RATE):
    path = os.path.join(TEST_DIR, filename)
    sf.write(path, audio, sr)
    return path


def generate_alarm(duration=3.0):
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration))
    freq_mod = 800 + 400 * np.sin(2 * np.pi * 3 * t)
    signal = 0.8 * np.sin(2 * np.pi * freq_mod * t / SAMPLE_RATE * 50)
    return signal.astype(np.float32)


def generate_bell(duration=2.0):
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration))
    freqs = [523, 659, 784]
    signal = np.zeros_like(t)
    for f in freqs:
        envelope = np.exp(-2 * t)
        signal += envelope * np.sin(2 * np.pi * f * t)
    signal = signal / np.max(np.abs(signal)) * 0.8
    return signal.astype(np.float32)


def generate_knock(duration=2.0):
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration))
    signal = np.zeros_like(t)
    for knock_time in [0.1, 0.4, 0.7]:
        idx_start = int(knock_time * SAMPLE_RATE)
        idx_end = min(idx_start + int(0.02 * SAMPLE_RATE), len(t))
        burst = np.random.randn(idx_end - idx_start) * 0.9
        burst *= np.exp(-np.linspace(0, 10, len(burst)))
        signal[idx_start:idx_end] = burst
    return signal.astype(np.float32)


def generate_speech(text, filename):
    aiff_path = os.path.join(TEST_DIR, filename.replace(".wav", ".aiff"))
    subprocess.run(["say", "-o", aiff_path, text], check=True)
    audio, sr = sf.read(aiff_path)
    if audio.ndim > 1:
        audio = audio[:, 0]
    wav_path = os.path.join(TEST_DIR, filename)
    sf.write(wav_path, audio.astype(np.float32), sr)
    os.remove(aiff_path)
    return wav_path


def generate_silence(duration=2.0):
    return np.zeros(int(SAMPLE_RATE * duration), dtype=np.float32)


print("Generating test sounds...")

write_wav("alarm.wav", generate_alarm())
print("  alarm.wav")

write_wav("bell.wav", generate_bell())
print("  bell.wav")

write_wav("knock.wav", generate_knock())
print("  knock.wav")

generate_speech("Hello, can anyone hear me? I need some help please.", "speech.wav")
print("  speech.wav")

generate_speech("Warning, the building must be evacuated immediately.", "speech_warning.wav")
print("  speech_warning.wav")

write_wav("silence.wav", generate_silence())
print("  silence.wav")

labels = [
    {"file": "alarm.wav", "expected": "alarm"},
    {"file": "bell.wav", "expected": "bell"},
    {"file": "knock.wav", "expected": "knock"},
    {"file": "speech.wav", "expected": "speech"},
    {"file": "speech_warning.wav", "expected": "speech"},
    {"file": "silence.wav", "expected": "silence"},
]

with open(os.path.join(TEST_DIR, "sound_labels.json"), "w") as f:
    json.dump(labels, f, indent=2)

print(f"\nCreated {len(labels)} test sounds + sound_labels.json in {TEST_DIR}/")
print("Run: swift run Aura --sound-eval test_sounds")
