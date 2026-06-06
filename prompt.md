# Aura — Cross-Machine Benchmark & Reproduction Prompt

Paste this whole file (or say "read `prompt.md` and follow it") as your first message to **Claude Code**, running inside a fresh checkout of this repo on the target Mac (e.g. an M1 or M5 laptop). It will set up, measure, and record every number on that machine.

---

## Your job

Reproduce **every Aura measurement on THIS machine** and record the real, freshly measured results. Do the automated measurements yourself; hand the human a short list of the live (camera/mic) ones to run, then collect their output. Finish by writing a per-machine results file and printing a summary table.

## Cardinal rule — do not violate

Every number must be **genuinely measured on THIS machine**. Never fabricate, estimate, extrapolate, round up, or copy a number from `README.md` / `PROGRESS.md` / `RESUME_BULLETS.md`. Those files contain numbers from *other* machines — they are reference only, not values to reuse. If a number cannot be measured (e.g. no camera, human declined the live test), write **`TBD — <reason>`**. A wrong-but-impressive number is a failure; a modest-but-real number is a success.

## Privacy invariant — do not violate

Audio and video are processed in memory and never written to disk. **Never commit** models, the `.mlpackage` files, build artifacts, generated test data (`test_*` directories), or any recordings — `.gitignore` already excludes them; do not force-add them. The only file you may commit is the results file in Step 7.

## Before you start

1. Read `CLAUDE.md`, `PROGRESS.md`, and `README.md` to understand the project.
2. Confirm toolchain:
   ```bash
   swift --version
   python3 --version
   ```
   Swift needs Xcode or the Command Line Tools. Python needs a version with PyTorch wheels (3.9–3.12 all work on Apple Silicon).

---

## Step 1 — Identify the machine

Run and record exactly what these print:
```bash
uname -m
sysctl -n hw.model
sysctl -n machdep.cpu.brand_string
system_profiler SPHardwareDataType | grep -E "Chip|Model Name|Memory"
sw_vers
```
Record: chip (e.g. Apple M1 / M5), RAM, macOS version + build. You'll name the results file after the chip (e.g. `M1`, `M5`).

## Step 2 — Python environment + Core ML models

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```
If `torch`/`coremltools` fail to install on the default `python3`, recreate the venv with `python3.11` or `python3.12` and retry. (On the M5, the system `python3` 3.9.6 installed cleanly.)

If `models/SpeechEnhancer.mlpackage` and `models/ObjectDetector.mlpackage` already exist, you may skip the next two commands. Otherwise convert:
```bash
python3 scripts/convert_enhancement_model.py    # DNS48 speech enhancer  -> models/SpeechEnhancer.mlpackage (~36 MB)
python3 scripts/convert_detection_model.py      # YOLOv8n object detector -> models/ObjectDetector.mlpackage (~6 MB)
ls models/
```

## Step 3 — Generate test data + the enhancement benchmark

```bash
python3 scripts/evaluate_enhancement.py     # creates test_audio/, prints SNR gain @ 0/5/10 dB + enhancement latency
python3 scripts/create_test_images.py       # creates test_images/
python3 scripts/create_test_sounds.py       # creates test_sounds/
python3 scripts/generate_fairness_data.py   # creates test_accents/, test_lighting/, test_lighting_mitigated/
python3 scripts/apply_speech_mitigation.py  # creates test_accents_mitigated/ (DNS48 mitigation pass)
```

**CAPTURE from `evaluate_enhancement.py`:** SNR gain at 0 / 5 / 10 dB, and enhancement model latency per 4 s chunk (record whatever stats it prints — mean / median / p95). Note: the noise is drawn randomly each run at fixed SNR levels, so noisy/enhanced WER is not a strict A/B against other machines — only the SNR levels are held fixed. Say so in the results.

## Step 4 — Automated measurements (you run these)

Use `swift run Aura <mode>` so the methodology matches the existing numbers. The first run will compile.

```bash
swift run Aura --evaluate test_audio          # WER for clean / noisy(0,5,10) / enhanced(0,5,10)
swift run Aura --vision-eval test_images      # detection + OCR precision / recall / F1 + latency
swift run Aura --sound-eval test_sounds       # sound-event classification F1 / precision / recall
swift run Aura --fairness-speech test_accents # WER per accent -> writes test_accents/speech_results.json
swift run Aura --fairness-vision test_lighting # OCR recall per lighting -> writes test_lighting/vision_results.json
swift run Aura --fairness-speech test_accents_mitigated   # mitigated accent WER (optional)
swift run Aura --fairness-vision test_lighting_mitigated  # mitigated lighting recall (optional)
python3 scripts/analyze_fairness.py           # Kruskal-Wallis (accents), Wilcoxon (lighting), disparities, task completion + quality + time-on-task
```

**CAPTURE:**
- `--evaluate`: WER for each of clean / noisy_0dB / noisy_5dB / noisy_10dB / enhanced_0dB / enhanced_5dB / enhanced_10dB.
- `--vision-eval`: OCR precision / recall / F1 and per-image latency.
- `--sound-eval`: F1, precision, recall, and the per-clip detection results (note this set is synthetic and dominated by which clips land near a class boundary).
- `--fairness-speech` / `--fairness-vision`: per-group WER/recall and the disparity (max − min).
- `analyze_fairness.py`: Kruskal-Wallis H and p (accents), Wilcoxon W and p (lighting), task completion rate, quality score mean ± std, time-on-task mean / median.

## Step 5 — Live measurements (the human must run these)

These need a person and granted **Microphone / Speech Recognition / Camera** permissions (first run will prompt; approve in System Settings → Privacy & Security, then re-run). You cannot speak aloud or point a camera, so print these instructions clearly and ask the human to run them and paste the output back. If the human declines or there's no camera, mark each **TBD — not run**.

1. **Caption WER + latency**
   ```bash
   swift run Aura --measure
   ```
   Read the on-screen reference sentence aloud at a normal pace; it records 30 s, then prints live WER and caption latency (mean / median / p95).
2. **Vision FPS + latency**
   ```bash
   swift run Aura --vision
   ```
   Point the camera at a few desk objects and a printed sign for ~60–90 s, then `Ctrl+C`. It prints camera FPS and detection+OCR latency over the session.
3. **Multimodal fusion (qualitative)**
   ```bash
   swift run Aura --multimodal
   ```
   Clap or knock near the mic; confirm it prints a fused alert combining the sound event with what the camera sees. Record whether fusion fired and the approximate latency.

## Step 6 — Privacy verification

While any live mode is running, in a second terminal:
```bash
lsof -i -P | grep Aura     # expect: nothing (no network connections)
```
Also confirm no audio/video files were created during the runs (check the working directory; only `test_*` generated data and `models/` should exist). Record "audio/frames written to disk: 0" and "network bytes: 0" only if you actually verified it.

## Step 7 — Record the results

Write a new file `benchmarks/<CHIP>.md` (e.g. `benchmarks/M1.md`). Create the `benchmarks/` directory if needed. Fill the template below with **only measured values**; use `TBD — <reason>` for anything not run. Then **print the same table in chat** so the human can copy it.

If `git` is configured with push access, commit and push just that one file:
```bash
git add benchmarks/<CHIP>.md
git commit -m "Add <CHIP> benchmark results"
git push
```
The file is per-machine, so M1 and M5 results won't collide. If git push isn't available, just print the full file contents for the human to copy. **Do not edit `PROGRESS.md`, `README.md`, or `RESUME_BULLETS.md`** — folding these into the comparison tables happens later on the main machine.

### Results template

```markdown
# Aura Benchmark — <CHIP>

Machine: <chip> / <RAM> / macOS <version> (<build>), arch <arm64>. Core ML on the Neural Engine.
Date: <YYYY-MM-DD>. All numbers genuinely measured on this machine via `swift run Aura` and the scripts.

| Metric | Value |
|---|---|
| Clean speech WER (`--evaluate`) | |
| Noisy WER @ 0 / 5 / 10 dB | |
| Enhanced WER @ 0 / 5 / 10 dB | |
| SNR gain @ 0 / 5 / 10 dB | |
| Enhancement latency, 4 s chunk (mean / median / p95) | |
| Live caption latency mean / median / p95 (`--measure`) | |
| Live WER (`--measure`, spoken) | |
| OCR precision / recall / F1 (`--vision-eval`) | |
| OCR latency per image | |
| Camera FPS, live (`--vision`) | |
| Detection+OCR latency, live (`--vision`) | |
| Sound-event F1 / precision / recall (`--sound-eval`) | |
| Sound-event speech detection | |
| Multimodal fusion fired? + latency (`--multimodal`) | |
| WER disparity across accents (max − min) | |
| Kruskal-Wallis across accents (H, p) | |
| OCR disparity across lighting (max − min) | |
| Wilcoxon across lighting (W, p) | |
| Task completion rate | |
| Quality score (mean ± std) | |
| Time-on-task (mean / median) | |
| Audio / frames written to disk | |
| Network bytes | |

Notes: <e.g. fresh noise realization per run; synthetic sound set caveat; any TBDs and why; which Python version was used>.
```

---

## What to hand back to the human at the end

1. The path to `benchmarks/<CHIP>.md` (committed if possible, otherwise its full contents).
2. The filled summary table, printed in chat.
3. A short list of any **TBDs** and exactly why (so the human knows what still needs a live run).
4. Confirmation that nothing outside the allowed results file was committed, and that the privacy checks passed.
