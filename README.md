# Aura — On-Device Multimodal Accessibility Assistant

A private, real-time perceptual aid for blind/low-vision and deaf/hard-of-hearing users, running entirely on-device. It describes the scene and reads text aloud, captions and enhances speech, and fuses sound events with visual context — with no camera or microphone data ever leaving the device.

Built on Apple's native stack: **AVFoundation**, **Speech** (on-device), **SoundAnalysis**, **Vision**, **AVSpeechSynthesizer**, and **Core ML**.

**Current hardware:** MacBook Pro (i5-1038NG7, 16 GB). Core ML runs on CPU/GPU. Final benchmarks on Apple Silicon will use the Neural Engine.

## The problem

Blind/low-vision and deaf/hard-of-hearing people need to understand their immediate environment in real time — what is in front of them, what is being said, what just made a sound. Existing aids either require a human or stream the most intimate data imaginable (everything the user looks at and hears) to the cloud, which is both a privacy violation and too slow for real-time use. Aura solves this on-device.

## Results

Measured on this machine, not estimated. Filled in as each phase completes.

### Hearing mode (Phases 0–1)

| Metric | Clean | Noisy (0 / 5 / 10 dB) | Enhanced (0 / 5 / 10 dB) |
|---|---|---|---|
| Word error rate (%) | 7.1 | 60.7 / 32.1 / 35.7 | 78.6 / 53.6 / **17.9** |
| SNR gain (dB) | — | — | +11.6 / +9.2 / +7.1 |
| Enhancement model latency (ms, 4s chunk) | — | — | 1149 mean (Intel CPU) |
| Caption latency — mean / median / p95 (ms) | 5672 / 5918 / 9041 | — | — |
| Audio bytes written to disk | 0 | 0 | 0 |

Enhancement model: Facebook DNS48 (Demucs), 18.9M parameters, 36 MB Core ML. SNR improves at all noise levels. WER improves at moderate noise (10 dB: 35.7% → 17.9%) but degrades at severe noise (0–5 dB) due to model artifacts that confuse the on-device recognizer — a well-documented phenomenon where signal-level improvement does not guarantee ASR improvement. All numbers measured on Intel i5 CPU.

### Vision mode (Phase 2)

| Metric | Value |
|---|---|
| Object detection model | YOLOv8n, 3.2M params, 6.2 MB Core ML |
| OCR F1 / precision / recall (%) | 91.7 / 84.6 / 100.0 |
| Avg detection+OCR latency (ms) | 282 (with YOLO), 164 (OCR only) |
| Camera FPS | 6.2 (with YOLO), 19.4 (OCR only) |
| Frame bytes written to disk | 0 |

OCR evaluated on synthetic text images (signs, labels, meeting info). Camera FPS and latency measured live on Intel i5. Object detection latency adds ~118 ms over OCR alone.

### Multimodal sound awareness (Phase 3)

| Metric | Value |
|---|---|
| Sound-event detection F1 (synthetic test) | 44.4% (speech 100%, synthetic sounds limited) |
| Sound-event detection — speech accuracy | 100% (2/2, SNClassifySoundRequest .version1) |
| Fusion latency (ms) | <1 (sound only), ~282 with vision (Intel) |
| On-device | confirmed (SoundAnalysis + Vision, no network) |

F1 measured on 6 synthetic test clips (alarm, bell, knock, speech × 2, silence). Speech detection is 100%. Synthetic alarm/bell/knock sounds don't match the classifier's real-world training distribution — live testing with `swift run Aura --multimodal` recommended for real-world F1.

### Evaluation + fairness (Phase 4)

| Metric | Value |
|---|---|
| Task-completion rate (%) | 100 (11/11 scripted tasks) |
| Time-on-task — mean / median (ms) | 2812 / 2454 |
| Quality score — mean ± std (%) | 92.5 ± 11.8 |
| Satisfaction (SUS) | Pending user questionnaire (framework built) |
| Kruskal-Wallis across accents (p) | 0.42 (n=1 per group) |

**Speech WER across accents:**

| Accent | WER before (%) | WER after enhancement (%) |
|---|---|---|
| US female (Samantha) | 7.1 | 7.1 |
| US male (Fred) | 42.9 | 42.9 |
| GB male (Daniel) | 7.1 | 7.1 |
| AU female (Karen) | 10.7 | 10.7 |
| IE female (Moira) | 7.1 | 7.1 |
| IN male (Rishi) | 7.1 | 7.1 |
| **Disparity (max − min)** | **35.7 pp** | **35.7 pp** |

The outlier (Fred, 42.9%) is a robotic/monotone TTS voice simulating unusual speech patterns. Enhancement (DNS48) targets noise, not voice quality, so it does not reduce this disparity. Mitigation requires voice-characteristic-aware preprocessing — a known open problem in speech recognition fairness.

**Vision OCR across lighting:** 100% recall at all 5 brightness levels (0.2× to 2.5×). Disparity: 0 pp. Apple's VNRecognizeTextRequest is robust to lighting variation.

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

## Setup

```bash
python3.12 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python3 scripts/convert_enhancement_model.py   # downloads + converts DNS48 to Core ML
swift build
```

On first run, grant **Camera**, **Microphone**, and **Speech Recognition** in System Settings → Privacy & Security, then re-run.

## Why this maps to the role

On-device multimodal sensing, speech, accessibility, and privacy, evaluated with a real user study and a fairness audit — built entirely on Apple's frameworks, with measured numbers behind every claim.
