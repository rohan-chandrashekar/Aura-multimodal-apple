# Resume Bullets

Interview-defensible bullets with measured numbers only. Updated each phase.

## Aura — On-Device Multimodal Accessibility Assistant

- Built a real-time hearing-mode captioning pipeline using AVAudioEngine and SFSpeechRecognizer (on-device) with zero audio written to disk and zero network bytes sent; 7.1% WER on clean speech
- Speech enhancement (DNS48, 18.9M params Core ML) delivers +11.6 dB SNR gain and halves WER at moderate noise (35.7% → 17.9% at 10 dB); documented SNR-vs-WER divergence at severe noise
- Vision-mode scene aid: YOLOv8n (3.2M params, 6.2 MB Core ML) + VNRecognizeTextRequest OCR → spoken description via AVSpeechSynthesizer; 6.2 FPS, 282 ms latency, OCR 100% recall
- Multimodal fusion: SoundAnalysis (SNClassifySoundRequest) sound-event detection fused with Vision context for deaf/HH users; <1 ms fusion latency, 100% speech detection accuracy; all processing on-device
- End-to-end evaluation tooling: WER measurement with Levenshtein alignment, SNR gain analysis, labeled image evaluation (precision/recall/F1), sound classification F1, all automated via CLI flags
- Privacy invariant: all audio and video processed in memory, never written to disk, nothing leaves the device
