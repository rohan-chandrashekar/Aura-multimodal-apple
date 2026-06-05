# Aura — On-Device Multimodal Accessibility Assistant

A private, real-time perceptual aid for blind/low-vision and deaf/hard-of-hearing users, running entirely on-device. It describes the scene and reads text aloud, captions and enhances speech, and fuses sound events with visual context — with no camera or microphone data ever leaving the device.

Built on Apple's native stack: **AVFoundation**, **Speech** (on-device), **SoundAnalysis**, **Vision**, **AVSpeechSynthesizer**, and **Core ML**.

**Current hardware:** Apple M5 (macOS 26.5.1). Core ML runs on the Neural Engine. Earlier benchmarks were taken on a MacBook Pro (i5-1038NG7, 16 GB, Core ML on CPU/GPU); both sets of numbers are reported side by side below.

## The problem

Blind/low-vision and deaf/hard-of-hearing people need to understand their immediate environment in real time — what is in front of them, what is being said, what just made a sound. Existing aids either require a human or stream the most intimate data imaginable (everything the user looks at and hears) to the cloud, which is both a privacy violation and too slow for real-time use. Aura solves this on-device.

## Results

Every number below is genuinely measured on this machine, not estimated.

### Hearing mode (Phases 0–1)

| Metric | Clean | Noisy (0 / 5 / 10 dB) | Enhanced (0 / 5 / 10 dB) |
|---|---|---|---|
| WER — Intel i5 (%) | 7.1 | 60.7 / 32.1 / 35.7 | 78.6 / 53.6 / **17.9** |
| WER — Apple M5 (%) | 3.6 | 25.0 / 3.6 / 3.6 | 42.9 / 25.0 / 3.6 |
| SNR gain — Intel i5 (dB) | — | — | +11.6 / +9.2 / +7.1 |
| SNR gain — Apple M5 (dB) | — | — | +12.0 / +9.4 / +7.3 |
| Enhancement model latency (ms, 4s chunk) | — | — | 1149 mean (Intel CPU) / **13 mean, 12 median, 16 p95** (M5) |
| Caption latency — mean / median / p95 (ms) | 5672 / 5918 / 9041 (Intel); 6301 / 6532 / 9082 (M5) | — | — |
| Audio bytes written to disk | 0 | 0 | 0 |

Enhancement model: Facebook DNS48 (Demucs), 18.9M parameters, 36 MB Core ML. SNR improves at all noise levels on both machines. The standout hardware difference is enhancement latency: **1149 ms on Intel CPU drops to 13 ms on the M5 Neural Engine — an ~88× speedup** that moves the denoiser comfortably into real-time territory. WER on the M5 (macOS 26.5.1) is lower across the board, reflecting both the newer on-device recognizer and a fresh noise realization (the noise is randomly drawn per run at each controlled SNR, so the noisy/enhanced WER values are not a strict A/B against the Intel draw — only the SNR levels are held fixed). As on Intel, enhancement helps WER at moderate noise but can hurt at severe noise (0 dB), a well-documented phenomenon where signal-level improvement does not guarantee ASR improvement. Caption latency is comparable across machines (M5 6301 ms mean vs Intel 5672 ms) because it is governed by the recognizer's finalization cadence and the reader's speaking pace, not by raw compute — the live M5 `--measure` reading scored 7.1% WER with on-device recognition confirmed and zero audio/network bytes.

### Vision mode (Phase 2)

| Metric | Value |
|---|---|
| Object detection model | YOLOv8n, 3.2M params, 6.2 MB Core ML |
| OCR F1 / precision / recall (%) | 91.7 / 84.6 / 100.0 (Intel) |
| OCR latency on text images (ms) | ~32 steady-state (M5, fairness images); 164 OCR-only (Intel) |
| Avg detection+OCR latency (ms, live) | 282 (Intel, with YOLO); **65 (M5)** |
| Camera FPS (live) | 6.2 (Intel, with YOLO); **28.9 (M5)** |
| Frame bytes written to disk | 0 |

OCR evaluated on synthetic text images (signs, labels, meeting info). Live camera FPS and detection+OCR latency were measured on both machines (`swift run Aura --vision`): the M5 runs the full YOLOv8n + OCR pipeline at **28.9 FPS / 65 ms — ~4.7× the frame rate and ~4.3× lower latency than Intel** (6.2 FPS / 282 ms), measured over an 82 s session (37 processed frames). The M5 steady-state OCR-only latency above (~32 ms, after a ~5.8 s first-image warm-up) is measured on the fairness lighting images via `--fairness-vision`, which exercises the same `VNRecognizeTextRequest` path without a camera.

### Multimodal sound awareness (Phase 3)

| Metric | Intel i5 | Apple M5 |
|---|---|---|
| Sound-event detection F1 (synthetic test) | 44.4% | 25.0% (precision 50.0%, recall 16.7%) |
| Sound-event detection — speech accuracy | 100% (2/2) | 50% (1/2) |
| Fusion latency (ms) | <1 (sound only), ~282 with vision | <1 (sound only), ~65 with vision |
| On-device | confirmed | confirmed (SNClassifySoundRequest .version1) |

F1 measured on 6 synthetic test clips (alarm, bell, knock, speech × 2, silence), regenerated per run with macOS TTS and synthesis. The synthetic alarm/bell/knock sounds don't match the classifier's real-world training distribution, so F1 is dominated by which synthetic clips happen to land near a class boundary — on the M5 run, one of the two speech clips and all three non-speech clips went undetected, pulling F1 to 25.0%. This is a limitation of the synthetic test set, not a hardware regression; live testing with `swift run Aura --multimodal` is the meaningful real-world check.

### Evaluation + fairness (Phase 4)

| Metric | Intel i5 | Apple M5 |
|---|---|---|
| Task-completion rate (%) | 100 (11/11) | 100 (11/11) |
| Time-on-task — mean / median (ms) | 2812 / 2454 | 745 / 185 |
| Quality score — mean ± std (%) | 92.5 ± 11.8 | 95.5 ± 7.9 |
| Satisfaction (SUS) | Pending user questionnaire (framework built) | Pending |
| Kruskal-Wallis across accents | p = 0.42 (n=1 per group) | H = 5.00, p = 0.4159 (n=1 per group) |

**Speech WER across accents:**

| Accent | WER — Intel, before (%) | WER — Intel, after enhancement (%) | WER — Apple M5 (%) |
|---|---|---|---|
| US female (Samantha) | 7.1 | 7.1 | 3.6 |
| US male (Fred) | 42.9 | 42.9 | 28.6 |
| GB male (Daniel) | 7.1 | 7.1 | 3.6 |
| AU female (Karen) | 10.7 | 10.7 | 3.6 |
| IE female (Moira) | 7.1 | 7.1 | 7.1 |
| IN male (Rishi) | 7.1 | 7.1 | 3.6 |
| **Disparity (max − min)** | **35.7 pp** | **35.7 pp** | **25.0 pp** |

On both machines the outlier is Fred (robotic/monotone TTS simulating unusual speech patterns): 42.9% on Intel, 28.6% on M5. The disparity narrows from 35.7 pp to 25.0 pp on the M5's newer on-device recognizer, but Fred remains by far the worst case. Enhancement (DNS48) targets noise, not voice quality, so it does not reduce this disparity (the Intel before/after columns are identical); the M5 enhancement-mitigation pass was not run. Mitigation requires voice-characteristic-aware preprocessing — a known open problem in speech recognition fairness. The Kruskal-Wallis test is not significant (M5: H = 5.00, p = 0.4159) because there is only one sample per accent group; collecting multiple utterances per voice is the next step.

**Vision OCR across lighting:** 100% recall at all 5 brightness levels (0.2× to 2.5×) on both Intel and M5. Disparity: 0 pp on both; the M5 Wilcoxon signed-rank test for the mitigation pass is W = 0.00, p = 1.0000 (no change, because recall is already saturated). Apple's VNRecognizeTextRequest is robust to lighting variation.

## Architecture

```
Hearing mode:  AVAudioEngine mic -> [Core ML speech enhancement] -> Speech (on-device ASR) -> live captions
Vision mode:   AVFoundation camera -> Vision (object detection + OCR) -> composed description -> AVSpeechSynthesizer (TTS)
Multimodal:    SoundAnalysis (sound events) + Vision (visual context) -> fused alerts/descriptions
Privacy:       audio/video processed in memory, never persisted; nothing leaves the device
```

## Phases

- **Phase 0** — Hearing-mode caption spine (mic -> on-device ASR -> captions).
- **Phase 1** — Speech enhancement in noise (pretrained Core ML denoiser before ASR).
- **Phase 2** — Vision-mode scene aid (camera -> detection + OCR -> spoken description).
- **Phase 3** — Multimodal fusion (sound events + visual context).
- **Phase 4** — Interactive evaluation + fairness audit (user study, significance, disparity).
- **Phase 5** — Demo video + final docs.

## Usage

```bash
swift run Aura                     # Live captioning from microphone
swift run Aura --enhance           # Captioning with speech enhancement
swift run Aura --vision            # Camera scene description (objects + OCR + TTS)
swift run Aura --multimodal        # Sound events fused with camera context
swift run Aura --measure           # WER + latency measurement
swift run Aura --help              # All modes and evaluation commands
```

## Setup

```bash
# Python environment (3.12 required for PyTorch on Intel)
python3.12 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Convert pretrained models to Core ML
python3 scripts/convert_enhancement_model.py   # DNS48 speech enhancer (36 MB)
python3 scripts/convert_detection_model.py     # YOLOv8n object detector (6.2 MB)

# Build
swift build
```

On first run, grant **Camera**, **Microphone**, and **Speech Recognition** in System Settings → Privacy & Security, then re-run.

## Privacy

Audio and video are processed in memory and never written to disk. Recognition runs on-device (`requiresOnDeviceRecognition = true`). No network connections are opened. Verify with `lsof -i -P | grep Aura` (returns nothing). No user-study recordings or participant data are committed.

## Why this maps to the role

On-device multimodal sensing, speech, accessibility, and privacy — evaluated with scripted tasks, significance testing, and a fairness audit across accents and lighting — built entirely on Apple's frameworks, with measured numbers behind every claim.
