import Foundation
import AVFoundation
import Vision
import CoreML
import AppKit

final class VisionMode: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "aura.vision.processing")
    private let synthesizer = AVSpeechSynthesizer()
    private var detectionModel: VNCoreMLModel?
    private var isProcessing = false
    private var frameCount = 0
    private var processedCount = 0
    private var totalLatencyMs: Double = 0
    private var startTime: Date?
    private var lastSpokenDescription = ""
    private let speakInterval: TimeInterval = 4.0
    private var lastSpeakTime = Date.distantPast

    override init() {
        super.init()
        loadDetectionModel()
    }

    func start() throws {
        guard let camera = AVCaptureDevice.default(for: .video) else {
            print("No camera detected.")
            exit(1)
        }

        let input = try AVCaptureDeviceInput(device: camera)
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .medium

        guard captureSession.canAddInput(input) else {
            print("Cannot add camera input.")
            exit(1)
        }
        captureSession.addInput(input)

        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        guard captureSession.canAddOutput(videoOutput) else {
            print("Cannot add video output.")
            exit(1)
        }
        captureSession.addOutput(videoOutput)
        captureSession.commitConfiguration()

        startTime = Date()
        captureSession.startRunning()
    }

    func stop() {
        captureSession.stopRunning()
        printStats()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameCount += 1

        guard !isProcessing else { return }
        let now = Date()
        guard now.timeIntervalSince(lastSpeakTime) >= speakInterval else { return }

        isProcessing = true
        let frameStart = Date()

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessing = false
            return
        }

        let group = DispatchGroup()
        var detectedObjects: [String] = []
        var detectedText: [String] = []

        group.enter()
        runObjectDetection(on: pixelBuffer) { objects in
            detectedObjects = objects
            group.leave()
        }

        group.enter()
        runOCR(on: pixelBuffer) { texts in
            detectedText = texts
            group.leave()
        }

        group.notify(queue: processingQueue) { [weak self] in
            guard let self else { return }

            let latencyMs = Date().timeIntervalSince(frameStart) * 1000
            self.totalLatencyMs += latencyMs
            self.processedCount += 1

            let description = self.composeDescription(objects: detectedObjects, text: detectedText)

            if !description.isEmpty && description != self.lastSpokenDescription {
                print("\r\u{1B}[2K[\(String(format: "%.0f", latencyMs))ms] \(description)")
                fflush(stdout)
                self.speak(description)
                self.lastSpokenDescription = description
                self.lastSpeakTime = Date()
            }

            self.isProcessing = false
        }
    }

    private func loadDetectionModel() {
        let modelPath = "models/ObjectDetector.mlpackage"
        let url = URL(fileURLWithPath: modelPath)

        guard FileManager.default.fileExists(atPath: modelPath) else {
            print("Object detection model not found at \(modelPath).")
            print("Run: python3 scripts/convert_detection_model.py")
            return
        }

        do {
            let compiledURL = try MLModel.compileModel(at: url)
            let config = MLModelConfiguration()
            config.computeUnits = .all
            let mlModel = try MLModel(contentsOf: compiledURL, configuration: config)
            detectionModel = try VNCoreMLModel(for: mlModel)
            print("Object detection model loaded.")
        } catch {
            print("Failed to load detection model: \(error.localizedDescription)")
        }
    }

    private func runObjectDetection(on pixelBuffer: CVPixelBuffer, completion: @escaping ([String]) -> Void) {
        guard let model = detectionModel else {
            completion([])
            return
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                completion([])
                return
            }

            let minConfidence: Float = 0.4
            var seen = Set<String>()
            var objects: [String] = []

            for observation in results where observation.confidence >= minConfidence {
                if let label = observation.labels.first?.identifier, !seen.contains(label) {
                    seen.insert(label)
                    objects.append(label)
                }
            }

            completion(objects)
        }

        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion([])
        }
    }

    private func runOCR(on pixelBuffer: CVPixelBuffer, completion: @escaping ([String]) -> Void) {
        let request = VNRecognizeTextRequest { request, error in
            guard let results = request.results as? [VNRecognizedTextObservation] else {
                completion([])
                return
            }

            let texts = results.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            completion(texts)
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion([])
        }
    }

    private func composeDescription(objects: [String], text: [String]) -> String {
        var parts: [String] = []

        if !objects.isEmpty {
            let objectList = objects.prefix(5).joined(separator: ", ")
            parts.append("I see \(objectList)")
        }

        if !text.isEmpty {
            let combined = text.prefix(3).joined(separator: "; ")
            parts.append("Text reads: \(combined)")
        }

        if parts.isEmpty {
            return ""
        }

        return parts.joined(separator: ". ") + "."
    }

    private func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    private func printStats() {
        guard let start = startTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        let fps = elapsed > 0 ? Double(frameCount) / elapsed : 0
        let avgLatency = processedCount > 0 ? totalLatencyMs / Double(processedCount) : 0

        print("\n" + String(repeating: "─", count: 40))
        print("Vision mode stats:")
        print("  Total frames: \(frameCount)")
        print("  Processed frames: \(processedCount)")
        print("  Camera FPS: \(String(format: "%.1f", fps))")
        print("  Avg detection+OCR latency: \(String(format: "%.0f", avgLatency)) ms")
        print("  Elapsed: \(String(format: "%.1f", elapsed))s")
    }
}
