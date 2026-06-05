# Aura — On-Device Multimodal Accessibility Assistant

A private, real-time perceptual aid for blind/low-vision and deaf/hard-of-hearing users, running entirely on Apple Silicon. It describes the scene and reads text aloud, captions and enhances speech, and fuses sound events with visual context — with no camera or microphone data ever leaving the device.

Built on Apple's native stack: **AVFoundation**, **Speech** (on-device), **SoundAnalysis**, **Vision**, **AVSpeechSynthesizer**, and **Core ML** on the Neural Engine.

## The problem

Blind/low-vision and deaf/hard-of-hearing people need to understand their immediate environment in real time — what is in front of them, what is being said, what just made a sound. Existing aids either require a human or stream the most intimate data imaginable (everything the user looks at and hears) to the cloud, which is both a privacy violation and too slow for real-time use. Aura solves this on-device.

## Results

Measured on Apple Silicon, not estimated. Filled in as each phase completes.

### Hearing mode (Phases 0–1)

| Metric | Clean | Noisy | Enhanced |
|---|---|---|---|
| Word error rate (%) | _tbd_ | _tbd_ | _tbd_ |
| Caption latency (ms) | _tbd_ | — | _tbd_ |
| SNR gain (dB) | — | — | _tbd_ |
| Audio bytes written to disk | 0 | 0 | 0 |

### Vision mode (Phase 2)

| Metric | Value |
|---|---|
| Object detection accuracy (%) | _tbd_ |
| OCR accuracy (%) | _tbd_ |
| End-to-end latency (ms) | _tbd_ |
| FPS | _tbd_ |
| Frame bytes written to disk | 0 |

### Multimodal sound awareness (Phase 3)

| Metric | Value |
|---|---|
| Sound-event detection F1 | _tbd_ |
| Fusion latency (ms) | _tbd_ |

### Evaluation + fairness (Phase 4)

| Metric | Value |
|---|---|
| Task-completion rate (%) | _tbd_ |
| Satisfaction (SUS) | _tbd_ |
| Significance (p) | _tbd_ |
| WER disparity across accents — before / after | _tbd_ |

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
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
swift build
```

On first run, grant **Camera**, **Microphone**, and **Speech Recognition** in System Settings → Privacy & Security, then re-run.

## Why this maps to the role

On-device multimodal sensing, speech, accessibility, and privacy, evaluated with a real user study and a fairness audit — built entirely on Apple's frameworks, with measured numbers behind every claim.
