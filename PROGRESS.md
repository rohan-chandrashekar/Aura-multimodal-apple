# Progress

## Current status
Phase 1 complete. Speech enhancement model integrated and evaluated with full WER/SNR measurements.

## Phase checklist
- [x] Phase 0 — Hearing-mode caption spine (mic -> on-device ASR -> captions)
- [x] Phase 1 — Speech enhancement in noise
- [ ] Phase 2 — Vision-mode scene aid (camera -> detection + OCR -> spoken description)
- [ ] Phase 3 — Multimodal fusion (sound events + visual context)
- [ ] Phase 4 — Interactive evaluation + fairness audit
- [ ] Phase 5 — Demo video + final docs

## Hardware
MacBook Pro (i5-1038NG7, Intel, 16 GB RAM, macOS 26.5.1). Core ML runs on CPU/GPU, no Neural Engine. Will re-measure on M-series Mac.

## Measured numbers

### Phase 0 (clean speech, Intel)
- On-device recognition supported: true (locale en_IN)
- Word error rate: 7.1% (28-word reference; errors: "jumps"→"jumped", "two"→"2")
- Caption latency: mean 5672 ms, median 5918 ms, p95 9041 ms (n=23 segments)
- Audio files written to disk: 0
- Network bytes for recognition: 0

### Phase 1 (speech enhancement, Intel)
- Model: Facebook DNS48 (Demucs), 18.9M params, 36 MB Core ML
- SNR gain: +11.6 dB (0 dB input), +9.2 dB (5 dB), +7.1 dB (10 dB)
- WER table:

| Condition | WER (%) |
|-----------|---------|
| Clean | 7.1 |
| Noisy 0 dB | 60.7 |
| Noisy 5 dB | 32.1 |
| Noisy 10 dB | 35.7 |
| Enhanced 0 dB | 78.6 |
| Enhanced 5 dB | 53.6 |
| Enhanced 10 dB | 17.9 |

- Enhancement model latency: mean 1149 ms, median 1148 ms, p95 1159 ms (4s chunk, Intel CPU, n=20)
- Key finding: SNR improves at all levels, but ASR WER only improves at moderate noise (10 dB). At severe noise (0–5 dB), enhancement artifacts degrade recognition. This is a known divergence between signal-level and ASR-level metrics.

## Known issues
- Intel Mac, not Apple Silicon. Latency high, no ANE.
- `SFSpeechRecognizer.requestAuthorization()` crashes CLI tools. Using `authorizationStatus()` instead.
- Recognition task ~1 min timeout on silence; restart handles it.
- Enhancement model requires Python 3.12 (PyTorch not available for 3.13 on x86_64).
- en_IN locale recognizer hallucinates Hindi words on severely degraded audio — relevant for Phase 4 fairness audit.

## Next action
Phase 2: Vision-mode scene aid. AVFoundation camera → Vision object detection + VNRecognizeTextRequest OCR → composed spoken description via AVSpeechSynthesizer. No frames written to disk.
