import Foundation
import AVFoundation
import SoundAnalysis

final class SoundEvaluator: NSObject, SNResultsObserving {

    private var classifications: [String: Double] = [:]
    private var completion: (() -> Void)?

    func evaluateDirectory(_ dirPath: String) {
        let labelsPath = (dirPath as NSString).appendingPathComponent("sound_labels.json")
        let fm = FileManager.default

        guard let data = fm.contents(atPath: labelsPath),
              let labels = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            print("No sound_labels.json found in \(dirPath). Expected format:")
            print("""
            [
              {"file": "alarm.wav", "expected": "alarm"},
              {"file": "speech.wav", "expected": "speech"},
              ...
            ]
            """)
            exit(1)
        }

        print("Evaluating sound classification on \(labels.count) audio files...\n")

        var results: [(String, String, String, Double)] = []

        func processNext(_ index: Int) {
            guard index < labels.count else {
                DispatchQueue.main.async {
                    self.printResults(results)
                    exit(0)
                }
                return
            }

            let entry = labels[index]
            guard let filename = entry["file"] as? String,
                  let expected = entry["expected"] as? String else {
                processNext(index + 1)
                return
            }

            let filePath = (dirPath as NSString).appendingPathComponent(filename)
            guard fm.fileExists(atPath: filePath) else {
                print("  Skipping \(filename) (not found)")
                processNext(index + 1)
                return
            }

            print("  Processing \(filename)...")
            classifyFile(filePath) { topLabel, confidence in
                let detected = topLabel ?? "(none)"
                let conf = confidence
                results.append((filename, expected, detected, conf))
                processNext(index + 1)
            }
        }

        processNext(0)
    }

    private func classifyFile(_ path: String, completion: @escaping (String?, Double) -> Void) {
        let url = URL(fileURLWithPath: path)

        do {
            let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            let analyzer = try SNAudioFileAnalyzer(url: url)

            classifications = [:]
            self.completion = {
                let top = self.classifications.max { $0.value < $1.value }
                completion(top?.key, top?.value ?? 0)
            }

            try analyzer.add(request, withObserver: self)
            analyzer.analyze()
        } catch {
            print("    Error: \(error.localizedDescription)")
            completion(nil, 0)
        }
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classification = result as? SNClassificationResult else { return }

        for c in classification.classifications where c.confidence > 0.1 {
            let current = classifications[c.identifier] ?? 0
            if c.confidence > current {
                classifications[c.identifier] = c.confidence
            }
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("    Classification error: \(error.localizedDescription)")
        completion?()
    }

    func requestDidComplete(_ request: SNRequest) {
        completion?()
    }

    private func printResults(_ results: [(String, String, String, Double)]) {
        var tp = 0, fp = 0, fn = 0

        print("\n" + String(repeating: "═", count: 60))
        print("SOUND CLASSIFICATION RESULTS")
        print(String(repeating: "═", count: 60))

        for (file, expected, detected, conf) in results {
            let detLower = detected.lowercased().replacingOccurrences(of: "_", with: " ")
            let expLower = expected.lowercased()
            let match = detLower.contains(expLower) || expLower.contains(detLower)

            let status = match ? "OK" : "MISS"
            print("  [\(status)] \(file): expected=\(expected), detected=\(detected) (\(String(format: "%.0f", conf * 100))%)")

            if match {
                tp += 1
            } else if detected != "(none)" {
                fp += 1
                fn += 1
            } else {
                fn += 1
            }
        }

        let precision = tp + fp > 0 ? Double(tp) / Double(tp + fp) : 0
        let recall = tp + fn > 0 ? Double(tp) / Double(tp + fn) : 0
        let f1 = precision + recall > 0 ? 2 * precision * recall / (precision + recall) : 0

        print("\n" + String(repeating: "─", count: 60))
        print("Sound-event detection:")
        print("  Precision: \(String(format: "%.1f", precision * 100))%")
        print("  Recall: \(String(format: "%.1f", recall * 100))%")
        print("  F1: \(String(format: "%.1f", f1 * 100))%")
        print("  On-device: confirmed (SNClassifySoundRequest .version1)")
    }
}
