# Aura — Full Screenshot Capture Prompt (run on the M3 Pro via Claude Code)

Paste this whole file (or say "read `screenshots_prompt.md` and follow it") as your first message to **Claude Code**, inside a checkout of this repo on the **M3 Pro MacBook**. Goal: capture the **complete set** of LinkedIn/demo screenshots — privacy, performance, evals, fairness, everything — using real measurements on this machine, fast.

---

## Ground rules (minimal)

- These screenshots are **real M3 Pro measurements**. Capture every command's actual output — do not edit or fake anything on screen. The human will reconcile any M5-vs-M3 wording in the post afterward; that's their call, not yours.
- **Do not commit** screenshots, models, or generated test data. Save all images to `~/Desktop/aura_screenshots/`. (`models/` and `test_*/` are already gitignored.)
- **Do not edit any repo docs or numbers.** You are only capturing images.
- The app still writes no audio/video to disk and opens no network connections — don't change that; it's what the privacy shot demonstrates.

## The full deliverable list — save all to `~/Desktop/aura_screenshots/`

| File | Command | Needs human? |
|---|---|---|
| `01_help.png` | `swift run Aura --help` | no |
| `02_privacy_proof.png` | `--vision` running + `lsof -i -P \| grep Aura` (returns nothing) | camera |
| `03_vision_live.png` | `--vision` detection lines + the FPS/latency summary on `Ctrl+C` | camera |
| `04_enhancement.png` | `python3 scripts/evaluate_enhancement.py` (SNR gain + per-chunk latency) | no |
| `05_asr_eval.png` | `swift run Aura --evaluate test_audio` (clean/noisy/enhanced WER table) | no |
| `06_vision_eval.png` | `swift run Aura --vision-eval test_images` (detection+OCR P/R/F1) | no |
| `07_sound_eval.png` | `swift run Aura --sound-eval test_sounds` (sound-event F1) | no |
| `08_fairness_speech.png` | `swift run Aura --fairness-speech test_accents` (WER by accent) | no |
| `09_fairness_vision.png` | `swift run Aura --fairness-vision test_lighting` (OCR recall by lighting) | no |
| `10_fairness_analysis.png` | `python3 scripts/analyze_fairness.py` (Kruskal-Wallis, Wilcoxon, task/quality) | no |
| `11_measure.png` | `swift run Aura --measure` (live spoken WER + caption latency) | speak |
| `12_multimodal.png` | `swift run Aura --multimodal` (fused sound+vision alert) | clap + camera |

## Step 1 — Setup (you run this)

```bash
# If the repo isn't here yet:
# git clone https://github.com/rohan-chandrashekar/Aura-multimodal-apple && cd Aura-multimodal-apple
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Core ML models
python3 scripts/convert_enhancement_model.py    # models/SpeechEnhancer.mlpackage
python3 scripts/convert_detection_model.py      # models/ObjectDetector.mlpackage

# Test data for the evals
python3 scripts/evaluate_enhancement.py         # creates test_audio/ (capture this output for 04_enhancement.png)
python3 scripts/create_test_images.py           # test_images/
python3 scripts/create_test_sounds.py           # test_sounds/
python3 scripts/generate_fairness_data.py       # test_accents/, test_lighting/, test_lighting_mitigated/
python3 scripts/apply_speech_mitigation.py      # test_accents_mitigated/

swift build
mkdir -p ~/Desktop/aura_screenshots
```

## Step 2 — Permissions (needs the human)

First runs of `--vision`/`--multimodal` prompt for **Camera**, and `--measure`/`--multimodal` for **Microphone** + **Speech Recognition**. The human approves these in System Settings → Privacy & Security, then re-run. You can't click those dialogs.

## Step 3 — Make the terminal look good (before each capture)

`Cmd+K` to clear scrollback, bump the font several sizes (`Cmd +`), clean/high-contrast theme, hide the rest of the desktop.

## Step 4 — Capture

Use `screencapture` (macOS CLI) plus `osascript` to open visible Terminal windows; fall back to telling the human to use `Cmd+Shift+5` / `Cmd+Shift+4` if window automation is unreliable.

**Terminal-output shots (01, 04–10)** — no camera/mic. For each: open a clean Terminal window via `osascript`, run the command, let it finish printing, then capture, e.g.:
```bash
screencapture -x ~/Desktop/aura_screenshots/05_asr_eval.png
```
Run `--evaluate`, `--vision-eval`, `--sound-eval`, `--fairness-speech`, `--fairness-vision` from the repo root with the directory args shown in the table. Capture `evaluate_enhancement.py` output for `04` and `analyze_fairness.py` output for `10`.

**Live shots (02, 03, 11, 12)** — guide the human:
- `02_privacy_proof` / `03_vision_live`: run `swift run Aura --vision`; human points the camera at a desk with a couple of objects and a **printed sign** (for OCR). For `02`, open a second window running `lsof -i -P | grep Aura` (prints nothing) and capture both. For `03`, let it print description lines, then `Ctrl+C` so the FPS/latency summary shows, and capture that.
- `11_measure`: run `swift run Aura --measure`; human reads the on-screen reference sentence aloud; after the 30 s it prints WER + latency — capture that.
- `12_multimodal`: run `swift run Aura --multimodal`; human claps/knocks near the mic with the camera on a scene; capture a fused alert line.

## Step 5 — Report back

1. List every file in `~/Desktop/aura_screenshots/` with a one-line note on what each shows and its key number (so the human knows the real M3 values per shot).
2. Flag which shots contain numbers that differ from the repo's M5 figures (e.g. FPS, live WER, latencies), so the human knows exactly where to reconcile the post wording.
3. Confirm you committed nothing and changed no docs.
4. (Optional) If the human wants a durable record, you may also write the captured numbers into `benchmarks/M3.md` using the template in `prompt.md` — ask first.
