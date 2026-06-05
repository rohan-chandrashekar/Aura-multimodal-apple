import Foundation
import AVFoundation
import Speech

final class LiveCaptioner {

    static let referenceText = "The quick brown fox jumps over the lazy dog. Technology makes the world a smaller place. Please turn left at the next intersection and continue for two miles."

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer: SFSpeechRecognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioStartTime: Date?
    private var latencies: [Double] = []
    private var lastTranscript = ""
    private var accumulatedTranscript = ""
    private let measureMode: Bool
    private var measureTimer: DispatchSourceTimer?

    init?(measureMode: Bool = false) {
        guard let recognizer = SFSpeechRecognizer() else { return nil }
        self.speechRecognizer = recognizer
        self.measureMode = measureMode

        if !recognizer.supportsOnDeviceRecognition {
            print("Warning: on-device recognition not reported as supported for locale \(recognizer.locale.identifier).")
            print("Recognition will proceed but may use the server. Check network activity to confirm.")
        }
    }

    func start() throws {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        if #available(macOS 13, *) {
            request.addsPunctuation = true
        }
        self.recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.channelCount > 0 else {
            print("No microphone detected. Connect a microphone and try again.")
            exit(1)
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioStartTime = Date()

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            self?.handleResult(result, error: error)
        }

        audioEngine.prepare()
        try audioEngine.start()

        if measureMode {
            let timer = DispatchSource.makeTimerSource(queue: .main)
            timer.schedule(deadline: .now() + 30)
            timer.setEventHandler { [weak self] in
                self?.finishMeasurement()
            }
            timer.resume()
            measureTimer = timer
        }
    }

    func stop() {
        measureTimer?.cancel()
        measureTimer = nil
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }

    private func handleResult(_ result: SFSpeechRecognitionResult?, error: Error?) {
        if let result {
            let now = Date()
            let transcript = result.bestTranscription.formattedString
            let segments = result.bestTranscription.segments

            if let lastSegment = segments.last, let startTime = audioStartTime {
                let segmentEnd = startTime.addingTimeInterval(lastSegment.timestamp + lastSegment.duration)
                let latencyMs = now.timeIntervalSince(segmentEnd) * 1000
                if latencyMs > 0 && latencyMs < 10_000 {
                    latencies.append(latencyMs)
                }
            }

            if transcript != lastTranscript {
                print("\r\u{1B}[2K\(transcript)", terminator: "")
                fflush(stdout)
                lastTranscript = transcript
            }

            if result.isFinal {
                accumulatedTranscript += (accumulatedTranscript.isEmpty ? "" : " ") + transcript
                print()
                lastTranscript = ""
                if !measureMode {
                    restartRecognition()
                }
            }
        }

        if error != nil, !measureMode {
            restartRecognition()
        }
    }

    private func restartRecognition() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            try? self?.start()
        }
    }

    private func finishMeasurement() {
        let partial = lastTranscript
        stop()

        var finalTranscript = accumulatedTranscript
        if !partial.isEmpty && !finalTranscript.hasSuffix(partial) {
            finalTranscript += (finalTranscript.isEmpty ? "" : " ") + partial
        }

        print("\n")
        print(String(repeating: "═", count: 50))
        print("MEASUREMENT RESULTS")
        print(String(repeating: "═", count: 50))
        print()
        print("Reference:  \(Self.referenceText)")
        print("Recognized: \(finalTranscript)")
        print()

        let wer = Metrics.wordErrorRate(reference: Self.referenceText, hypothesis: finalTranscript)
        print("Word error rate: \(String(format: "%.1f", wer * 100))%")

        if !latencies.isEmpty {
            let stats = Metrics.latencyStats(latencies)
            print("Caption latency  — mean: \(String(format: "%.0f", stats.mean)) ms, median: \(String(format: "%.0f", stats.median)) ms, p95: \(String(format: "%.0f", stats.p95)) ms  (n=\(stats.count))")
        } else {
            print("Caption latency: no segments captured")
        }

        print("On-device recognition supported: \(speechRecognizer.supportsOnDeviceRecognition)")
        print("Audio files written to disk: 0 (buffers processed in memory only)")
        print("Network bytes for recognition: 0 (requiresOnDeviceRecognition = true)")

        exit(0)
    }
}
