//
//  TranscriptManager.swift
//  Speezy
//
//  Created by Matt Beaney on 27/10/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit

protocol TranscriptManagerDelegate: AnyObject {
    func transcriptManager(
        _ manager: TranscriptManager,
        didFinishEditingTranscript transcript: Transcript
    )
    
    func transcriptManager(
        _ manager: TranscriptManager,
        shouldCutItemWithRanges ranges: [CMTimeRange]
    )
}

class TranscriptManager {
    weak var delegate: TranscriptManagerDelegate?
    
    private var selectedWords: [Word] = []
    
    private(set) var transcript: Transcript?
    
    var transcriptExists: Bool {
        transcript != nil
    }
    
    let audioItemId: String
    
    init(audioItemId: String) {
        self.audioItemId = audioItemId
        self.transcript = TranscriptStorage.fetchTranscript(id: audioItemId)
    }
    
    func adjustTranscript(forCutOperationFromStartPoint start: TimeInterval, end: TimeInterval) {
        guard let transcript = transcript else {
            return
        }
        
        let newWords: [Word] = transcript.words.compactMap {
            // If the word exists within the manually cut duration, remove it altogether.
            let wordIsWithinChoppedRange = $0.timestamp.start > start && $0.timestamp.end < end
            
            // If the start of the manually cut duration is inside a word, also remove the word.
            let choppedRangeIsWithinWord = start > $0.timestamp.start && start < $0.timestamp.end
            
            if wordIsWithinChoppedRange || choppedRangeIsWithinWord {
                return nil
            }
            
            // If the words duration is after the cut with no overlaps,
            // then we need to offset the words timestamp by the
            // length of the cut duration
            let duration = end - start
            if $0.timestamp.start > end {
                return Word(
                    text: $0.text,
                    timestamp: Timestamp(
                        start: $0.timestamp.start - duration,
                        end: $0.timestamp.end - duration
                    )
                )
            }
            
            return $0
        }
        
        updateTranscript(Transcript(words: newWords))
        saveTranscript()
        
        print(transcript)
    }
    
    func removeUhms() {
        selectedWords = transcript?.words.compactMap {
            $0.text.contains("HESITATION") ? $0 : nil
        } ?? []
        
        removeSelectedWords()
    }
    
    func removeSelectedWords() {
        cut(selectedWords)
    }
    
    func updateTranscript(_ transcript: Transcript) {
        self.transcript = transcript
    }
    
    func saveTranscript() {
        guard let transcript = self.transcript else {
            return
        }
        
        TranscriptStorage.save(transcript, id: audioItemId)
    }
    
    func clearSelectedWords() {
        selectedWords = []
    }
    
    func updateTranscriptRemovingSelectedWords() {
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
            
            self.delegate?.transcriptManager(
                self,
                didFinishEditingTranscript: newTranscript
            )
        }
    }
    
    private func cut(_ range: [Word]) {
        let timeRanges: [CMTimeRange] = range.reversed().map {
            let startTime = CMTime(seconds: $0.timestamp.start, preferredTimescale: 100)
            let endTime = CMTime(seconds: $0.timestamp.end, preferredTimescale: 100)
            return CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        }
        
        delegate?.transcriptManager(self, shouldCutItemWithRanges: timeRanges)
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
