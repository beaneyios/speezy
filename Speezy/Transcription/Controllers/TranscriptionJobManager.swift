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
        print("Checking jobs")
        let jobs = TranscriptionJobStorage.fetchItems()
        
        if jobs.isEmpty {
            return
        }
        
        let group = DispatchGroup()
        
        // Check each job.
        print("Job count \(jobs.count)")
        jobs.forEach { (job) in
            group.enter()
            self.checkJob(job) { (checkResult) in
                // Update the storage.
                switch checkResult {
                case let .complete(transcript):
                    print("Job complete, deleting item")
                    TranscriptionJobStorage.deleteItem(job)
                    self.transcriptionObservatons.forEach {
                        $0.value.observer?.transcriptionJobManager(
                            self,
                            didFinishTranscribingWithAudioItemId: job.id,
                            transcript: transcript
                        )
                    }
                case let .processing(job):
                    print("Job processing, letting listeners know.")
                    self.transcriptionObservatons.forEach {
                        $0.value.observer?.transcriptionJobManager(
                            self,
                            didQueueTranscriptionJobWithAudioItemId: job.id
                        )
                    }
                case .unknown:
                    break
                }
                
                print("Leaving the group.")
                group.leave()
            }
        }
    
        group.notify(queue: .global()) {
            print("All jobs checked, scheduling a 2 second timer")
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 2.0) {
                print("Timer finished, checking jobs again.")
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
