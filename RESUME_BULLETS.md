# Resume Bullets

Interview-defensible bullets. Every number is genuinely measured. Numbers are reported as **Apple M5 (macOS 26.5.1, Neural Engine)** with the earlier **Intel i5 (Core ML on CPU/GPU)** figures kept alongside.

## Aura — On-Device Multimodal Accessibility Assistant

**Hearing mode:** Built real-time captioning with AVAudioEngine → SFSpeechRecognizer (on-device, requiresOnDeviceRecognition = true), achieving 3.6% WER on clean speech on the M5 (7.1% on Intel). Integrated a pretrained speech enhancement model (Facebook DNS48, 18.9M params, converted to 36 MB Core ML) delivering +12.0 dB SNR gain at 0 dB (M5; +11.6 dB on Intel). Cut per-chunk enhancement latency from 1149 ms on Intel CPU to **13 ms on the M5 Neural Engine — an ~88× speedup** that puts the denoiser in real time. Zero audio written to disk, zero network bytes.

**Vision mode:** AVFoundation camera → YOLOv8n object detection (3.2M params, 6.2 MB Core ML) + VNRecognizeTextRequest OCR → spoken description via AVSpeechSynthesizer. Full live pipeline runs at **28.9 FPS / 65 ms on the M5 — ~4.7× the frame rate and ~4.3× lower latency than Intel** (6.2 FPS / 282 ms). OCR achieves 100% recall across 5 lighting conditions (0.2×–2.5× brightness, 0 pp disparity) on both machines.

**Multimodal fusion:** SoundAnalysis (SNClassifySoundRequest) sound-event detection fused with Vision context, producing combined spoken alerts for deaf/HH users. Fusion latency <1 ms (sound only). Speech-event detection on the synthetic test set is sensitive to clip generation (100% / 2-of-2 on Intel, 50% / 1-of-2 on the M5 run); live `--multimodal` testing is the real-world check. All processing on-device.

**Evaluation and fairness:** 100% task completion across 11 scripted tasks on both machines (quality score 95.5% ± 7.9% on M5, 92.5% ± 11.8% on Intel). Fairness audit across 6 English accents with scipy significance testing (Kruskal-Wallis, H = 5.00, p = 0.42, n=1 per group): WER disparity for robotic voices narrowed from 35.7 pp (Intel) to 25.0 pp (M5's newer recognizer); DNS48 mitigation leaves it unchanged, confirming root cause is voice quality not noise. Vision OCR shows zero disparity across lighting (Wilcoxon p = 1.0).

**Stack:** Swift, AVFoundation, Speech, SoundAnalysis, Vision, Core ML, AVSpeechSynthesizer, coremltools, scipy.
