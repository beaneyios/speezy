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
    func appending(element: Element) -> Self {
        var newArray = self
        newArray.append(element)
        return newArray
    }
    
    func appending(elements: [Element]) -> Self {
        var newArray = self
        newArray.append(contentsOf: elements)
        return newArray
    }
    
    func first(withId id: String) -> Element? {
        first {
            $0.id == id
        }
    }
    
    func isSameOrderAs(_ array: Self) -> Bool {
        for (index, element) in self.enumerated() {
            if index >= array.count {
                // Something was added, best to assume these aren't in the same order.
                return false
            }
            
            // The chat in this position is not the same chat as self's element.
            let secondElement = array[index]
            if secondElement.id != element.id {
                return false
            }
        }
        
        // No early false terminations, we can assume they are in the same order.
        return true
    }
    
    func contains(_ element: Element) -> Bool {
        contains(elementWithId: element.id)
    }
    
    func contains(elementWithId id: String) -> Bool {
        contains {
            $0.id == id
        }
    }
    
    func inserting(_ element: Element) -> Self {
        if index(element) != nil {
            return replacing(element)
        }
        
        var newArray = self
        newArray.insert(element, at: 0)
        return newArray
    }
    
    func replacing(_ element: Element) -> Self {
        guard let index = index(element) else {
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
    
    func index(_ id: String) -> Int? {
        firstIndex {
            $0.id == id
        }
    }
    
    func index(_ element: Element) -> Int? {
        index(element.id)
    }
}
