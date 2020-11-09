//
//  Array+Extensions.swift
//  Example
//
//  Created by Jorge Ouahbi on 29/10/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

// https://gist.github.com/pixeldock/f1c3b2bf0f7fe48d412c09fcb2705bf1
extension Array {
    func takeElements(_ numberOfElements: Int, startAt: Int = 0) -> Array {
        var numberOfElementsToGet = numberOfElements
        if numberOfElementsToGet > count - startAt {
            numberOfElementsToGet = count - startAt
        }
        let from = Array(self[startAt..<count])
        return Array(from[0..<numberOfElementsToGet])
    }
}
extension Array where Element: Comparable {
    var indexOfMax: Index? {
        guard var maxValue = self.first else { return nil }
        var maxIndex = 0
        for (index, value) in self.enumerated() {
            if value > maxValue {
                maxValue = value
                maxIndex = index
            }
        }
        return maxIndex
    }
    var indexOfMin: Index? {
        guard var maxValue = self.first else { return nil }
        var maxIndex = 0
        for (index, value) in self.enumerated() {
            if value < maxValue {
                maxValue = value
                maxIndex = index
            }
        }
        return maxIndex
    }
}

extension Array: Hashable where Iterator.Element: Hashable {
    public var hashValue: Int {
        return self.reduce(1, { $0.hashValue ^ $1.hashValue })
    }
}
