//
//  SpeezySpeechTranscriber.swift
//  Speezy
//
//  Created by Matt Beaney on 03/10/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import Alamofire

struct SpeezySpeechTranscriber {
    private let host = "https://quiet-hollows-82585.herokuapp.com"
//    private let host = "http://localhost:8000"
    
    func createTranscriptionJob(audioId: String, url: URL, completion: @escaping (TranscriptionJob) -> Void) {
        let uploadUrl = URL(string: "\(host)/upload-audio")!
        
        guard
            let audioData = try? Data(contentsOf: url),
            let audioIdData = audioId.data(using: .utf8)
        else {
            fatalError("ID Should not produce nil data")
        }
        
        AF.upload(multipartFormData: { (data) in
            data.append(audioData, withName: "audio", fileName: url.lastPathComponent, mimeType: "audio/wav")
            data.append(audioIdData, withName: "audioId")
        }, to: uploadUrl).responseDecodable(of: TranscriptionJob.self) { response in
            switch response.result {
            case let .success(job):
                completion(job)
            case let .failure(error):
                break
            }
        }
    }
    
    func checkJob(id: String, completion: @escaping (Result<TranscriptionJobCheckResponse, AFError>) -> Void) {
        let request = AF.request("\(host)/transcriptions/\(id)")
        request.responseDecodable(of: TranscriptionJobCheckResponse.self) { (response) in
            completion(response.result)
        }
    }
}

enum TranscriptionJobCheckResponse: Decodable {
    case complete(Transcript)
    case processing(TranscriptionJob)
    case unknown
    
    init(from decoder: Decoder) throws {
        if let transcript = try? Transcript(from: decoder) {
            self = .complete(transcript)
        } else if let job = try? TranscriptionJob(from: decoder) {
            self = .processing(job)
        } else {
            self = .unknown
        }
    }
}
