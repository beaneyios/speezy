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
        didFinishTranscribingWithAudioItemId id: String,
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
        let jobs = TranscriptionJobStorage.fetchItems()
        
        if jobs.isEmpty {
            return
        }
        
        let group = DispatchGroup()
        
        // Check each job.
        jobs.forEach { (job) in
            group.enter()
            self.checkJob(job) { (response) in
                self.handleJobResponse(response, job: job)
                group.leave()
            }
        }
    
        group.notify(queue: .global()) {
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 2.0) {
                self.checkJobs()
            }
        }
    }
    
    private func handleJobResponse(_ response: TranscriptionJobCheckResponse, job: TranscriptionJob) {
        switch response {
        case let .complete(transcript):
            // Remove the job.
            TranscriptionJobStorage.deleteItem(job)
            
            self.transcriptionObservatons.forEach {
                $0.value.observer?.transcriptionJobManager(
                    self,
                    didFinishTranscribingWithAudioItemId: job.id,
                    transcript: transcript
                )
            }
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
    }
    
    private func checkJob(_ job: TranscriptionJob, completion: @escaping (TranscriptionJobCheckResponse) -> Void) {
        transcriber.checkJob(id: job.id) { (result) in
            switch result {
            case let .success(response):
                completion(response)
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
