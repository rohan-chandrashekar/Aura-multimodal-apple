# Progress

## Current status
Project scaffolded. Phase 0 not yet built.

## Phase checklist
- [ ] Phase 0 — Hearing-mode caption spine (mic -> on-device ASR -> captions)
- [ ] Phase 1 — Speech enhancement in noise
- [ ] Phase 2 — Vision-mode scene aid (camera -> detection + OCR -> spoken description)
- [ ] Phase 3 — Multimodal fusion (sound events + visual context)
- [ ] Phase 4 — Interactive evaluation + fairness audit
- [ ] Phase 5 — Demo video + final docs

## Measured numbers
None yet.

## Known issues
None yet.

## Next action
Build Phase 0: set up the Swift package, capture the mic with AVAudioEngine, run on-device recognition (requiresOnDeviceRecognition = true), show live captions, and measure caption latency + word error rate on a read sample. Confirm 0 audio files written.
