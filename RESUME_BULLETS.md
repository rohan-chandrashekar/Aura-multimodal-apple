# Resume Bullets

Interview-defensible bullets with measured numbers only. Updated each phase.

## Aura — On-Device Multimodal Accessibility Assistant

- Built a real-time hearing-mode captioning pipeline using AVAudioEngine and SFSpeechRecognizer (on-device, requiresOnDeviceRecognition = true) with zero audio written to disk and zero network bytes sent
- Measured 7.1% word error rate on a read sample (28-word reference, on-device recognition, Intel i5 — errors: "jumps"→"jumped", "two"→"2")
- Caption latency: mean 5672 ms, median 5918 ms, p95 9041 ms on Intel CPU (no Neural Engine); expect significant improvement on Apple Silicon
- WER evaluation via Levenshtein-distance word alignment with automated per-segment latency tracking (mean, median, p95; n=23 segments)
