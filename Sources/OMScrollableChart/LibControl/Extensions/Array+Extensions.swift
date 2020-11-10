//
//  Array+Extensions.swift
//  Example
//
//  Created by Jorge Ouahbi on 29/10/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit
import Accelerate

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
/// Index of max and index of min
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

extension Array where Element: Equatable {
    func indexes(of element: Element) -> [Int] {
        return self.enumerated().filter({ element == $0.element }).map({ $0.offset })
    }
}
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

//extension Array: Hashable where Iterator.Element: Hashable {
//    public var hashValue: Int {
//        return self.reduce(1, { $0.hashValue ^ $1.hashValue })
//    }
//}

// Stadistics
extension Array where Element == Float {
    func mean() -> Float {
        if isEmpty { return 0 }
        return reduce(.zero, +) / Float(count)
    }
    
     func meanv() -> Float {
        var result: Float = 0
        vDSP_meanv(self, 1, &result, vDSP_Length(self.count))
        return result
        
    }
     func measq() -> Float {
        var result: Float = 0
        vDSP_measqv(self, 1, &result, vDSP_Length(self.count))
        return result
        
    }
    static func linregress(_ lhs: [Float], _ rhs: [Float]) -> (slope: Float, intercept: Float) {
        precondition(lhs.count == rhs.count, "Vectors must have equal count")
        let meanx = lhs.mean()
        let meany = rhs.mean()
        var result: [Float] = [Float].init(repeating: 0, count: lhs.count)
        vDSP_vmul(lhs, 1, rhs, 1, &result, 1, vDSP_Length(lhs.count))
        
        let meanxy = result.mean()
        let meanxSqr = lhs.measq()
        
        let slope = (meanx * meany - meanxy) / (meanx * meanx - meanxSqr)
        let intercept = meany - slope * meanx
        return (slope, intercept)
    }
    
}

extension Array where Element == CGPoint {
    /// Calculate signed area.
    ///
    /// See https://en.wikipedia.org/wiki/Centroid#Of_a_polygon
    ///
    /// - Returns: The signed area

    func signedArea() -> CGFloat {
        if isEmpty { return .zero }

        var sum: CGFloat = 0
        for (index, point) in enumerated() {
            let nextPoint: CGPoint
            if index < count-1 {
                nextPoint = self[index+1]
            } else {
                nextPoint = self[0]
            }

            sum += point.x * nextPoint.y - nextPoint.x * point.y
        }

        return sum / 2
    }

    func segments() -> [LineSegment]? {
        if isEmpty { return nil }
        var segments = [LineSegment]()
        for index in stride(from: 0, to: count - 1, by: 1){
            segments.append(LineSegment(self[index], self[index + 1]))
        }
        return segments
    }
    /// Calculate centroid
    ///
    /// See https://en.wikipedia.org/wiki/Centroid#Of_a_polygon
    ///
    /// - Note: If the area of the polygon is zero (e.g. the points are collinear), this returns `nil`.
    ///
    /// - Parameter points: Unclosed points of polygon.
    /// - Returns: Centroid point.

    func centroid() -> CGPoint? {
        if isEmpty { return nil }

        let area = signedArea()
        if area == 0 { return nil }

        var sumPoint: CGPoint = .zero

        for (index, point) in enumerated() {
            let nextPoint: CGPoint
            if index < count-1 {
                nextPoint = self[index+1]
            } else {
                nextPoint = self[0]
            }

            let factor = point.x * nextPoint.y - nextPoint.x * point.y
            sumPoint.x += (point.x + nextPoint.x) * factor
            sumPoint.y += (point.y + nextPoint.y) * factor
        }

        return sumPoint / 6 / area
    }

    func mean() -> CGPoint? {
        if isEmpty { return nil }

        return reduce(.zero, +) / CGFloat(count)
    }
}

private extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }

    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}
