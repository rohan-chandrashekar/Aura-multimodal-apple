import Foundation
import Speech

setbuf(stdout, nil)

let arguments = CommandLine.arguments
let measureMode = arguments.contains("--measure")
let enhanceMode = arguments.contains("--enhance")
let showHelp = arguments.contains("--help") || arguments.contains("-h")
let evaluateIndex = arguments.firstIndex(of: "--evaluate")
let evaluateDir = evaluateIndex.map { arguments.index(after: $0) }.flatMap {
    $0 < arguments.endIndex ? arguments[$0] : nil
}

if showHelp {
    print("""
    Aura — On-Device Hearing Mode

    Usage:
      swift run Aura                            Live captioning from microphone
      swift run Aura --enhance                  Live captioning with speech enhancement
      swift run Aura --measure                  Read a reference sentence; reports WER and latency
      swift run Aura --evaluate <dir>           Evaluate WER on clean/noisy/enhanced WAV files

    Permissions required (System Settings → Privacy & Security):
      • Microphone — grant to your terminal app
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

if let dir = evaluateDir {
    guard let evaluator = FileEvaluator(referenceText: LiveCaptioner.referenceText) else {
        print("Speech recognizer unavailable.")
        exit(1)
    }
    let absDir = dir.hasPrefix("/") ? dir : FileManager.default.currentDirectoryPath + "/" + dir
    DispatchQueue.main.async {
        evaluator.evaluateDirectory(absDir)
    }
    dispatchMain()
}

var enhancer: SpeechEnhancer? = nil
if enhanceMode {
    let modelPath = "models/SpeechEnhancer.mlpackage"
    do {
        enhancer = try SpeechEnhancer(modelPath: modelPath)
        print("Speech enhancement model loaded.")
    } catch {
        print("Failed to load enhancement model at \(modelPath): \(error.localizedDescription)")
        print("Run: python3 scripts/convert_enhancement_model.py")
        exit(1)
    }
}

guard let captioner = LiveCaptioner(measureMode: measureMode, enhancer: enhancer) else {
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
    let mode = enhancer != nil ? "Live captioning with enhancement" : "Live captioning"
    print("\(mode) active. Speak into the microphone. Ctrl+C to stop.\n")
}

signal(SIGINT) { _ in
    print("\nStopped.")
    exit(0)
}

dispatchMain()
