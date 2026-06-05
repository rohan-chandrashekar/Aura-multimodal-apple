import Foundation
import CoreML
import AVFoundation

final class SpeechEnhancer {

    private let model: MLModel
    let chunkSamples: Int
    let sampleRate: Int

    init(modelPath: String, sampleRate: Int = 16000, chunkSeconds: Int = 4) throws {
        let url = URL(fileURLWithPath: modelPath)
        let config = MLModelConfiguration()
        config.computeUnits = .all
        self.model = try MLModel(contentsOf: url, configuration: config)
        self.sampleRate = sampleRate
        self.chunkSamples = sampleRate * chunkSeconds
    }

    func enhance(samples: [Float]) -> [Float] {
        let length = samples.count
        let paddedLength = ((length + chunkSamples - 1) / chunkSamples) * chunkSamples
        var padded = [Float](repeating: 0, count: paddedLength)
        padded[0..<length] = samples[0..<length]

        var enhanced = [Float](repeating: 0, count: paddedLength)

        for start in stride(from: 0, to: paddedLength, by: chunkSamples) {
            let chunk = Array(padded[start..<start + chunkSamples])
            if let output = processChunk(chunk) {
                enhanced[start..<start + chunkSamples] = output[0..<chunkSamples]
            } else {
                enhanced[start..<start + chunkSamples] = padded[start..<start + chunkSamples]
            }
        }

        return Array(enhanced[0..<length])
    }

    func processChunk(_ chunk: [Float]) -> [Float]? {
        guard chunk.count == chunkSamples else { return nil }

        let shape: [NSNumber] = [1, 1, NSNumber(value: chunkSamples)]
        guard let inputArray = try? MLMultiArray(shape: shape, dataType: .float32) else {
            return nil
        }

        let ptr = inputArray.dataPointer.bindMemory(to: Float.self, capacity: chunkSamples)
        for i in 0..<chunkSamples {
            ptr[i] = chunk[i]
        }

        let provider = try? MLDictionaryFeatureProvider(
            dictionary: ["audio": MLFeatureValue(multiArray: inputArray)]
        )
        guard let provider, let prediction = try? model.prediction(from: provider) else {
            return nil
        }

        guard let outputArray = prediction.featureValue(for: "enhanced")?.multiArrayValue else {
            return nil
        }

        var result = [Float](repeating: 0, count: chunkSamples)
        let outPtr = outputArray.dataPointer.bindMemory(to: Float.self, capacity: chunkSamples)
        for i in 0..<chunkSamples {
            result[i] = outPtr[i]
        }

        return result
    }
}
