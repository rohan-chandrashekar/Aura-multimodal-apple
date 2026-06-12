# Capturing LinkedIn Screenshots

A run sheet for grabbing the visuals for the LinkedIn post. Read this on the machine you'll shoot from.

## ⚠️ Capture on the M5 — never on Intel

Every screenshot must come from the **Apple M5** (Neural Engine). On the Intel i5 the same commands print the *slow* numbers (≈6.2 FPS, ≈282 ms vision; ≈1149 ms enhancement) — those would contradict the 29.4 FPS / 13 ms claims in the post and undercut its credibility. The whole point of the visuals is the M5 numbers, so shoot there.

The live camera demo has to be driven by you interactively (grant the permission prompts) — it can't be automated.

## Before you shoot (pre-flight on the M5)

```bash
# 1. Build the app
swift build                                   # must succeed

# 2. Make sure the Core ML models exist (gitignored, so rebuild if missing)
ls models/                                    # expect the .mlpackage files
# If missing:
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python3 scripts/convert_detection_model.py    # YOLOv8n  (needed for --vision)
python3 scripts/convert_enhancement_model.py  # DNS48    (needed for the enhancement shot)
# Note: on the M5 the system python3 (3.9.6) installed requirements.txt cleanly.

# 3. Grant permissions: first run of --vision will prompt for
#    Camera, Microphone, and Speech Recognition. Approve all three in
#    System Settings -> Privacy & Security, then re-run.
```

## Terminal setup (do this first, every shot)

1. `Cmd+K` — clear the scrollback so only the relevant output shows
2. `Cmd +` a few times — bump the font so it's readable in a feed
3. Narrow the window so lines don't wrap awkwardly
4. Default or high-contrast theme; hide the rest of the desktop
5. Capture: `Cmd+Shift+4` then `Space` for a single clean window, or `Cmd+Shift+5` for the split-pane shot

## The 3 shots (ranked by impact)

### Shot 1 — Privacy proof (the hero image)
Two terminal panes side by side:
- **Left:** `swift run Aura --vision` running, printing detections
- **Right:** `lsof -i -P | grep Aura` → returns **nothing**

Capture both panes in one frame. This is the most arresting and uniquely-yours shot: an assistant actively reading the camera and mic with **zero network connections**, and it's trivially honest (anyone can rerun the command).

### Shot 2 — Vision running live
```bash
swift run Aura --vision
```
Point the camera at your desk plus a printed sign. Let it print a few lines like:
```
[65ms] I see laptop, cup. Text reads: Meeting at 3 PM.
```
Then `Ctrl+C` so the **FPS / latency summary** prints (look for ~29 FPS). Screenshot the terminal with both the detection lines and the FPS stat visible. This is "it actually works, on-device, fast."

### Shot 3 — Results card (no app run needed)
Screenshot the rendered **Highlights** block at the top of `README.md` on GitHub. Clean, all the headline numbers in one frame, and it's your own real docs — honest and effortless. Good as a carousel slide or a fallback.

### Optional — Breadth
`swift run Aura --help` shows all four modes plus the evaluation commands. Decent for conveying scope; weaker than the three above.

## Posting

- Lead with **Shot 1** (privacy proof) as the main image — most arresting, uniquely yours.
- For a 2–3 image carousel: Shot 1 → Shot 2 → Shot 3.
- Upload images/video **natively** to LinkedIn (native media beats an external link in the feed).
- Paste the post body from `linkedin_post.md`. Put the GitHub link in the **first comment** if you want a cleaner body.
