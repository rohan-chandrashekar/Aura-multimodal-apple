# Aura — Screenshot Capture Prompt (run on the M3 Pro via Claude Code)

Paste this whole file (or say "read `screenshots_prompt.md` and follow it") as your first message to **Claude Code**, inside a fresh checkout of this repo on the **M3 Pro MacBook**. Goal: produce LinkedIn-ready screenshots, fast.

---

## Context you MUST respect

- The LinkedIn post and every number in this repo are **Apple M5** figures (canonical, in `benchmarks/M5.md`). This M3 Pro is being used **only to capture visuals**, not to measure anything.
- Therefore the screenshots must **not feature any M3 performance number** — no FPS-summary stat, and don't make a latency value the focus. Those would contradict the M5 numbers in the post. Favor shots that carry **no speed claim** (the privacy proof and the `--help` mode list are exactly this).
- **Do not change any numbers** in `README.md`, `PROGRESS.md`, `RESUME_BULLETS.md`, `linkedin_post.md`, or `benchmarks/`. You are not benchmarking. Leave all docs untouched.
- Screenshots are machine-specific media: **do not commit them.** Save to `~/Desktop/aura_screenshots/`.
- Privacy invariant holds: the app writes no audio/video to disk and opens no network connections — that's the whole point of the hero shot. Don't alter that behavior.

## Deliverables — save all to `~/Desktop/aura_screenshots/`

1. **`privacy_proof.png`** (the hero) — the app running via `--vision` beside a terminal where `lsof -i -P | grep Aura` returns **nothing**. The selling point is the empty `lsof` = zero network connections while the camera/mic are live. Frame the shot so the empty `lsof` pane is clearly visible.
2. **`modes.png`** — the output of `swift run Aura --help` (lists all four modes + the evaluation commands; contains no numbers; conveys the project's scope).
3. **`scene.png`** (optional) — a couple of `--vision` description lines such as `I see laptop, cup. Text reads: Meeting at 3 PM.` Capture only the descriptive lines; **do not** include the FPS summary (don't `Ctrl+C` in frame), and it's fine if a per-frame `[NNms]` prefix shows but don't make it the focus.

## Step 1 — Setup (you run this)

```bash
# If the repo isn't here yet:
# git clone https://github.com/rohan-chandrashekar/Aura-multimodal-apple && cd Aura-multimodal-apple
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python3 scripts/convert_detection_model.py     # YOLOv8n -> models/ObjectDetector.mlpackage (needed for --vision)
swift build
mkdir -p ~/Desktop/aura_screenshots
```
(The speech-enhancement model is NOT needed for screenshots — skip `convert_enhancement_model.py` to save time.)

## Step 2 — Camera permission (needs the human)

Run `swift run Aura --vision` once. macOS will prompt for **Camera** access — the human approves it (System Settings → Privacy & Security → Camera, for the terminal app), then re-run if needed and `Ctrl+C`. You cannot click this dialog; ask the human to.

## Step 3 — Make the terminal look good (before any capture)

`Cmd+K` to clear scrollback, bump the font several sizes (`Cmd +`), use a clean/high-contrast theme, hide the rest of the desktop.

## Step 4 — Capture

You may automate with `screencapture` (macOS CLI) and `osascript` (to open visible Terminal windows), or, if that's unreliable, hand the human exact `Cmd+Shift+5` / `Cmd+Shift+4` instructions. Either way produce the three files.

Suggested automated approach:
- **modes.png** — open a clean Terminal window running `swift run Aura --help`, then:
  ```bash
  screencapture -x ~/Desktop/aura_screenshots/modes.png
  ```
- **privacy_proof.png** — open one Terminal window running `swift run Aura --vision` (ask the human to point the camera at a desk with a couple of objects and a printed sign), open a second window running `lsof -i -P | grep Aura` (it prints nothing), arrange both visible, then:
  ```bash
  screencapture -x ~/Desktop/aura_screenshots/privacy_proof.png
  ```
- **scene.png** — while `--vision` is printing description lines, capture the window (crop later to the descriptive lines):
  ```bash
  screencapture -x ~/Desktop/aura_screenshots/scene.png
  ```

If you can't reliably arrange windows, tell the human: "Run these two commands in two panes, point the camera at a desk + a sign, then press `Cmd+Shift+5`, choose the area, and save into `~/Desktop/aura_screenshots/`."

## Step 5 — Report back to the human

1. List the saved files in `~/Desktop/aura_screenshots/` and which is the hero (`privacy_proof.png`).
2. Give an honest caption suggestion for the hero, e.g. **"Aura running on Apple Silicon — camera and mic live, zero network connections."** (Do NOT caption it as the M5 or attach any M3 speed number.)
3. Confirm you committed nothing and changed no docs.
4. Remind the human: post the screenshot(s) with the body from `linkedin_post.md` (which carries the M5 numbers).
