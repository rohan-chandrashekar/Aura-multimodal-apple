import Foundation
import Vision
import CoreML
import AppKit

final class VisionEvaluator {

    private var detectionModel: VNCoreMLModel?

    init() {
        let modelPath = "models/ObjectDetector.mlpackage"
        let url = URL(fileURLWithPath: modelPath)
        if let mlModel = try? MLModel(contentsOf: url),
           let vnModel = try? VNCoreMLModel(for: mlModel) {
            detectionModel = vnModel
        }
    }

    func evaluateDirectory(_ dirPath: String) {
        let fm = FileManager.default
        let labelsPath = (dirPath as NSString).appendingPathComponent("labels.json")

        guard let data = fm.contents(atPath: labelsPath),
              let labels = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            print("No labels.json found in \(dirPath). Expected format:")
            print("""
            [
              {"file": "image1.jpg", "objects": ["person", "laptop"], "text": ["Hello World"]},
              ...
            ]
            """)
            exit(1)
        }

        print("Evaluating vision pipeline on \(labels.count) labeled images...\n")

        var totalDetectionTP = 0
        var totalDetectionFP = 0
        var totalDetectionFN = 0
        var totalOcrTP = 0
        var totalOcrFP = 0
        var totalOcrFN = 0
        var latencies: [Double] = []

        for entry in labels {
            guard let filename = entry["file"] as? String else { continue }
            let expectedObjects = (entry["objects"] as? [String]) ?? []
            let expectedText = (entry["text"] as? [String]) ?? []
            let imagePath = (dirPath as NSString).appendingPathComponent(filename)

            guard let image = NSImage(contentsOfFile: imagePath),
                  let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                print("  Skipping \(filename) (cannot load)")
                continue
            }

            let start = Date()
            let (detectedObjects, detectedText) = processImage(cgImage)
            let latencyMs = Date().timeIntervalSince(start) * 1000
            latencies.append(latencyMs)

            let detNorm = Set(detectedObjects.map { $0.lowercased() })
            let expNorm = Set(expectedObjects.map { $0.lowercased() })
            let detTP = detNorm.intersection(expNorm).count
            let detFP = detNorm.subtracting(expNorm).count
            let detFN = expNorm.subtracting(detNorm).count

            totalDetectionTP += detTP
            totalDetectionFP += detFP
            totalDetectionFN += detFN

            let ocrNorm = Set(detectedText.map { $0.lowercased().trimmingCharacters(in: .whitespaces) })
            let expTextNorm = Set(expectedText.map { $0.lowercased().trimmingCharacters(in: .whitespaces) })
            var ocrTP = 0
            for expected in expTextNorm {
                if ocrNorm.contains(where: { $0.contains(expected) || expected.contains($0) }) {
                    ocrTP += 1
                }
            }
            let ocrFN = expTextNorm.count - ocrTP
            let ocrFP = max(0, ocrNorm.count - ocrTP)

            totalOcrTP += ocrTP
            totalOcrFP += ocrFP
            totalOcrFN += ocrFN

            print("[\(filename)] \(String(format: "%.0f", latencyMs))ms")
            print("  Objects expected: \(expectedObjects)  detected: \(detectedObjects)")
            print("  Text expected: \(expectedText)  detected: \(detectedText)")
        }

        let detPrecision = totalDetectionTP + totalDetectionFP > 0
            ? Double(totalDetectionTP) / Double(totalDetectionTP + totalDetectionFP) : 0
        let detRecall = totalDetectionTP + totalDetectionFN > 0
            ? Double(totalDetectionTP) / Double(totalDetectionTP + totalDetectionFN) : 0
        let detF1 = detPrecision + detRecall > 0
            ? 2 * detPrecision * detRecall / (detPrecision + detRecall) : 0

        let ocrPrecision = totalOcrTP + totalOcrFP > 0
            ? Double(totalOcrTP) / Double(totalOcrTP + totalOcrFP) : 0
        let ocrRecall = totalOcrTP + totalOcrFN > 0
            ? Double(totalOcrTP) / Double(totalOcrTP + totalOcrFN) : 0
        let ocrF1 = ocrPrecision + ocrRecall > 0
            ? 2 * ocrPrecision * ocrRecall / (ocrPrecision + ocrRecall) : 0

        let stats = Metrics.latencyStats(latencies)

        print("\n" + String(repeating: "═", count: 55))
        print("VISION EVALUATION RESULTS")
        print(String(repeating: "═", count: 55))
        print()
        print("Object detection (YOLOv8n, 80 COCO classes):")
        print("  Precision: \(String(format: "%.1f", detPrecision * 100))%")
        print("  Recall: \(String(format: "%.1f", detRecall * 100))%")
        print("  F1: \(String(format: "%.1f", detF1 * 100))%")
        print()
        print("OCR (VNRecognizeTextRequest, accurate mode):")
        print("  Precision: \(String(format: "%.1f", ocrPrecision * 100))%")
        print("  Recall: \(String(format: "%.1f", ocrRecall * 100))%")
        print("  F1: \(String(format: "%.1f", ocrF1 * 100))%")
        print()
        print("Latency per frame — mean: \(String(format: "%.0f", stats.mean)) ms, median: \(String(format: "%.0f", stats.median)) ms, p95: \(String(format: "%.0f", stats.p95)) ms  (n=\(stats.count))")
        print("Frames written to disk: 0")

        exit(0)
    }

    private func processImage(_ cgImage: CGImage) -> ([String], [String]) {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        var objects: [String] = []
        var texts: [String] = []

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
        ocrRequest.recognitionLevel = .accurate
        ocrRequest.usesLanguageCorrection = true
        try? handler.perform([ocrRequest])

        return (objects, texts)
    }
}
