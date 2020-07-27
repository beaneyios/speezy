//
//  FileManager+Helpers.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

extension FileManager {
    func documentsURL(with fileName: String, create: Bool = false) -> URL? {
        do {
            let documentDirectory = try url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            
            if fileExists(atPath: fileURL.absoluteString) == false && create {
                createFile(atPath: fileURL.path, contents: nil, attributes: nil)
            }
            
            return fileURL
        } catch {
            print(error)
        }
        
        return nil
    }
    
    func renameFile(from originalName: String, to newName: String) {
        do {
            let documentDirectory = try url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let originPath = documentDirectory.appendingPathComponent(originalName)
            let destinationPath = documentDirectory.appendingPathComponent(newName)
            try FileManager.default.moveItem(at: originPath, to: destinationPath)
        } catch {
            print(error)
        }
    }
    
    func deleteExistingFile(with fileName: String) {
        do {
            let documentDirectory = try url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            try removeItem(at: fileURL)
        } catch {
            print(error)
        }
    }
    
    func deleteExistingURL(_ url: URL) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: url)
        } catch {
            print(error)
        }
    }
}
