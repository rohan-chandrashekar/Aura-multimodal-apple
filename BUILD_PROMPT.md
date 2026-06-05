You are building a macOS portfolio project called "Aura," an on-device multimodal
accessibility assistant. It is the flagship project for my Apple internship application
(AIML track). It must survive scrutiny from a senior Apple ML engineer in a technical
interview.

THE NON-NEGOTIABLE RULE: every performance number must be genuinely measured on this
machine. Never fabricate, estimate, extrapolate, or round up a metric. If a number cannot
be measured yet, write "TBD" and state why. A wrong-but-impressive number is a failure; a
modest-but-real number is a success.

WHAT IT DOES
A private, real-time perceptual aid for blind/low-vision and deaf/hard-of-hearing users,
running entirely on-device. Two modes plus a multimodal fusion layer: a vision mode that
describes the scene and reads text aloud, a hearing mode that captions and enhances speech,
and a sound-awareness layer that fuses audio events with visual context. No camera or
microphone data ever leaves the device.

THE PROBLEM (anchor every design decision to this)
Blind/low-vision and deaf/hard-of-hearing people need to understand their immediate
environment in real time. Existing aids either require a human or stream the most intimate
data imaginable -- everything the user looks at and hears -- to the cloud, which is both a
privacy violation and too slow for real-time use. Aura solves this on-device.

HARD CONSTRAINTS
- Apple Silicon, macOS 14+. Confirm with `sw_vers`, `swift --version`, `uname -m`.
- Core app: Swift, as a Swift Package Manager executable target. Build with `swift build`,
  run with `swift run`.
- Use Apple's native frameworks: AVFoundation (camera + microphone), Speech
  (SFSpeechRecognizer with requiresOnDeviceRecognition = true), SoundAnalysis
  (SNClassifySoundRequest for sound events), Vision (object detection + VNRecognizeTextRequest
  OCR), AVSpeechSynthesizer (on-device text-to-speech).
- ML models run in Core ML on the Neural Engine. Use PRETRAINED models converted with
  coremltools -- do NOT train large models from scratch (this is a wiped, time-boxed lab
  machine).
- Python (coremltools, scipy, scikit-learn, librosa, pystoi) only for model conversion and
  offline evaluation/statistics.
- On first run, instruct me to grant Camera, Microphone, and Speech Recognition permissions
  in System Settings > Privacy & Security, then re-run.
- PRIVACY INVARIANT: audio and video are processed in memory and never written to disk;
  user-study recordings and participant data are never committed; nothing leaves the device.
  State this and keep it true.

ENGINEERING STANDARDS
- Complete, runnable files. No inline code comments; clear names, explanation in commit
  messages and README prose.
- Clearly flag placeholder values for anything not provided.
- Communicate directly; push back on anything wrong, slow, or that won't survive interview
  scrutiny rather than agreeing.
- Git: one commit per completed phase. Maintain a .gitignore excluding the venv, models,
  build artifacts, recordings, and study data.
- Maintain three living docs every phase: README.md (numbers-first, real measured values),
  RESUME_BULLETS.md (interview-defensible bullets, measured numbers only), PROGRESS.md
  (done / next / known issues).

ITERATIVE PROTOCOL (IMPORTANT)
Build ONE phase at a time; do not skip ahead. At the end of each phase you MUST:
(1) run the verification, (2) update README.md, RESUME_BULLETS.md, and PROGRESS.md with the
real results, (3) commit, (4) STOP and summarize -- what you built, the measured numbers,
what didn't work, what the next phase does -- then WAIT for me to reply "go." Only ask when
genuinely blocked; otherwise make reasonable defaults and note them.

PHASES

Phase 0 -- Hearing-mode caption spine
AVAudioEngine microphone capture -> Speech framework on-device recognition
(requiresOnDeviceRecognition = true) -> live captions in the UI. No audio written to disk.
Done when: live captions work from the mic; report caption latency, on-device word error
rate on a read sample, and confirm 0 bytes sent and 0 audio files written.

Phase 1 -- Speech enhancement in noise
Insert a pretrained speech-enhancement/denoising model (converted to Core ML) before
recognition. Measure recognition on clean vs noisy vs enhanced audio.
Done when: a before/after table of word error rate (clean / noisy / enhanced), SNR gain in
dB, and the added latency from the enhancement model on the ANE.

Phase 2 -- Vision-mode scene aid
AVFoundation camera -> Vision object detection + VNRecognizeTextRequest OCR -> compose a
spoken description -> AVSpeechSynthesizer. No frames written to disk.
Done when: pointing the camera produces a correct spoken description; report detection/OCR
accuracy on a small labeled set, end-to-end latency, and FPS.

Phase 3 -- Multimodal fusion (sound awareness + scene)
SoundAnalysis (SNClassifySoundRequest) for on-device sound-event detection (alarms, knocks,
name called) fused with Vision context, producing combined alerts/descriptions -- the
multimodal core for deaf users.
Done when: sound events are detected and fused with visual context; report sound-event
detection F1, fusion latency, and on-device confirmation.

Phase 4 -- Interactive evaluation + fairness audit
Package the modes as an interactive prototype. Run a small user study (participants or
scripted tasks) measuring task-completion rate, time-on-task, and satisfaction (SUS),
analyzed with significance testing (scipy). Audit recognition fairness across groups --
speech word error rate across accents, vision accuracy across lighting -- report the
disparity and apply a mitigation.
Done when: study results with statistical significance, and a fairness disparity table
before vs after mitigation. Do not commit any participant recordings or identifying data.

Phase 5 -- Demo + docs
A screen/scene-recordable demo (camera -> spoken description; noisy speech -> captions; a
sound alert; a privacy indicator showing nothing left the device). Finalize README,
RESUME_BULLETS.md, and a DEMO.md with a LinkedIn post and a 30-60s video script.

Start now with Phase 0: confirm toolchain and hardware, set up the Swift package and
.gitignore, build the hearing-mode caption spine, measure it, and stop.
