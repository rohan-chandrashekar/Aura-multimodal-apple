import Foundation
import AVFoundation
import SoundAnalysis

struct SoundEvent {
    let identifier: String
    let confidence: Double
    let timestamp: Date
}

final class SoundEventDetector: NSObject, SNResultsObserving {

    private let audioEngine = AVAudioEngine()
    private var analyzer: SNAudioStreamAnalyzer?
    private let analysisQueue = DispatchQueue(label: "aura.sound.analysis")
    private var onEvent: ((SoundEvent) -> Void)?
    var eventLog: [SoundEvent] = []

    private static let relevantKeywords = [
        "alarm", "siren", "doorbell", "knock", "speech", "shout", "scream",
        "cry", "dog", "cat", "horn", "glass", "bell", "telephone", "ring",
        "whistle", "buzzer", "beep", "clap", "snap", "door", "bang",
        "smoke", "fire", "vehicle", "car", "baby", "water", "appliance",
    ]

    func start(onEvent: @escaping (SoundEvent) -> Void) throws {
        self.onEvent = onEvent

        let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
        request.windowDuration = CMTime(seconds: 1.5, preferredTimescale: 48_000)
        request.overlapFactor = 0.5

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard format.channelCount > 0 else {
            print("No microphone detected.")
            exit(1)
        }

        analyzer = SNAudioStreamAnalyzer(format: format)
        try analyzer!.add(request, withObserver: self)

        inputNode.installTap(onBus: 0, bufferSize: 8192, format: format) { [weak self] buffer, time in
            self?.analysisQueue.async {
                self?.analyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        analyzer?.completeAnalysis()
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classification = result as? SNClassificationResult else { return }

        let top = classification.classifications
            .filter { $0.confidence > 0.3 }
            .sorted { $0.confidence > $1.confidence }

        for c in top.prefix(3) {
            let lower = c.identifier.lowercased().replacingOccurrences(of: "_", with: " ")
            let relevant = Self.relevantKeywords.contains { lower.contains($0) }
            if relevant {
                let event = SoundEvent(
                    identifier: c.identifier,
                    confidence: c.confidence,
                    timestamp: Date()
                )
                eventLog.append(event)
                onEvent?(event)
                return
            }
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("Sound analysis error: \(error.localizedDescription)")
    }

    func requestDidComplete(_ request: SNRequest) {}
}
