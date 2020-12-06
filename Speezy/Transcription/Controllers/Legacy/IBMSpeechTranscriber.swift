//
//  IBMSpeechTranscriber.swift
//  Speezy
//
//  Created by Matt Beaney on 13/09/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

class IBMSpeechTranscriber: NSObject {
    var completion: ((Transcript) -> Void)?
    
    func transcribe(url: URL, completion: @escaping (Transcript) -> Void) {
        
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "Content-Type": "audio/flac"
        ]
        
        let username = "apikey"
        let password = "4oFu8N2dnGHE7cq9oZcAGmLuhWE5byscjp10tMoIJ9hU"
        let loginString = String(format: "%@:%@", username, password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        
        let session = URLSession(configuration: config)
        let uploadUrl = URL(string: "https://api.eu-gb.speech-to-text.watson.cloud.ibm.com/instances/9f7c8bd2-2c4b-453c-a828-a28c8f1bf212/v1/recognize?timestamps=true&model=en-GB_NarrowbandModel")!
        var request = URLRequest(url: uploadUrl)
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        let data = try! Data(contentsOf: url)
        session.uploadTask(with: request, from: data) { (data, response, error) in
            let dictionary: [String: Any] = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String: Any]

            let results = dictionary["results"] as! [[String: Any]]

            let words: [Word] = results.flatMap { (result) -> [Word] in
                let alternatives = result["alternatives"] as! [[String: Any]]
                let firstAlternative = alternatives[0]
                let timestamps = firstAlternative["timestamps"] as! [[Any]]
                return timestamps.map { (timestamp) -> Word in
                    let word = timestamp[0] as! String
                    let startTimeStamp = timestamp[1] as! TimeInterval
                    let endTimeStamp = timestamp[2] as! TimeInterval
                    let speezyTimeStamp = Timestamp(start: startTimeStamp, end: endTimeStamp)
                    return Word(text: word, timestamp: speezyTimeStamp)
                }
            }
            .filter {
                $0.text.contains("HESITATION") == false
            }
            
            completion(Transcript(words: words))
        }.resume()
    }
}
