//
//  AudiowaveRenderer.swift
//  Speezy
//
//  Created by Matt Beaney on 11/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit
import Accelerate

struct AudioData {
    let dBLevels: [Float]
    let percentageLevels: [Float]
    let duration: TimeInterval
    
    func addingDBLevel(_ dB: Float, addedDuration: TimeInterval) -> AudioData {
        var newDBLevels = dBLevels
        newDBLevels.append(dB)
        
        let newPercentageLevels = AudioLevelGenerator.generatePercentageLevels(from: newDBLevels)
        
        return AudioData(
            dBLevels: newDBLevels,
            percentageLevels: newPercentageLevels,
            duration: duration + addedDuration
        )
    }
}

class AudioLevelGenerator {
    
    enum TargetSamples {
        case fitToWidth(width: CGFloat, barSpacing: CGFloat)
        case fitToDuration
    }
    
    typealias AudioLevelCompletion = (AudioData) -> Void
    static func render(fromAudioItem item: AudioItem, targetSamplesPolicy: TargetSamples, completion: @escaping AudioLevelCompletion) {
        self.load(fromAudioURL: item.url) { (context) in
            guard let context = context else {
                completion(
                    AudioData(
                        dBLevels: [],
                        percentageLevels: [],
                        duration: 0.0
                    )
                )
                return
            }
            
            let targetSamples: Int = {
                switch targetSamplesPolicy {
                case .fitToDuration:
                    guard let audioFile = try? AVAudioFile(forReading: item.url) else {
                        assertionFailure("Couldn't load URL \(item.url.absoluteString)")
                        return 100
                    }
                    
                    let audioFilePFormat = audioFile.processingFormat
                    let sampleRate = audioFilePFormat.sampleRate
                    let audioFileLength = audioFile.length

                    let frameSizeToRead = Int(sampleRate / 10)
                    let numberOfFrames = Int(audioFileLength) / frameSizeToRead
                    return numberOfFrames > 0 ? numberOfFrames : 100
                    
                case let .fitToWidth(width, barSpacing):
                    return Int(width / barSpacing)
                }
            }()
            
            let levels = self.render(audioContext: context, targetSamples: targetSamples)
            let seconds = item.duration
            let percentageLevels = self.generatePercentageLevels(from: levels)
            
            completion(
                AudioData(
                    dBLevels: levels,
                    percentageLevels: percentageLevels,
                    duration: seconds
                )
            )
        }
    }
    
    static func generatePercentageLevels(from dB: [Float]) -> [Float] {
        guard let minLevel = dB.sorted().first else {
            return []
        }
        
        let percentageLevels = dB.map {
            ($0 - minLevel) / 85
        }
        
        return percentageLevels
    }
    
    private static func load(
        fromAudioURL audioURL: URL,
        completionHandler: @escaping (_ audioContext: AudioContext?) -> ()
    ) {
        let asset = AVURLAsset(url: audioURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(value: true as Bool)])

        guard let assetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else {
            completionHandler(nil)
            return
        }

        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "duration", error: &error)
            switch status {
            case .loaded:
                guard
                    let formatDescriptions = assetTrack.formatDescriptions as? [CMAudioFormatDescription],
                    let audioFormatDesc = formatDescriptions.first,
                    let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDesc)
                    else { break }

                let totalSamples = Int((asbd.pointee.mSampleRate) * Float64(asset.duration.value) / Float64(asset.duration.timescale))
                let audioContext = AudioContext(audioURL: audioURL, totalSamples: totalSamples, asset: asset, assetTrack: assetTrack)
                completionHandler(audioContext)
                return

            case .failed, .cancelled, .loading, .unknown:
                print("Couldn't load asset: \(error?.localizedDescription ?? "Unknown error")")
            }

            completionHandler(nil)
        }
    }
    
    private static func render(audioContext: AudioContext?, targetSamples: Int) -> [Float] {
        guard let audioContext = audioContext else {
            fatalError("Couldn't create the audioContext")
        }

        let sampleRange: CountableRange<Int> = 0..<audioContext.totalSamples

        guard let reader = try? AVAssetReader(asset: audioContext.asset)
            else {
                fatalError("Couldn't initialize the AVAssetReader")
        }

        reader.timeRange = CMTimeRange(start: CMTime(value: Int64(sampleRange.lowerBound), timescale: audioContext.asset.duration.timescale),
                                       duration: CMTime(value: Int64(sampleRange.count), timescale: audioContext.asset.duration.timescale))

        let outputSettingsDict: [String : Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        let readerOutput = AVAssetReaderTrackOutput(track: audioContext.assetTrack, outputSettings: outputSettingsDict)
        readerOutput.alwaysCopiesSampleData = false
        reader.add(readerOutput)

        var channelCount = 1
        let formatDescriptions = audioContext.assetTrack.formatDescriptions as! [CMAudioFormatDescription]
        for item in formatDescriptions {
            guard let fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item) else {
                fatalError("Couldn't get the format description")
            }
            channelCount = Int(fmtDesc.pointee.mChannelsPerFrame)
        }

        let samplesPerPixel = max(1, channelCount * sampleRange.count / targetSamples)
        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)

        var outputSamples = [Float]()
        var sampleBuffer = Data()

        // 16-bit samples
        reader.startReading()
        defer { reader.cancelReading() }

        while reader.status == .reading {
            guard let readSampleBuffer = readerOutput.copyNextSampleBuffer(),
                let readBuffer = CMSampleBufferGetDataBuffer(readSampleBuffer) else {
                    break
            }
            // Append audio sample buffer into our current sample buffer
            var readBufferLength = 0
            var readBufferPointer: UnsafeMutablePointer<Int8>?
            CMBlockBufferGetDataPointer(
                readBuffer,
                atOffset: 0,
                lengthAtOffsetOut: &readBufferLength,
                totalLengthOut: nil,
                dataPointerOut: &readBufferPointer
            )
            sampleBuffer.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
            CMSampleBufferInvalidate(readSampleBuffer)

            let totalSamples = sampleBuffer.count / MemoryLayout<Int16>.size
            let downSampledLength = totalSamples / samplesPerPixel
            let samplesToProcess = downSampledLength * samplesPerPixel

            guard samplesToProcess > 0 else { continue }

            outputSamples += processSamples(
                fromData: &sampleBuffer,
                samplesToProcess: samplesToProcess,
                downSampledLength: downSampledLength,
                samplesPerPixel: samplesPerPixel,
                filter: filter
            )
        }

        // Process the remaining samples at the end which didn't fit into samplesPerPixel
        let samplesToProcess = sampleBuffer.count / MemoryLayout<Int16>.size
        if samplesToProcess > 0 {
            let downSampledLength = 1
            let samplesPerPixel = samplesToProcess
            let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)

            outputSamples += processSamples(
                fromData: &sampleBuffer,
                samplesToProcess: samplesToProcess,
                downSampledLength: downSampledLength,
                samplesPerPixel: samplesPerPixel,
                filter: filter
            )
        }

        // if (reader.status == AVAssetReaderStatusFailed || reader.status == AVAssetReaderStatusUnknown)
        guard reader.status == .completed else {
            fatalError("Couldn't read the audio file")
        }

        return outputSamples
    }
    
    private static func processSamples(
        fromData sampleBuffer: inout Data,
        samplesToProcess: Int,
        downSampledLength: Int,
        samplesPerPixel: Int,
        filter: [Float]
    ) -> [Float] {
        return sampleBuffer.withUnsafeBytes { (samples) -> [Float] in
            var processingBuffer = [Float](repeating: 0.0, count: samplesToProcess)

            let sampleCount = vDSP_Length(samplesToProcess)
            
            let unsafeBufferPointer = samples.bindMemory(to: Int16.self)
            let unsafePointer = unsafeBufferPointer.baseAddress!

            //Convert 16bit int samples to floats
            vDSP_vflt16(unsafePointer, 1, &processingBuffer, 1, sampleCount)

            //Take the absolute values to get amplitude
            vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, sampleCount)

            //get the corresponding dB, and clip the results
            getdB(from: &processingBuffer)

            //Downsample and average
            var downSampledData = [Float](repeating: 0.0, count: downSampledLength)
            vDSP_desamp(processingBuffer,
                        vDSP_Stride(samplesPerPixel),
                        filter, &downSampledData,
                        vDSP_Length(downSampledLength),
                        vDSP_Length(samplesPerPixel))

            //Remove processed samples
            sampleBuffer.removeFirst(samplesToProcess * MemoryLayout<Int16>.size)

            return downSampledData
        }
    }
    
    private static func getdB(from normalizedSamples: inout [Float]) {
        // Convert samples to a log scale
        var zero: Float = 32768.0
        vDSP_vdbcon(
            normalizedSamples,
            1,
            &zero,
            &normalizedSamples,
            1,
            vDSP_Length(normalizedSamples.count),
            1
        )

        //Clip to [noiseFloor, 0]
        var ceil: Float = 0.0
        var noiseFloorMutable: Float = -80.0
        vDSP_vclip(
            normalizedSamples,
            1,
            &noiseFloorMutable,
            &ceil,
            &normalizedSamples,
            1,
            vDSP_Length(normalizedSamples.count)
        )
    }
}
