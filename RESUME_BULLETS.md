# Resume Bullets

Interview-defensible bullets. Every number is genuinely measured.

## Aura — On-Device Multimodal Accessibility Assistant

**Hearing mode:** Built real-time captioning with AVAudioEngine → SFSpeechRecognizer (on-device, requiresOnDeviceRecognition = true), achieving 7.1% WER on clean speech. Integrated a pretrained speech enhancement model (Facebook DNS48, 18.9M params, converted to 36 MB Core ML) delivering +11.6 dB SNR gain and halving WER in moderate noise (35.7% → 17.9% at 10 dB SNR). Zero audio written to disk, zero network bytes.

**Vision mode:** AVFoundation camera → YOLOv8n object detection (3.2M params, 6.2 MB Core ML) + VNRecognizeTextRequest OCR → spoken description via AVSpeechSynthesizer. 6.2 FPS with 282 ms latency. OCR achieves 100% recall across 5 lighting conditions (0.2×–2.5× brightness, 0 pp disparity).

**Multimodal fusion:** SoundAnalysis (SNClassifySoundRequest) sound-event detection fused with Vision context, producing combined spoken alerts for deaf/HH users. Fusion latency <1 ms (sound only), ~282 ms with vision. 100% speech detection accuracy. All processing on-device.

**Evaluation and fairness:** 100% task completion across 11 scripted tasks (quality score 92.5% ± 11.8%). Fairness audit across 6 English accents with scipy significance testing (Kruskal-Wallis): identified 35.7 pp WER disparity for robotic voices; attempted DNS48 mitigation — disparity unchanged, confirming root cause is voice quality not noise. Vision OCR shows zero disparity across lighting.

**Stack:** Swift, AVFoundation, Speech, SoundAnalysis, Vision, Core ML, AVSpeechSynthesizer, coremltools, scipy.
