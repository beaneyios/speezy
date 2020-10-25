//
//  TranscriptionJobManager.swift
//  Speezy
//
//  Created by Matt Beaney on 25/10/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

protocol TranscriptionObserver: AnyObject {
    func transcriptionJobManager(
        _ manager: TranscriptionJobManager,
        didFinishTranscribingWithAudioItemId: String,
        transcript: Transcript
    )
    
    func transcriptionJobManager(
        _ manager: TranscriptionJobManager,
        didQueueTranscriptionJobWithAudioItemId: String
    )
}

struct TranscriptionObservation {
    weak var observer: TranscriptionObserver?
}

class TranscriptionJobManager {
    let transcriber: SpeezySpeechTranscriber
    var timer: Timer?
    
    private var transcriptionObservatons = [ObjectIdentifier : TranscriptionObservation]()
    
    init(transcriber: SpeezySpeechTranscriber) {
        self.transcriber = transcriber
    }
    
    func createTranscriptionJob(audioId: String, url: URL) {
        transcriber.createTranscriptionJob(audioId: audioId, url: url) { (job) in
            TranscriptionJobStorage.save(job)
            self.checkJobs()
        }
    }
        
    @objc func checkJobs() {
        let jobs = TranscriptionJobStorage.fetchItems()
        let group = DispatchGroup()
        
        // Check each job.
        jobs.forEach { (job) in
            group.enter()
            self.checkJob(job) { (checkResult) in
                // Update the storage.
                switch checkResult {
                case let .complete(transcript):
                    TranscriptionJobStorage.deleteItem(job)
                    self.transcriptionObservatons.forEach {
                        $0.value.observer?.transcriptionJobManager(
                            self,
                            didFinishTranscribingWithAudioItemId: job.id,
                            transcript: transcript
                        )
                    }
                    
                    self.timer?.invalidate()
                    self.timer = nil
                case let .processing(job):
                    self.transcriptionObservatons.forEach {
                        $0.value.observer?.transcriptionJobManager(
                            self,
                            didQueueTranscriptionJobWithAudioItemId: job.id
                        )
                    }
                case .unknown:
                    break
                }
                
                group.leave()
            }
        }
        
        group.notify(queue: .global()) {
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 2.0) {
                self.checkJobs()
            }
        }
    }
    
    private func checkJob(_ job: TranscriptionJob, completion: @escaping (TranscriptJobCheckResponse) -> Void) {
        transcriber.checkJob(id: job.id) { (result) in
            switch result {
            case let .success(checkResponse):
                completion(checkResponse)
            default:
                completion(.unknown)
            }
        }
    }
}

extension TranscriptionJobManager {
    func addTranscriptionObserver(_ observer: TranscriptionObserver) {
        let id = ObjectIdentifier(observer)
        transcriptionObservatons[id] = TranscriptionObservation(observer: observer)
    }
}
