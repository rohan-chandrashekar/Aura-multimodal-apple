# Resume Bullets

Interview-defensible bullets with measured numbers only. Updated each phase.

## Aura — On-Device Multimodal Accessibility Assistant

- Built a real-time hearing-mode captioning pipeline using AVAudioEngine and SFSpeechRecognizer (on-device, requiresOnDeviceRecognition = true) with zero audio written to disk and zero network bytes sent
- Measured 7.1% word error rate on clean speech (28-word reference, on-device recognition, Intel i5)
- Integrated a pretrained speech enhancement model (Facebook DNS48, 18.9M params) converted to Core ML (36 MB .mlpackage) via PyTorch tracing + coremltools
- Enhancement delivers +11.6 dB SNR gain at 0 dB input noise; WER halved at moderate noise (35.7% → 17.9% at 10 dB) but degrades at severe noise (0–5 dB) due to model artifacts — a documented divergence between signal-level and ASR-level improvement
- Enhancement model latency: 1149 ms per 4-second chunk on Intel CPU (faster than real-time)
- Built automated evaluation pipeline: Python scripts generate noisy test audio at controlled SNR levels, Core ML model enhances, Swift evaluator runs on-device ASR on all conditions and reports WER
