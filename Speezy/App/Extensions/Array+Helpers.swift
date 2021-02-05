//
//  Array+Helpers.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    func without(_ element: Element) -> Self {
        let indexOfElement = firstIndex(of: element)
        guard let index = indexOfElement else {
            return self
        }
        
        var newArray = self
        newArray[index] = element
        return newArray
    }
}

extension Array where Element: Identifiable {
    func first(withId id: String) -> Element? {
        first {
            $0.id == id
        }
    }
    
    func contains(_ element: Element) -> Bool {
        contains(elementWithId: element.id)
    }
    
    func contains(elementWithId id: String) -> Bool {
        contains {
            $0.id == id
        }
    }
    
    func replacing(_ element: Element) -> Self {
        let indexOfElement = firstIndex {
            $0.id == element.id
        }
        
        guard let index = indexOfElement else {
            return self
        }
        
        var newArray = self
        newArray[index] = element
        return newArray
    }
    
    func removing(_ id: String) -> Self {
        let indexOfElement = firstIndex {
            $0.id == id
        }
        
        guard let index = indexOfElement else {
            return self
        }
        
        var newArray = self
        newArray.remove(at: index)
        return newArray
    }
    
    func removing(_ element: Element) -> Self {
        removing(element.id)
    }
}
