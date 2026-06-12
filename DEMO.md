# Demo

All numbers below are the measured **Apple M5** figures (macOS 26.5.1, Core ML on the Neural Engine). Intel i5 comparisons live in `README.md`.

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
[40ms] I see laptop, cup. Text reads: Meeting at 3 PM.
```
The Mac speaks the description aloud.
Narrator: "It sees objects and reads text aloud in real time — the full detection and OCR pipeline at twenty-nine frames per second."

**[15–22s] Hearing mode — live captions**
Ctrl+C the vision mode. Run:
```
swift run Aura
```
Speak a sentence. Captions appear as you talk.
Narrator: "It captions speech on-device — under four percent word error rate on clean speech."

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

**[30–40s] Speech enhancement on the Neural Engine**
Run:
```
python3 scripts/evaluate_enhancement.py
```
Show the output: **+12.1 dB SNR gain** at 0 dB and **13 ms** per 4-second chunk.
Narrator: "A pretrained denoiser, converted to Core ML, adds twelve decibels of signal-to-noise — and runs in thirteen milliseconds on the Neural Engine, about eighty-eight times faster than the same model on Intel CPU. That's what moves it into real time."

**[40–50s] Privacy proof**
Open a second terminal pane. Run:
```
lsof -i -P | grep Aura
```
Show it returns nothing — zero network connections.
Narrator: "No network connections. No files on disk. The most private accessibility tool possible."

**[50–60s] Fairness**
Show the fairness tables from the README (screenshot or terminal output of `python3 scripts/analyze_fairness.py`).
Narrator: "We audited recognition across six English accents and five lighting conditions, with significance testing — and reported the results honestly, including where it still falls short."

## Recording tips

1. Use a clean desktop with just the terminal visible
2. Increase terminal font size (Cmd+ several times)
3. Use a well-lit room for the camera demo
4. Have a printed sign or book visible for OCR
5. Speak clearly and at normal pace for the caption demo
6. For the 30s version, rehearse transitions — Ctrl+C and the next command should be fluid
7. Narration cites M5 numbers: ~4% clean-speech WER, 29 FPS / 40 ms vision, +12 dB SNR, 13 ms enhancement

## LinkedIn post

The post lives in its own file: **`linkedin_post.md`** (single source of truth, M5 numbers). Upload the demo video natively to LinkedIn and paste that post; put the GitHub link in the first comment if you want a cleaner body.

## Commands reference for demo

```bash
swift run Aura --help              # show all modes
swift run Aura                     # live captions
swift run Aura --enhance           # captions with speech enhancement
swift run Aura --measure           # WER + latency measurement
swift run Aura --vision            # camera scene description
swift run Aura --multimodal        # sound events + camera fusion

# Enhancement SNR gain + latency (Neural Engine)
python3 scripts/evaluate_enhancement.py

# Privacy verification
lsof -i -P | grep Aura             # should return nothing (no network)
```
