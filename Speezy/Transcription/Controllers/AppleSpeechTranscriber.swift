//
//  AppleSpeechTranscriber.swift
//  Speezy
//
//  Created by Matt Beaney on 13/09/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import Speech

class AppleSpeechTranscriber: NSObject {
    var recognizer: SFSpeechRecognizer!
    var task: SFSpeechRecognitionTask!
    
    var completion: ((Transcript) -> Void)?
    
    func transcribe(url: URL, completion: @escaping (Transcript) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_GB"))
                    let request = SFSpeechURLRecognitionRequest(url: Bundle.main.url(forResource: "transcription-test-file", withExtension: "wav")!)
//                    request.requiresOnDeviceRecognition = true
//                    request.shouldReportPartialResults = false
                    
                    // start recognition!
                    self.task = self.recognizer.recognitionTask(with: request) { (result, error) in
                        // abort if we didn't get any transcription back
                        guard let result = result else {
                            print("There was an error: \(error!)")
                            return
                        }

                        // if we got the final transcription back, print it
                        print(result.bestTranscription.formattedString)
                        if result.isFinal {

                            let words: [Word] = result.bestTranscription.segments.map {
                                Word(
                                    text: $0.substring,
                                    timestamp: Timestamp(start: $0.timestamp, end: $0.timestamp + $0.duration)
                                )
                            }

                            let transcript = Transcript(words: words)
                            completion(transcript)
                        }
                    }
                }
            }
        }
    }
}
