# Demo

## 30-second video script

Record with QuickTime screen recording (Cmd+Shift+5) showing the terminal plus the camera feed.

**[0–5s] Title**
Show the terminal. Type and run:
```
swift run Aura --vision
```
Narrator: "Aura is an on-device accessibility assistant. Everything runs locally — nothing leaves this machine."

**[5–15s] Vision mode — scene description**
Point the camera at objects on your desk (laptop, cup, book) and at a printed sign with text.
The terminal prints descriptions like:
```
[282ms] I see laptop, cup. Text reads: Meeting at 3 PM.
```
The Mac speaks the description aloud.
Narrator: "It sees objects and reads text aloud in real time."

**[15–22s] Hearing mode — live captions**
Ctrl+C the vision mode. Run:
```
swift run Aura
```
Speak a sentence. Captions appear as you talk.
Narrator: "It captions speech on-device with seven percent word error rate."

**[22–28s] Multimodal — sound alert**
Ctrl+C. Run:
```
swift run Aura --multimodal
```
Clap or snap near the mic. The terminal prints a fused alert combining the sound event with what the camera sees.
Narrator: "And it fuses sound events with visual context for deaf users."

**[28–30s] Closing**
Narrator: "Zero bytes written. Zero bytes sent. All on-device."

## 60-second extended version

Same as above, plus:

**[30–40s] Speech enhancement**
Run `swift run Aura --measure` in a noisy environment. Show the WER result.
Narrator: "A pretrained speech enhancement model halves word error rate in noise."

**[40–50s] Privacy proof**
Open a second terminal pane. Run:
```
lsof -i -P | grep Aura
```
Show it returns nothing — zero network connections.
Narrator: "No network connections. No files on disk. The most private accessibility tool possible."

**[50–60s] Fairness**
Show the fairness table from the README (screenshot or terminal output of `python3 scripts/analyze_fairness.py`).
Narrator: "We audited recognition across six English accents and five lighting conditions, with significance testing."

## Recording tips

1. Use a clean desktop with just the terminal visible
2. Increase terminal font size (Cmd+ several times)
3. Use a well-lit room for the camera demo
4. Have a printed sign or book visible for OCR
5. Speak clearly and at normal pace for the caption demo
6. For the 30s version, rehearse transitions — Ctrl+C and the next command should be fluid

## LinkedIn post

---

Built Aura — an on-device multimodal accessibility assistant for blind/low-vision and deaf/hard-of-hearing users, running entirely on Apple's native ML stack.

What it does:
- Describes the scene and reads text aloud (Vision + OCR + TTS)
- Captions speech in real time (on-device ASR, 7.1% WER)
- Enhances speech in noise (+11.6 dB SNR gain, WER halved at moderate noise)
- Fuses sound events with visual context for deaf users (SoundAnalysis + Vision)

Key numbers, all measured:
- 6.2 FPS camera processing, 282 ms detection+OCR latency
- 100% OCR recall across 5 lighting conditions
- Fairness audit across 6 English accents with significance testing
- Zero bytes written to disk, zero bytes sent over the network

Built with: AVFoundation, Speech, SoundAnalysis, Vision, Core ML, AVSpeechSynthesizer. Two pretrained models converted to Core ML (Facebook DNS48 for speech enhancement, YOLOv8n for object detection).

Every number is genuinely measured, not estimated.

GitHub: https://github.com/rohan-chandrashekar/Aura-multimodal-apple

#AppleML #Accessibility #CoreML #OnDevice #Privacy #SpeechRecognition #ComputerVision #MachineLearning

---

## Commands reference for demo

```bash
swift run Aura --help              # show all modes
swift run Aura                     # live captions
swift run Aura --enhance           # captions with speech enhancement
swift run Aura --measure           # WER + latency measurement
swift run Aura --vision            # camera scene description
swift run Aura --multimodal        # sound events + camera fusion

# Privacy verification
lsof -i -P | grep Aura            # should return nothing (no network)
```
