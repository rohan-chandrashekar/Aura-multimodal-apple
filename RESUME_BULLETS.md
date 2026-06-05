# Resume Bullets

Interview-defensible bullets with measured numbers only. Updated each phase.

## Aura — On-Device Multimodal Accessibility Assistant

- Built a real-time hearing-mode captioning pipeline using AVAudioEngine and SFSpeechRecognizer (on-device, requiresOnDeviceRecognition = true) with zero audio written to disk and zero network bytes sent
- Measured 7.1% word error rate on clean speech; enhancement (DNS48, 18.9M params Core ML) delivers +11.6 dB SNR gain and halves WER at moderate noise (35.7% → 17.9% at 10 dB)
- Built vision-mode scene aid: AVFoundation camera → YOLOv8n object detection (3.2M params, 6.2 MB Core ML) + VNRecognizeTextRequest OCR → composed spoken description via AVSpeechSynthesizer
- Live camera: 6.2 FPS with detection+OCR at 282 ms average latency; OCR alone achieves 100% recall at 164 ms; object detection adds 118 ms overhead
- Automated evaluation pipelines: Python scripts for model conversion and SNR measurement; Swift evaluators for WER (audio) and detection+OCR accuracy (vision) on labeled test sets
- Privacy invariant: all audio and video processed in memory, never written to disk, nothing leaves the device
