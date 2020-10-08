//
//  GoogleSpeechTranscriber.swift
//  Speezy
//
//  Created by Matt Beaney on 14/09/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

class GoogleSpeechTranscriber: NSObject {
    var completion: ((Transcript) -> Void)?
    
    func transcribe(url: URL, completion: @escaping (Transcript) -> Void) {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "Content-Type": "audio/flac"
        ]
        
        let session = URLSession(configuration: config)
        let uploadUrl = URL(string: "https://speech.googleapis.com/v1/speech:longrunningrecognize?key=AIzaSyC73e1UY7VJ5xhw8t9-8PuZrJnRKB82BaA")!
        var request = URLRequest(url: uploadUrl)
        
        let data = try! Data(contentsOf: url)
        let audioData = ["content": data.base64EncodedString()]
        let requestDictionary = [
            "audio": audioData
        ]
        
        let requestData = try! JSONSerialization.data(withJSONObject: requestDictionary, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        request.httpMethod = "POST"    
    }
}
