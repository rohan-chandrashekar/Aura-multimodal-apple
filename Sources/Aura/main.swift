import Foundation
import Speech

setbuf(stdout, nil)

let arguments = CommandLine.arguments
let measureMode = arguments.contains("--measure")
let enhanceMode = arguments.contains("--enhance")
let visionMode = arguments.contains("--vision")
let multimodalMode = arguments.contains("--multimodal")
let showHelp = arguments.contains("--help") || arguments.contains("-h")

func argValue(for flag: String) -> String? {
    guard let idx = arguments.firstIndex(of: flag) else { return nil }
    let next = arguments.index(after: idx)
    return next < arguments.endIndex ? arguments[next] : nil
}

let evaluateDir = argValue(for: "--evaluate")
let visionEvalDir = argValue(for: "--vision-eval")
let soundEvalDir = argValue(for: "--sound-eval")

if showHelp {
    print("""
    Aura — On-Device Multimodal Accessibility Assistant

    Hearing mode:
      swift run Aura                            Live captioning from microphone
      swift run Aura --enhance                  Live captioning with speech enhancement
      swift run Aura --measure                  Read a reference sentence; reports WER and latency
      swift run Aura --evaluate <dir>           Evaluate WER on clean/noisy/enhanced WAV files

    Vision mode:
      swift run Aura --vision                   Live scene description from camera
      swift run Aura --vision-eval <dir>        Evaluate detection+OCR on labeled images

    Multimodal mode:
      swift run Aura --multimodal               Sound events fused with camera context
      swift run Aura --sound-eval <dir>         Evaluate sound classification on audio files

    Permissions (System Settings → Privacy & Security):
      • Microphone, Speech Recognition — for hearing mode
      • Camera — for vision mode and multimodal mode

    All audio/video is processed in memory. Nothing is written to disk or sent over the network.
    """)
    exit(0)
}

if multimodalMode {
    print("Aura — Multimodal Mode")
    let fusion = MultimodalMode()
    do {
        try fusion.start()
        print("Multimodal mode active. Listening for sounds + watching camera. Ctrl+C to stop.\n")
    } catch {
        print("Failed to start: \(error.localizedDescription)")
        print("Grant Microphone and Camera access in System Settings → Privacy & Security.")
        exit(1)
    }

    let source = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    signal(SIGINT, SIG_IGN)
    source.setEventHandler {
        fusion.stop()
        exit(0)
    }
    source.resume()
    dispatchMain()
}

if let dir = soundEvalDir {
    print("Aura — Sound Classification Evaluation")
    let absDir = dir.hasPrefix("/") ? dir : FileManager.default.currentDirectoryPath + "/" + dir
    let evaluator = SoundEvaluator()
    DispatchQueue.main.async {
        evaluator.evaluateDirectory(absDir)
    }
    dispatchMain()
}

if visionMode {
    print("Aura — Vision Mode")
    let vision = VisionMode()
    do {
        try vision.start()
        print("Vision mode active. Point camera at objects or text. Ctrl+C to stop.\n")
    } catch {
        print("Failed to start camera: \(error.localizedDescription)")
        print("Grant Camera access: System Settings → Privacy & Security → Camera for your terminal app.")
        exit(1)
    }

    let source = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    signal(SIGINT, SIG_IGN)
    source.setEventHandler {
        vision.stop()
        exit(0)
    }
    source.resume()
    dispatchMain()
}

if let dir = visionEvalDir {
    print("Aura — Vision Evaluation")
    let absDir = dir.hasPrefix("/") ? dir : FileManager.default.currentDirectoryPath + "/" + dir
    let evaluator = VisionEvaluator()
    evaluator.evaluateDirectory(absDir)
    dispatchMain()
}

print("Aura — Hearing Mode")

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
