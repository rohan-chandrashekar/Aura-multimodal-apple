# Progress

## Current status
All phases complete. Project ready for demo recording and interview.

## Phase checklist
- [x] Phase 0 — Hearing-mode caption spine (mic -> on-device ASR -> captions)
- [x] Phase 1 — Speech enhancement in noise
- [x] Phase 2 — Vision-mode scene aid (camera -> detection + OCR -> spoken description)
- [x] Phase 3 — Multimodal fusion (sound events + visual context)
- [x] Phase 4 — Interactive evaluation + fairness audit
- [x] Phase 5 — Demo video + final docs

## Hardware
MacBook Pro (i5-1038NG7, Intel, 16 GB RAM, macOS 26.5.1). Core ML on CPU/GPU. Re-measure on M-series for final benchmarks.

## All measured numbers

| Metric | Value |
|---|---|
| Clean speech WER | 7.1% |
| Caption latency (mean) | 5672 ms |
| SNR gain at 0 dB | +11.6 dB |
| Enhanced WER at 10 dB | 17.9% (down from 35.7%) |
| Enhancement latency | 1149 ms / 4s chunk |
| OCR recall | 100% |
| Camera FPS (with YOLO) | 6.2 |
| Detection+OCR latency | 282 ms |
| Sound-event speech detection | 100% |
| Fusion latency | <1 ms (sound), ~282 ms (with vision) |
| Task completion | 100% (11/11) |
| Quality score | 92.5% ± 11.8% |
| WER disparity across accents | 35.7 pp |
| OCR disparity across lighting | 0 pp |
| Audio/frames written to disk | 0 |
| Network bytes | 0 |

## Next action
Record demo video using DEMO.md script. Push final commit. Prepare for interview.
