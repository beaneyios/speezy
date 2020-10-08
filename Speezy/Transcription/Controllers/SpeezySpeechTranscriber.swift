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
    func createTranscriptionJob(url: URL, completion: @escaping (TranscriptionJob) -> Void) {
        let uploadUrl = URL(string: "http://localhost:8000/upload-audio")!
        
        AF.upload(multipartFormData: { (data) in
            data.append(try! Data(contentsOf: url), withName: "audio", fileName: url.lastPathComponent, mimeType: "audio/flac")
        }, to: uploadUrl).responseDecodable(of: TranscriptionJob.self) { response in
            switch response.result {
            case let .success(job):
                completion(job)
            case let .failure(error):
                break
            }
        }
    }
    
    func checkJob(id: String, completion: @escaping (Result<Transcript, AFError>) -> Void) {
        AF.request("http://localhost:8000/transcriptions/\(id)").responseDecodable(of: Transcript.self) { response in
            completion(response.result)
        }
    }
}
