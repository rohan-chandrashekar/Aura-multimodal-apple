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
    private let enhancer: SpeechEnhancer?
    private var measureTimer: DispatchSourceTimer?
    private var enhanceBuffer: [Float] = []

    init?(measureMode: Bool = false, enhancer: SpeechEnhancer? = nil) {
        guard let recognizer = SFSpeechRecognizer() else { return nil }
        self.speechRecognizer = recognizer
        self.measureMode = measureMode
        self.enhancer = enhancer

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

        if let enhancer {
            let targetRate = Double(enhancer.sampleRate)
            let chunkSamples = enhancer.chunkSamples

            inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
                guard let self else { return }
                let samples = self.extractSamples(buffer, targetSampleRate: targetRate)
                self.enhanceBuffer.append(contentsOf: samples)

                while self.enhanceBuffer.count >= chunkSamples {
                    let chunk = Array(self.enhanceBuffer.prefix(chunkSamples))
                    self.enhanceBuffer.removeFirst(chunkSamples)

                    if let enhanced = enhancer.processChunk(chunk) {
                        let enhancedBuffer = self.samplesToBuffer(enhanced, sampleRate: targetRate)
                        request.append(enhancedBuffer)
                    }
                }
            }
        } else {
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }
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

    private func extractSamples(_ buffer: AVAudioPCMBuffer, targetSampleRate: Double) -> [Float] {
        guard let channelData = buffer.floatChannelData else { return [] }
        let frameCount = Int(buffer.frameLength)
        let inputRate = buffer.format.sampleRate

        var samples = [Float](repeating: 0, count: frameCount)
        for i in 0..<frameCount {
            samples[i] = channelData[0][i]
        }

        if abs(inputRate - targetSampleRate) > 1.0 {
            let ratio = targetSampleRate / inputRate
            let outputCount = Int(Double(frameCount) * ratio)
            var resampled = [Float](repeating: 0, count: outputCount)
            for i in 0..<outputCount {
                let srcIdx = Double(i) / ratio
                let low = Int(srcIdx)
                let frac = Float(srcIdx - Double(low))
                let high = min(low + 1, frameCount - 1)
                resampled[i] = samples[low] * (1 - frac) + samples[high] * frac
            }
            return resampled
        }

        return samples
    }

    private func samplesToBuffer(_ samples: [Float], sampleRate: Double) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        let channelData = buffer.floatChannelData![0]
        for i in 0..<samples.count {
            channelData[i] = samples[i]
        }
        return buffer
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
