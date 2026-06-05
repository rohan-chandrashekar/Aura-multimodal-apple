# Progress

## Current status
Phase 0 complete. Live captioning pipeline works end-to-end with measured WER and latency.

## Phase checklist
- [x] Phase 0 — Hearing-mode caption spine (mic -> on-device ASR -> captions)
- [ ] Phase 1 — Speech enhancement in noise
- [ ] Phase 2 — Vision-mode scene aid (camera -> detection + OCR -> spoken description)
- [ ] Phase 3 — Multimodal fusion (sound events + visual context)
- [ ] Phase 4 — Interactive evaluation + fairness audit
- [ ] Phase 5 — Demo video + final docs

## Hardware
MacBook Pro (i5-1038NG7, Intel, 16 GB RAM, macOS 26.5.1). Not Apple Silicon — Core ML runs on CPU/GPU, no Neural Engine. Will re-measure on M-series Mac.

## Measured numbers (Phase 0, Intel)
- On-device recognition supported: true (locale en_IN)
- Word error rate: 7.1% (28-word reference; errors: "jumps"→"jumped", "two"→"2")
- Caption latency: mean 5672 ms, median 5918 ms, p95 9041 ms (n=23 segments)
- Audio engine input: 48 kHz, 1 channel
- Audio files written to disk: 0
- Network bytes for recognition: 0

## Known issues
- Intel Mac, not Apple Silicon. Latency is high (~5.7s mean) because recognition runs on CPU without ANE. Expect improvement on M-series.
- `SFSpeechRecognizer.requestAuthorization()` crashes CLI tools (SIGABRT). Solved by checking `authorizationStatus()` synchronously.
- Recognition task has ~1 minute timeout on silence; `restart()` handles this for continuous captioning.

## Next action
Phase 1: insert a pretrained speech-enhancement/denoising model (converted to Core ML) before ASR. Measure WER on clean vs noisy vs enhanced audio, SNR gain in dB, and added model latency.
