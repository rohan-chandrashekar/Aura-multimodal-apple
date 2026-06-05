import Foundation
import AVFoundation
import Speech

final class FileEvaluator {

    private let speechRecognizer: SFSpeechRecognizer
    private let referenceText: String

    init?(referenceText: String) {
        guard let recognizer = SFSpeechRecognizer() else { return nil }
        self.speechRecognizer = recognizer
        self.referenceText = referenceText
    }

    func evaluateDirectory(_ dirPath: String) {
        let files: [(String, String)] = [
            ("clean", "clean.wav"),
            ("noisy_0dB", "noisy_0dB.wav"),
            ("noisy_5dB", "noisy_5dB.wav"),
            ("noisy_10dB", "noisy_10dB.wav"),
            ("enhanced_0dB", "enhanced_0dB.wav"),
            ("enhanced_5dB", "enhanced_5dB.wav"),
            ("enhanced_10dB", "enhanced_10dB.wav"),
        ]

        print("Evaluating ASR on test audio files...")
        print("Reference: \(referenceText)\n")

        var results: [(String, String, Double)] = []

        func processNext(_ index: Int) {
            guard index < files.count else {
                DispatchQueue.main.async { [self] in
                    self.printResults(results)
                    exit(0)
                }
                return
            }

            let (label, filename) = files[index]
            let filePath = (dirPath as NSString).appendingPathComponent(filename)

            guard FileManager.default.fileExists(atPath: filePath) else {
                print("  Skipping \(filename) (not found)")
                processNext(index + 1)
                return
            }

            print("  Processing \(filename)...")
            recognizeFile(filePath) { transcript in
                let wer = Metrics.wordErrorRate(reference: self.referenceText, hypothesis: transcript ?? "")
                results.append((label, transcript ?? "(no recognition)", wer))
                processNext(index + 1)
            }
        }

        processNext(0)
    }

    private func recognizeFile(_ path: String, completion: @escaping (String?) -> Void) {
        let url = URL(fileURLWithPath: path)

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        if #available(macOS 13, *) {
            request.addsPunctuation = true
        }

        var completed = false

        speechRecognizer.recognitionTask(with: request) { result, error in
            guard !completed else { return }

            if let result, result.isFinal {
                completed = true
                completion(result.bestTranscription.formattedString)
                return
            }

            if let error {
                completed = true
                print("    Recognition error: \(error.localizedDescription)")
                completion(nil)
            }
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
            guard !completed else { return }
            completed = true
            print("    Recognition timed out")
            completion(nil)
        }
    }

    private func printResults(_ results: [(String, String, Double)]) {
        print("\n" + String(repeating: "═", count: 60))
        print("ASR EVALUATION RESULTS (on-device recognition)")
        print(String(repeating: "═", count: 60))

        for (label, transcript, wer) in results {
            print("\n[\(label)]")
            print("  Transcript: \(transcript)")
            print("  WER: \(String(format: "%.1f", wer * 100))%")
        }

        print("\n" + String(repeating: "─", count: 60))
        print("WER Summary:")
        print(String(format: "  %-20s %s", "Condition", "WER (%)"))
        for (label, _, wer) in results {
            print(String(format: "  %-20s %.1f", label, wer * 100))
        }
    }
}
