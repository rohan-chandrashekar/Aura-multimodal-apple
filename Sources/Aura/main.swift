import Foundation
import Speech

setbuf(stdout, nil)

let arguments = CommandLine.arguments
let measureMode = arguments.contains("--measure")
let showHelp = arguments.contains("--help") || arguments.contains("-h")

if showHelp {
    print("""
    Aura — On-Device Hearing Mode

    Usage:
      swift run Aura              Live captioning from microphone
      swift run Aura --measure    Read a reference sentence; reports WER and latency

    Permissions required (System Settings → Privacy & Security):
      • Microphone — grant to your terminal app (Terminal, iTerm, etc.)
      • Speech Recognition — grant to your terminal app

    All audio is processed in memory. Nothing is written to disk or sent over the network.
    """)
    exit(0)
}

print("Aura — On-Device Hearing Mode")

let status = SFSpeechRecognizer.authorizationStatus()
if status == .denied || status == .restricted {
    print("Speech recognition denied (status: \(status.rawValue)).")
    print("Grant access: System Settings → Privacy & Security → Speech Recognition.")
    exit(1)
}

guard let captioner = LiveCaptioner(measureMode: measureMode) else {
    print("Speech recognizer unavailable. Check locale support for on-device recognition.")
    exit(1)
}

do {
    try captioner.start()
} catch {
    print("Failed to start audio capture: \(error.localizedDescription)")
    print("Grant Microphone access: System Settings → Privacy & Security → Microphone for your terminal app.")
    exit(1)
}

if measureMode {
    print("Measurement mode — read the following text aloud:")
    print(String(repeating: "─", count: 50))
    print(LiveCaptioner.referenceText)
    print(String(repeating: "─", count: 50))
    print("Recording for 30 seconds...\n")
} else {
    print("Live captioning active. Speak into the microphone. Ctrl+C to stop.\n")
}

signal(SIGINT) { _ in
    print("\nStopped.")
    exit(0)
}

dispatchMain()
