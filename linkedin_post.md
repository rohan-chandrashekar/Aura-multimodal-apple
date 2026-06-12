# LinkedIn Post

Single source of truth for the Aura LinkedIn post. All numbers are genuinely measured on an Apple M5 (macOS 26.5.1, Core ML on the Neural Engine).

Recommended: upload the demo video natively to LinkedIn (native video beats an external link in the feed), paste the post body below, and drop the GitHub link as the first comment if you want a cleaner body.

---

Built **Aura** — an on-device multimodal accessibility assistant for blind/low-vision and deaf/hard-of-hearing users, running entirely on Apple's native ML stack. No cloud. Nothing leaves the device.

The result I'm proudest of: I moved a pretrained speech-enhancement model onto the **M5 Neural Engine** and watched per-chunk latency drop from **1149 ms to 13 ms — an ~88× speedup** that turns a too-slow denoiser into a real-time one.

What it does:
- Describes the scene and reads text aloud — Vision + OCR + TTS, **29.4 FPS / 40 ms**
- Captions speech in real time — on-device ASR, **3.6% WER** on clean speech
- Enhances speech in noise — **+12.1 dB SNR gain** at 0 dB
- Fuses sound events with visual context for deaf users — SoundAnalysis + Vision

Built for trust:
- **0 bytes written to disk, 0 bytes sent over the network** (verifiable with `lsof`)
- Fairness audit across 6 English accents + 5 lighting conditions, with scipy significance testing
- Every number genuinely measured on-device — including the ones that weren't flattering

Stack: AVFoundation, Speech, SoundAnalysis, Vision, Core ML, AVSpeechSynthesizer. Two pretrained models converted to Core ML (Facebook DNS48 for speech enhancement, YOLOv8n for object detection).

GitHub: https://github.com/rohan-chandrashekar/Aura-multimodal-apple

#AppleML #Accessibility #CoreML #OnDevice #Privacy #SpeechRecognition #ComputerVision #MachineLearning

---

## Shorter variant (if you want a tighter post)

On-device multimodal accessibility assistant, built on Apple's native ML stack — describes scenes, reads text aloud, captions speech, and alerts deaf users to sounds. All local; nothing leaves the device.

Highlight: moving the speech denoiser to the **M5 Neural Engine** cut latency **1149 ms → 13 ms (~88×)** — real-time. Vision runs at **29.4 FPS**, ASR at **3.6% WER**, with **0 bytes to disk and 0 to the network**.

Every number measured, not estimated.

GitHub: https://github.com/rohan-chandrashekar/Aura-multimodal-apple

#AppleML #Accessibility #CoreML #OnDevice #Privacy
