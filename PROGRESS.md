# Progress

## Current status
Phase 3 complete. Multimodal fusion works end-to-end: sound events detected via SoundAnalysis, fused with camera context from Vision, producing combined spoken alerts.

## Phase checklist
- [x] Phase 0 — Hearing-mode caption spine (mic -> on-device ASR -> captions)
- [x] Phase 1 — Speech enhancement in noise
- [x] Phase 2 — Vision-mode scene aid (camera -> detection + OCR -> spoken description)
- [x] Phase 3 — Multimodal fusion (sound events + visual context)
- [ ] Phase 4 — Interactive evaluation + fairness audit
- [ ] Phase 5 — Demo video + final docs

## Hardware
MacBook Pro (i5-1038NG7, Intel, 16 GB RAM, macOS 26.5.1). Core ML on CPU/GPU. Will re-measure on M-series.

## Measured numbers

### Phase 0 (clean speech, Intel)
- WER: 7.1% (28-word reference)
- Caption latency: mean 5672 ms, median 5918 ms, p95 9041 ms
- Audio files written: 0, network bytes: 0

### Phase 1 (speech enhancement, Intel)
- Model: Facebook DNS48, 18.9M params, 36 MB Core ML
- SNR gain: +11.6 dB (0 dB), +9.2 dB (5 dB), +7.1 dB (10 dB)
- WER: clean 7.1%, noisy 60.7/32.1/35.7%, enhanced 78.6/53.6/17.9% (0/5/10 dB)
- Model latency: 1149 ms per 4s chunk (Intel CPU)

### Phase 2 (vision mode, Intel, live camera)
- Object detection model: YOLOv8n, 3.2M params, 6.2 MB Core ML
- OCR: F1 91.7%, precision 84.6%, recall 100%
- Avg detection+OCR latency: 282 ms (with YOLO), 164 ms (OCR only)
- Camera FPS: 6.2 (with YOLO), 19.4 (OCR only)

### Phase 3 (multimodal fusion, Intel)
- Sound classifier: SNClassifySoundRequest .version1 (Apple built-in, on-device)
- Sound F1 on synthetic test set: 44.4% (speech 100%, synthetic alarm/bell/knock limited)
- Alarm classified as "synthesizer" (correct for synthetic waveform, wrong vs label)
- Fusion latency: <1 ms (sound-only alert), ~282 ms (with vision processing)
- On-device confirmed: SoundAnalysis + Vision, no network
- Live test detected ambient sound ("water" at 35%) within 5.6 seconds

## Known issues
- Intel Mac, not Apple Silicon.
- Enhancement artifacts degrade ASR at severe noise.
- en_IN locale recognizer hallucinates Hindi on degraded audio.
- Synthetic test sounds don't match real-world classifier training distribution — speech works, alarm/bell/knock need real recordings for fair F1.
- Camera not accessible from CLI agent environment for automated testing.

## Next action
Phase 4: Interactive evaluation + fairness audit. Package modes as interactive prototype. Run scripted tasks measuring task-completion rate, time-on-task, satisfaction (SUS), with significance testing (scipy). Audit WER across accents and vision accuracy across lighting.
