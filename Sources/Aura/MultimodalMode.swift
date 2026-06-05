import Foundation
import AVFoundation
import Vision
import CoreML
import AppKit

final class MultimodalMode: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    private let soundDetector = SoundEventDetector()
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let cameraQueue = DispatchQueue(label: "aura.multimodal.camera")
    private let synthesizer = AVSpeechSynthesizer()
    private var detectionModel: VNCoreMLModel?
    private var latestPixelBuffer: CVPixelBuffer?
    private var bufferLock = NSLock()
    private var fusionLatencies: [Double] = []
    private var eventsDetected = 0
    private var startTime: Date?
    private var lastAlertTime = Date.distantPast
    private let alertCooldown: TimeInterval = 3.0

    override init() {
        super.init()
        loadDetectionModel()
    }

    func start() throws {
        try setupCamera()
        captureSession.startRunning()

        try soundDetector.start { [weak self] event in
            self?.handleSoundEvent(event)
        }

        startTime = Date()
    }

    func stop() {
        soundDetector.stop()
        captureSession.stopRunning()
        printStats()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        bufferLock.lock()
        latestPixelBuffer = pixelBuffer
        bufferLock.unlock()
    }

    private func setupCamera() throws {
        guard let camera = AVCaptureDevice.default(for: .video) else {
            print("No camera detected. Multimodal mode will run sound-only.")
            return
        }

        let input = try AVCaptureDeviceInput(device: camera)
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .medium

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        videoOutput.setSampleBufferDelegate(self, queue: cameraQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        captureSession.commitConfiguration()
    }

    private func handleSoundEvent(_ event: SoundEvent) {
        let now = Date()
        guard now.timeIntervalSince(lastAlertTime) >= alertCooldown else { return }
        lastAlertTime = now

        eventsDetected += 1
        let fusionStart = Date()

        bufferLock.lock()
        let pixelBuffer = latestPixelBuffer
        bufferLock.unlock()

        guard let pixelBuffer else {
            let alert = formatAlert(sound: event, objects: [], text: [])
            let latencyMs = Date().timeIntervalSince(fusionStart) * 1000
            fusionLatencies.append(latencyMs)
            displayAndSpeak(alert, latencyMs: latencyMs)
            return
        }

        var objects: [String] = []
        var texts: [String] = []

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        if let model = detectionModel {
            let detRequest = VNCoreMLRequest(model: model) { request, _ in
                guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
                var seen = Set<String>()
                for obs in results where obs.confidence >= 0.4 {
                    if let label = obs.labels.first?.identifier, !seen.contains(label) {
                        seen.insert(label)
                        objects.append(label)
                    }
                }
            }
            detRequest.imageCropAndScaleOption = .scaleFill
            try? handler.perform([detRequest])
        }

        let ocrRequest = VNRecognizeTextRequest { request, _ in
            guard let results = request.results as? [VNRecognizedTextObservation] else { return }
            texts = results.compactMap { $0.topCandidates(1).first?.string }
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        }
        ocrRequest.recognitionLevel = .fast
        ocrRequest.usesLanguageCorrection = false
        try? handler.perform([ocrRequest])

        let latencyMs = Date().timeIntervalSince(fusionStart) * 1000
        fusionLatencies.append(latencyMs)

        let alert = formatAlert(sound: event, objects: objects, text: texts)
        displayAndSpeak(alert, latencyMs: latencyMs)
    }

    private func formatAlert(sound: SoundEvent, objects: [String], text: [String]) -> String {
        let soundLabel = sound.identifier
            .replacingOccurrences(of: "_", with: " ")
            .localizedCapitalized
        let conf = String(format: "%.0f", sound.confidence * 100)

        var parts = ["Sound: \(soundLabel) (\(conf)%)"]

        if !objects.isEmpty {
            parts.append("I see \(objects.prefix(4).joined(separator: ", "))")
        }

        if !text.isEmpty {
            parts.append("Text: \(text.prefix(2).joined(separator: "; "))")
        }

        return parts.joined(separator: ". ") + "."
    }

    private func displayAndSpeak(_ alert: String, latencyMs: Double) {
        print("\r\u{1B}[2K[\(String(format: "%.0f", latencyMs))ms] \(alert)")
        fflush(stdout)

        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: alert)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.2
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    private func loadDetectionModel() {
        let modelPath = "models/ObjectDetector.mlpackage"
        guard FileManager.default.fileExists(atPath: modelPath) else { return }

        do {
            let url = URL(fileURLWithPath: modelPath)
            let compiledURL = try MLModel.compileModel(at: url)
            let mlModel = try MLModel(contentsOf: compiledURL)
            detectionModel = try VNCoreMLModel(for: mlModel)
            print("Object detection model loaded for fusion.")
        } catch {
            print("Detection model not loaded: \(error.localizedDescription)")
        }
    }

    private func printStats() {
        guard let start = startTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        let stats = Metrics.latencyStats(fusionLatencies)

        print("\n" + String(repeating: "─", count: 50))
        print("Multimodal fusion stats:")
        print("  Sound events detected: \(eventsDetected)")
        print("  Unique event types: \(Set(soundDetector.eventLog.map { $0.identifier }).count)")
        if !fusionLatencies.isEmpty {
            print("  Fusion latency — mean: \(String(format: "%.0f", stats.mean)) ms, median: \(String(format: "%.0f", stats.median)) ms, p95: \(String(format: "%.0f", stats.p95)) ms  (n=\(stats.count))")
        }
        print("  Elapsed: \(String(format: "%.1f", elapsed))s")
        print("  On-device: confirmed (SoundAnalysis + Vision, no network)")

        if !soundDetector.eventLog.isEmpty {
            print("\n  Event log:")
            var seen = Set<String>()
            for event in soundDetector.eventLog {
                let key = event.identifier
                if !seen.contains(key) {
                    seen.insert(key)
                    print("    \(key): \(String(format: "%.0f", event.confidence * 100))%")
                }
            }
        }
    }
}
