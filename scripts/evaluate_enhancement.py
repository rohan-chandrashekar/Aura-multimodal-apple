import numpy as np
import soundfile as sf
import coremltools as ct
import subprocess
import os
import sys
import time

SAMPLE_RATE = 16000
MODEL_PATH = "models/SpeechEnhancer.mlpackage"
CHUNK_SAMPLES = SAMPLE_RATE * 4
TEST_DIR = "test_audio"
REFERENCE_TEXT = "The quick brown fox jumps over the lazy dog. Technology makes the world a smaller place. Please turn left at the next intersection and continue for two miles."


def generate_speech(text, output_path):
    subprocess.run(["say", "-o", output_path, text], check=True)


def compute_snr(signal, noise):
    sig_power = np.mean(signal ** 2)
    noise_power = np.mean(noise ** 2)
    if noise_power < 1e-10:
        return float("inf")
    return 10 * np.log10(sig_power / noise_power)


def add_noise(clean, snr_db):
    noise = np.random.randn(len(clean))
    clean_power = np.mean(clean ** 2)
    noise_power = clean_power / (10 ** (snr_db / 10))
    noise = noise * np.sqrt(noise_power)
    return clean + noise, noise


def enhance_audio(model, audio):
    length = len(audio)
    padded_length = ((length + CHUNK_SAMPLES - 1) // CHUNK_SAMPLES) * CHUNK_SAMPLES
    padded = np.zeros(padded_length, dtype=np.float32)
    padded[:length] = audio

    enhanced = np.zeros(padded_length, dtype=np.float32)
    for start in range(0, padded_length, CHUNK_SAMPLES):
        chunk = padded[start:start + CHUNK_SAMPLES]
        inp = chunk.reshape(1, 1, CHUNK_SAMPLES).astype(np.float32)
        out = model.predict({"audio": inp})["enhanced"]
        enhanced[start:start + CHUNK_SAMPLES] = out.flatten()

    return enhanced[:length]


def measure_latency(model, n_runs=20):
    dummy = np.random.randn(1, 1, CHUNK_SAMPLES).astype(np.float32)
    for _ in range(3):
        model.predict({"audio": dummy})

    times = []
    for _ in range(n_runs):
        start = time.perf_counter()
        model.predict({"audio": dummy})
        times.append((time.perf_counter() - start) * 1000)
    return times


def main():
    os.makedirs(TEST_DIR, exist_ok=True)

    print("Generating reference speech with macOS TTS...")
    clean_path = os.path.join(TEST_DIR, "clean.aiff")
    generate_speech(REFERENCE_TEXT, clean_path)
    clean, sr = sf.read(clean_path)
    if clean.ndim > 1:
        clean = clean[:, 0]
    if sr != SAMPLE_RATE:
        from scipy.signal import resample
        clean = resample(clean, int(len(clean) * SAMPLE_RATE / sr))
    clean = clean.astype(np.float32)
    peak = np.max(np.abs(clean))
    if peak > 0:
        clean = clean / peak * 0.9

    print(f"Clean audio: {len(clean)} samples ({len(clean)/SAMPLE_RATE:.1f}s)")

    print("Loading Core ML model...")
    model = ct.models.MLModel(MODEL_PATH)

    snr_levels = [0, 5, 10]
    results = []

    for target_snr in snr_levels:
        print(f"\n--- SNR {target_snr} dB ---")

        noisy, noise = add_noise(clean, target_snr)
        actual_snr_in = compute_snr(clean, noise)
        print(f"Input SNR: {actual_snr_in:.1f} dB")

        noisy_path = os.path.join(TEST_DIR, f"noisy_{target_snr}dB.wav")
        sf.write(noisy_path, noisy, SAMPLE_RATE)

        enhanced = enhance_audio(model, noisy)
        enhanced_path = os.path.join(TEST_DIR, f"enhanced_{target_snr}dB.wav")
        sf.write(enhanced_path, enhanced, SAMPLE_RATE)

        residual_noise = enhanced - clean[:len(enhanced)]
        snr_out = compute_snr(clean[:len(enhanced)], residual_noise)
        snr_gain = snr_out - actual_snr_in
        print(f"Output SNR: {snr_out:.1f} dB")
        print(f"SNR gain: {snr_gain:.1f} dB")

        results.append({
            "target_snr": target_snr,
            "snr_in": actual_snr_in,
            "snr_out": snr_out,
            "snr_gain": snr_gain,
        })

    print("\nMeasuring model latency (4s chunks)...")
    latencies = measure_latency(model)
    lat_mean = np.mean(latencies)
    lat_median = np.median(latencies)
    lat_p95 = np.percentile(latencies, 95)

    print(f"\n{'='*55}")
    print("ENHANCEMENT EVALUATION RESULTS")
    print(f"{'='*55}")
    print(f"\nModel: Facebook DNS48 (Demucs), 18.9M params, 36 MB Core ML")
    print(f"Chunk size: {CHUNK_SAMPLES/SAMPLE_RATE:.0f}s at {SAMPLE_RATE} Hz")
    print()
    print(f"{'Target SNR':>12} {'SNR In':>10} {'SNR Out':>10} {'Gain':>10}")
    print(f"{'-'*12:>12} {'-'*10:>10} {'-'*10:>10} {'-'*10:>10}")
    for r in results:
        print(f"{r['target_snr']:>10} dB {r['snr_in']:>8.1f} dB {r['snr_out']:>8.1f} dB {r['snr_gain']:>+8.1f} dB")

    print(f"\nModel latency (4s chunk, CPU):")
    print(f"  mean: {lat_mean:.0f} ms, median: {lat_median:.0f} ms, p95: {lat_p95:.0f} ms  (n={len(latencies)})")

    clean_path_wav = os.path.join(TEST_DIR, "clean.wav")
    sf.write(clean_path_wav, clean, SAMPLE_RATE)

    print(f"\nTest audio written to {TEST_DIR}/")
    print("Next: run `swift run Aura --evaluate test_audio` to measure WER on clean/noisy/enhanced")


if __name__ == "__main__":
    main()
