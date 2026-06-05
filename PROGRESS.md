# Progress

## Current status
Phase 4 complete. Scripted task evaluation, significance testing, and fairness audit all measured.

## Phase checklist
- [x] Phase 0 — Hearing-mode caption spine (mic -> on-device ASR -> captions)
- [x] Phase 1 — Speech enhancement in noise
- [x] Phase 2 — Vision-mode scene aid (camera -> detection + OCR -> spoken description)
- [x] Phase 3 — Multimodal fusion (sound events + visual context)
- [x] Phase 4 — Interactive evaluation + fairness audit
- [ ] Phase 5 — Demo video + final docs

## Hardware
MacBook Pro (i5-1038NG7, Intel, 16 GB RAM, macOS 26.5.1). Core ML on CPU/GPU. Will re-measure on M-series.

## Measured numbers

### Phase 0 (clean speech, Intel)
- WER: 7.1%, caption latency: mean 5672 ms
- Audio files written: 0, network bytes: 0

### Phase 1 (speech enhancement, Intel)
- Model: Facebook DNS48, 18.9M params, 36 MB Core ML
- SNR gain: +11.6/+9.2/+7.1 dB at 0/5/10 dB
- WER: clean 7.1%, enhanced at 10 dB: 17.9%

### Phase 2 (vision mode, Intel, live camera)
- YOLOv8n, 3.2M params, 6.2 MB Core ML
- OCR: F1 91.7%, 100% recall; latency: 282 ms; FPS: 6.2

### Phase 3 (multimodal fusion, Intel)
- Sound detection: speech 100%; fusion latency <1 ms (sound only), ~282 ms with vision
- On-device confirmed

### Phase 4 (evaluation + fairness)
- Task completion rate: 100% (11/11 tasks)
- Time-on-task: mean 2812 ms, median 2454 ms
- Quality score: 92.5% ± 11.8%
- SUS: framework built, awaiting user questionnaire

**Speech fairness (WER across accents):**
| Accent | Before | After enhancement |
|--------|--------|-------------------|
| US female | 7.1% | 7.1% |
| US male (Fred) | 42.9% | 42.9% |
| GB male | 7.1% | 7.1% |
| AU female | 10.7% | 10.7% |
| IE female | 7.1% | 7.1% |
| IN male | 7.1% | 7.1% |
| Disparity | 35.7 pp | 35.7 pp |

Root cause: robotic voice quality, not noise. Enhancement targets noise → no disparity reduction.

**Vision fairness (OCR across lighting):**
- 100% recall at all 5 brightness levels (0.2× to 2.5×)
- Disparity: 0 pp before and after mitigation

**Significance testing:**
- Kruskal-Wallis across accents: H=5.00, p=0.42 (n=1 per group)
- Wilcoxon on vision mitigation: W=0.00, p=1.00 (no change needed)

## Known issues
- Intel Mac, not Apple Silicon.
- Speech enhancement doesn't mitigate voice-quality disparity.
- Fred (robotic) voice has 42.9% WER — known open problem.
- SUS requires human participant ratings.

## Next action
Phase 5: Demo + final docs. Screen-recordable demo, finalize README, RESUME_BULLETS, create DEMO.md with LinkedIn post and 30–60s video script.
