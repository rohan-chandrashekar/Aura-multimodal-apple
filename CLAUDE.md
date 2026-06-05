# Aura — On-Device Multimodal Accessibility Assistant

Flagship portfolio project for an Apple AIML internship application. Must survive a senior Apple ML engineer's scrutiny in a technical interview.

## Cardinal rule
Every performance number must be genuinely measured on this machine. Never fabricate, estimate, extrapolate, or round up a metric. If a number cannot be measured yet, write "TBD" and state why. A wrong-but-impressive number is a failure; a modest-but-real number is a success.

## Where we are
- Current state, completed phases, known issues: read `PROGRESS.md`.
- Full phase-by-phase build plan: read `BUILD_PROMPT.md`.
- At the start of a session, read both before doing anything else, then continue from the phase the user names.

## Workflow rules
- Build ONE phase at a time. Do not skip ahead.
- At the end of each phase: run the verification, update `README.md`, `RESUME_BULLETS.md`, and `PROGRESS.md` with real measured results, commit, then STOP, summarize for the user, and wait for "go".
- Commit and push after every meaningful step. This is a wiped lab machine; uncommitted work is lost on logout and auto memory does not persist here. `CLAUDE.md` plus `PROGRESS.md` in the repo are the only durable memory.
- Before ending a session, remind the user to commit and push.

## Tech stack and constraints
- Apple Silicon, macOS 14+.
- Core app: Swift, Swift Package Manager executable. `swift build`, `swift run`.
- Native frameworks: AVFoundation (camera + microphone), Speech (SFSpeechRecognizer, on-device), SoundAnalysis (SNClassifySoundRequest), Vision (object detection + VNRecognizeTextRequest OCR), AVSpeechSynthesizer (TTS).
- ML models run in Core ML on the Neural Engine. Use PRETRAINED models converted with coremltools — do NOT train large models from scratch (wiped, time-boxed lab machine).
- Python (coremltools, scipy, scikit-learn, librosa, pystoi) for model conversion and offline evaluation/statistics only.

## Privacy invariant
Audio and video are processed in memory and never written to disk. User-study recordings and participant data are never committed. Nothing leaves the device. This must be provable.

## Coding standards
- Complete, runnable files. No inline code comments; clear names, explanation in commit messages and README prose.
- Clearly flag placeholder values for anything not provided.
- Communicate directly. Push back on anything wrong, slow, or that won't survive interview scrutiny rather than agreeing.

## Never commit
Models/checkpoints, the .mlpackage, build artifacts, audio/video recordings, and any user-study or participant data.
