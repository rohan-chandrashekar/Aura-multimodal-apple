import Foundation
import AVFoundation
import Speech
import Vision
import CoreML
import AppKit

final class FairnessEvaluator {

    private let speechRecognizer: SFSpeechRecognizer?

    init() {
        speechRecognizer = SFSpeechRecognizer()
    }

    func evaluateSpeechFairness(_ dirPath: String) {
        let labelsPath = (dirPath as NSString).appendingPathComponent("accent_labels.json")

        guard let data = FileManager.default.contents(atPath: labelsPath),
              let entries = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            print("No accent_labels.json found in \(dirPath).")
            exit(1)
        }

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("Speech recognizer unavailable.")
            exit(1)
        }

        print("Evaluating speech WER across accents (\(entries.count) voices)...\n")

        var results: [[String: Any]] = []

        func processNext(_ index: Int) {
            guard index < entries.count else {
                DispatchQueue.main.async {
                    self.writeSpeechResults(results, to: dirPath)
                    exit(0)
                }
                return
            }

            let entry = entries[index]
            guard let filename = entry["file"] as? String,
                  let reference = entry["reference"] as? String,
                  let accent = entry["accent"] as? String else {
                processNext(index + 1)
                return
            }

            let filePath = (dirPath as NSString).appendingPathComponent(filename)
            guard FileManager.default.fileExists(atPath: filePath) else {
                print("  Skipping \(filename)")
                processNext(index + 1)
                return
            }

            print("  [\(accent)] Processing \(filename)...")
            let start = Date()

            let url = URL(fileURLWithPath: filePath)
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.requiresOnDeviceRecognition = true
            request.shouldReportPartialResults = false
            if #available(macOS 13, *) {
                request.addsPunctuation = true
            }

            var done = false

            recognizer.recognitionTask(with: request) { result, error in
                guard !done else { return }

                if let result, result.isFinal {
                    done = true
                    let latencyMs = Date().timeIntervalSince(start) * 1000
                    let transcript = result.bestTranscription.formattedString
                    let wer = Metrics.wordErrorRate(reference: reference, hypothesis: transcript)

                    print("    WER: \(String(format: "%.1f", wer * 100))%  (\(String(format: "%.0f", latencyMs))ms)")

                    var r: [String: Any] = entry
                    r["transcript"] = transcript
                    r["wer"] = wer
                    r["latency_ms"] = latencyMs
                    results.append(r)
                    processNext(index + 1)
                }

                if let error {
                    done = true
                    print("    Error: \(error.localizedDescription)")
                    var r: [String: Any] = entry
                    r["transcript"] = ""
                    r["wer"] = 1.0
                    r["latency_ms"] = 0.0
                    results.append(r)
                    processNext(index + 1)
                }
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
                guard !done else { return }
                done = true
                print("    Timed out")
                var r: [String: Any] = entry
                r["transcript"] = ""
                r["wer"] = 1.0
                r["latency_ms"] = 0.0
                results.append(r)
                processNext(index + 1)
            }
        }

        processNext(0)
    }

    func evaluateVisionFairness(_ dirPath: String) {
        let labelsPath = (dirPath as NSString).appendingPathComponent("lighting_labels.json")

        guard let data = FileManager.default.contents(atPath: labelsPath),
              let entries = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            print("No lighting_labels.json found in \(dirPath).")
            exit(1)
        }

        print("Evaluating OCR across lighting conditions (\(entries.count) levels)...\n")

        var results: [[String: Any]] = []

        for entry in entries {
            guard let filename = entry["file"] as? String,
                  let expectedText = entry["expected_text"] as? [String],
                  let level = entry["level"] as? String else { continue }

            let filePath = (dirPath as NSString).appendingPathComponent(filename)
            guard let image = NSImage(contentsOfFile: filePath),
                  let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                print("  Skipping \(filename)")
                continue
            }

            print("  [\(level)] Processing \(filename)...")
            let start = Date()

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            var detectedText: [String] = []

            let ocrRequest = VNRecognizeTextRequest { request, _ in
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                detectedText = observations.compactMap { $0.topCandidates(1).first?.string }
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            }
            ocrRequest.recognitionLevel = .accurate
            ocrRequest.usesLanguageCorrection = true
            try? handler.perform([ocrRequest])

            let latencyMs = Date().timeIntervalSince(start) * 1000

            let expSet = Set(expectedText.map { $0.lowercased() })
            let detSet = Set(detectedText.map { $0.lowercased().trimmingCharacters(in: .whitespaces) })
            var tp = 0
            for exp in expSet {
                if detSet.contains(where: { $0.contains(exp) || exp.contains($0) }) {
                    tp += 1
                }
            }
            let recall = expSet.count > 0 ? Double(tp) / Double(expSet.count) : 1.0

            print("    Recall: \(String(format: "%.0f", recall * 100))%  detected: \(detectedText)  (\(String(format: "%.0f", latencyMs))ms)")

            var r: [String: Any] = entry
            r["detected_text"] = detectedText
            r["recall"] = recall
            r["latency_ms"] = latencyMs
            results.append(r)
        }

        writeVisionResults(results, to: dirPath)
        exit(0)
    }

    private func writeSpeechResults(_ results: [[String: Any]], to dirPath: String) {
        let outPath = (dirPath as NSString).appendingPathComponent("speech_results.json")
        if let data = try? JSONSerialization.data(withJSONObject: results, options: .prettyPrinted) {
            FileManager.default.createFile(atPath: outPath, contents: data)
        }

        print("\n" + String(repeating: "═", count: 55))
        print("SPEECH FAIRNESS RESULTS")
        print(String(repeating: "═", count: 55))
        print("\n  " + "Accent".padding(toLength: 15, withPad: " ", startingAt: 0) + " " + "WER (%)".padding(toLength: 10, withPad: " ", startingAt: 0) + " Latency (ms)")
        print("  " + String(repeating: "─", count: 45))

        var wers: [Double] = []
        for r in results {
            let accent = r["accent"] as? String ?? "?"
            let wer = r["wer"] as? Double ?? 1.0
            let lat = r["latency_ms"] as? Double ?? 0
            wers.append(wer)
            print("  " + accent.padding(toLength: 15, withPad: " ", startingAt: 0) + " " + String(format: "%.1f", wer * 100).padding(toLength: 10, withPad: " ", startingAt: 0) + " " + String(format: "%.0f", lat))
        }

        if let minWer = wers.min(), let maxWer = wers.max() {
            let disparity = (maxWer - minWer) * 100
            let mean = wers.reduce(0, +) / Double(wers.count) * 100
            print("\n  Mean WER: \(String(format: "%.1f", mean))%")
            print("  Min WER: \(String(format: "%.1f", minWer * 100))%  Max WER: \(String(format: "%.1f", maxWer * 100))%")
            print("  Disparity (max - min): \(String(format: "%.1f", disparity)) pp")
        }

        print("\n  Results saved to \(outPath)")
    }

    private func writeVisionResults(_ results: [[String: Any]], to dirPath: String) {
        let outPath = (dirPath as NSString).appendingPathComponent("vision_results.json")
        if let data = try? JSONSerialization.data(withJSONObject: results, options: .prettyPrinted) {
            FileManager.default.createFile(atPath: outPath, contents: data)
        }

        print("\n" + String(repeating: "═", count: 55))
        print("VISION FAIRNESS RESULTS")
        print(String(repeating: "═", count: 55))
        print("\n  " + "Condition".padding(toLength: 20, withPad: " ", startingAt: 0) + " " + "Recall (%)".padding(toLength: 12, withPad: " ", startingAt: 0) + " Latency (ms)")
        print("  " + String(repeating: "─", count: 50))

        var recalls: [Double] = []
        for r in results {
            let level = r["level"] as? String ?? "?"
            let recall = r["recall"] as? Double ?? 0
            let lat = r["latency_ms"] as? Double ?? 0
            recalls.append(recall)
            print("  " + level.padding(toLength: 20, withPad: " ", startingAt: 0) + " " + String(format: "%.0f", recall * 100).padding(toLength: 12, withPad: " ", startingAt: 0) + " " + String(format: "%.0f", lat))
        }

        if let minR = recalls.min(), let maxR = recalls.max() {
            let disparity = (maxR - minR) * 100
            print("\n  Disparity (max - min): \(String(format: "%.0f", disparity)) pp")
        }

        print("\n  Results saved to \(outPath)")
    }
}
