//
//  Array+Helpers.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

extension Array where Element: Identifiable {
    func first(withId id: String) -> Element? {
        first {
            $0.id == id
        }
    }
    
    func contains(_ element: Element) -> Bool {
        contains {
            $0.id == element.id
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
    
    func removing(_ element: Element) -> Self {
        let indexOfElement = firstIndex {
            $0.id == element.id
        }
        
        guard let index = indexOfElement else {
            return self
        }
        
        var newArray = self
        newArray.remove(at: index)
        return newArray
    }
}
