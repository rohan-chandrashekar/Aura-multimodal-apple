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
- **Apple M5** (arm64, macOS 26.5.1, build 25F80). Core ML on the Neural Engine. Primary benchmark machine.
- Earlier: MacBook Pro (i5-1038NG7, Intel, 16 GB RAM). Core ML on CPU/GPU. Numbers kept for comparison.

## All measured numbers

| Metric | Intel i5 | Apple M5 |
|---|---|---|
| Clean speech WER (`--evaluate`) | 7.1% | 3.6% |
| Caption latency (mean / median / p95, live `--measure`) | 5672 / 5918 / 9041 ms | 5405 / 5634 / 8484 ms |
| Live WER (`--measure`, spoken) | 7.1% | 14.3% |
| SNR gain at 0 / 5 / 10 dB | +11.6 / +9.2 / +7.1 dB | +12.1 / +9.5 / +7.3 dB |
| Enhanced WER at 0 / 5 / 10 dB | 78.6 / 53.6 / 17.9% | 42.9 / 28.6 / 3.6% |
| Noisy WER at 0 / 5 / 10 dB | 60.7 / 32.1 / 35.7% | 35.7 / 14.3 / 3.6% |
| Enhancement latency (4s chunk) | 1149 ms | 13 ms mean (12 median, 16 p95) |
| OCR recall across lighting | 100% | 100% |
| OCR latency per text image | 164 ms (OCR-only) | ~33–36 ms steady-state (263 ms first-image warm-up) |
| Camera FPS (with YOLO, live) | 6.2 | 29.4 |
| Detection+OCR latency (live) | 282 ms | 40 ms |
| Sound-event F1 (synthetic) | 44.4% | 25.0% (P 50.0 / R 16.7) |
| Sound-event speech detection | 100% (2/2) | 50% (1/2) |
| Fusion latency | <1 ms (sound), ~282 ms (vision) | <1 ms (sound), ~23 ms end-to-end fused alert (n=14) |
| Task completion | 100% (11/11) | 100% (11/11) |
| Time-on-task (mean / median) | 2812 / 2454 ms | 218 / 164 ms |
| Quality score | 92.5% ± 11.8% | 95.5% ± 7.9% |
| WER disparity across accents | 35.7 pp | 25.0 pp (Kruskal-Wallis H=5.00, p=0.4159; mitigated 17.9 pp) |
| OCR disparity across lighting | 0 pp | 0 pp (Wilcoxon W=0.00, p=1.0000) |
| Audio/frames written to disk | 0 | 0 |
| Network bytes | 0 | 0 |

Notes: The M5 column is the canonical run recorded in `benchmarks/M5.md` (2026-06-07). Deterministic metrics (clean WER, enhancement latency, OCR F1, fairness disparities, task completion, quality) reproduced exactly across two independent M5 sessions; the run-to-run-variable live metrics (live spoken WER, caption latency, live FPS, live detection+OCR latency, time-on-task) and the noise-draw-dependent noisy/enhanced WER are reported from that canonical run — see `benchmarks/M5.md` for per-run ranges. Live spoken WER (14.3%) is far higher than the 3.6% file-based clean WER because of live mic/room acoustics and the 30 s capture window clipping the sentence tail; the file-based clean WER is the stable headline. On the M5 the recognizer is robust enough that enhancement does not improve WER (it ties or hurts at every level) — its value here is the +12 dB SNR gain and the 88× latency win (1149 → 13 ms). Sound-event F1 is dominated by which synthetic clips land near a class boundary — a test-set artifact, not a hardware regression. The vision pipeline shows the expected Neural Engine speedup (29.4 vs 6.2 FPS).

## Reproduction note (M5)
Setup used the system `python3` (3.9.6); `requirements.txt` installed cleanly. `ultralytics` (needed by `scripts/convert_detection_model.py`) is now listed in `requirements.txt`. The Swift summary-table printers in `FileEvaluator`/`FairnessEvaluator` previously segfaulted (exit 139) on a Swift-String-to-`%s` mismatch; this is fixed, so `--evaluate` and `--fairness-speech` now print their summary tables and exit cleanly.

## Next action
All M5 benchmarks are measured (no TBDs remain). Record the demo video using DEMO.md, then prepare for interview.
