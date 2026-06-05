# Resume Bullets

Interview-defensible bullets with measured numbers only. Updated each phase.

## Aura — On-Device Multimodal Accessibility Assistant

- Built a real-time hearing-mode captioning pipeline using AVAudioEngine and SFSpeechRecognizer (on-device) with zero audio written to disk; 7.1% WER on clean speech, 100% task completion across 11 scripted evaluation tasks
- Speech enhancement (DNS48, 18.9M params Core ML) delivers +11.6 dB SNR gain and halves WER at moderate noise (35.7% → 17.9% at 10 dB); documented SNR-vs-WER divergence at severe noise
- Vision-mode scene aid: YOLOv8n (3.2M params, 6.2 MB Core ML) + VNRecognizeTextRequest OCR → spoken description; 6.2 FPS, 282 ms latency, OCR 100% recall across 5 lighting conditions (0.2×–2.5× brightness, 0 pp disparity)
- Multimodal fusion: SoundAnalysis sound-event detection fused with Vision context for deaf/HH users; <1 ms fusion latency, 100% speech detection; all processing on-device
- Fairness audit across 6 English accents (US/GB/AU/IE/IN): identified 35.7 pp WER disparity for robotic/monotone voice; attempted DNS48 enhancement mitigation — disparity unchanged, confirming root cause is voice quality not noise (a known open problem)
- Evaluation with scipy significance testing (Kruskal-Wallis, Wilcoxon); task completion rate 100%, quality score 92.5% ± 11.8%
- Privacy invariant: all audio and video processed in memory, never written to disk, nothing leaves the device
