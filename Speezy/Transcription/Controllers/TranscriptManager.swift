//
//  TranscriptManager.swift
//  Speezy
//
//  Created by Matt Beaney on 27/10/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit

protocol TranscriptObserver: AnyObject {
    func transcriptManager(
        _ manager: TranscriptManager,
        didFinishEditingTranscript transcript: Transcript
    )
}

struct TranscriptObservation {
    weak var observer: TranscriptObserver?
}

class TranscriptManager {
    private let audioManager: AudioManager
    private var selectedWords: [Word] = []
    private var transcriptObservatons = [ObjectIdentifier : TranscriptObservation]()
    
    var transcript: Transcript? {
        TranscriptStorage.fetchTranscript(id: audioManager.item.id)
    }
    
    var transcriptExists: Bool {
        transcript != nil
    }
    
    init(audioManager: AudioManager) {
        self.audioManager = audioManager
        
        audioManager.addCropperObserver(self)
    }
    
    func removeUhms() {
        selectedWords = transcript?.words.compactMap {
            $0.text.contains("HESITATION") ? $0 : nil
        } ?? []
        
        removeSelectedWords()
    }
    
    func removeSelectedWords() {
        cut(audioItem: audioManager.item, from: selectedWords)
    }
    
    func updateTranscript(_ transcript: Transcript) {
        TranscriptStorage.save(transcript, id: audioManager.item.id)
    }
    
    private func adjustCurrentTranscript() {
        let orderedSelectedWords = selectedWords.sorted {
            $0.timestamp.start > $1.timestamp.start
        }
        
        // Run through each selected word in reverse order.
        // Find any words with a start time greater than that word.
        // Adjust their start times by subtracting the duration of the selected word.
        orderedSelectedWords.forEach { (selectedWord) in
            let duration = selectedWord.timestamp.end - selectedWord.timestamp.start
            
            let newWords = transcript?.words.compactMap({ (word) -> Word? in
                if self.selectedWords.contains(word) {
                    return nil
                }
                
                if word.timestamp.start > selectedWord.timestamp.start {
                    return Word(
                        text: word.text,
                        timestamp: Timestamp(
                            start: word.timestamp.start - duration,
                            end: word.timestamp.end - duration
                        )
                    )
                } else {
                    return word
                }
            }) ?? []
            
            let newTranscript = Transcript(words: newWords)
            self.updateTranscript(newTranscript)
            self.selectedWords = []
            
            self.transcriptObservatons.forEach {
                $0.value.observer?.transcriptManager(self, didFinishEditingTranscript: newTranscript)
            }
        }
    }
    
    private func cut(
        audioItem: AudioItem,
        from range: [Word]
    ) {
        let timeRanges: [CMTimeRange] = range.reversed().map {
            let startTime = CMTime(seconds: $0.timestamp.start, preferredTimescale: 100)
            let endTime = CMTime(seconds: $0.timestamp.end, preferredTimescale: 100)
            return CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        }
        
        audioManager.cut(timeRanges: timeRanges)
    }
}

extension TranscriptManager {
    var numberOfWords: Int {
        transcript?.words.count ?? 0
    }
    
    func word(for index: Int) -> Word? {
        transcript?.words[index]
    }
    
    func isSelected(word: Word) -> Bool {
        selectedWords.contains(word)
    }
    
    func toggleSelection(at indexPath: IndexPath) {
        guard let selectedWord = transcript?.words[indexPath.row] else {
            assertionFailure("No transcript found.")
            return
        }
        
        if let indexOfWord = selectedWords.firstIndex(of: selectedWord) {
            selectedWords.remove(at: indexOfWord)
        } else {
            selectedWords.append(selectedWord)
        }
    }
    
    func currentPlayingWord(at time: TimeInterval) -> Word? {
        transcript?.words.first {
            $0.timestamp.start < time && $0.timestamp.end > time
        }
    }
    
    func currentPlayingWordIndex(at time: TimeInterval) -> Int? {
        guard
            let activeWord = currentPlayingWord(at: time),
            let indexOfWord = transcript?.words.firstIndex(of: activeWord)
        else {
            return nil
        }
        
        return indexOfWord
    }
}

extension TranscriptManager: AudioCropperObserver {
    func audioManager(_ manager: AudioManager, didFinishCroppingItem item: AudioItem) {
        adjustCurrentTranscript()
    }
    
    func audioManager(_ manager: AudioManager, didStartCroppingItem item: AudioItem, kind: CropKind) {}
    func audioManager(_ manager: AudioManager, didAdjustCropOnItem item: AudioItem) {}
    func audioManager(_ manager: AudioManager, didMoveLeftCropHandleTo percentage: CGFloat) {}
    func audioManager(_ manager: AudioManager, didMoveRightCropHandleTo percentage: CGFloat) {}
    func audioManagerDidCancelCropping(_ manager: AudioManager) {}
}

extension TranscriptManager {
    func addTranscriptObserver(_ observer: TranscriptObserver) {
        let id = ObjectIdentifier(observer)
        transcriptObservatons[id] = TranscriptObservation(observer: observer)
    }
}
