//
//  TestUtils.swift
//  Example
//
//  Created by Jorge Ouahbi on 08/11/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

func randomNumber(probabilities: [Double]) -> Int {
    // Sum of all probabilities (so that we don't have to require that the sum is 1.0):
    let sum = probabilities.reduce(0, +)
    // Random number in the range 0.0 <= rnd < sum :
    let rnd = Double.random(in: 0.0 ..< sum)
    // Find the first interval of accumulated probabilities into which `rnd` falls:
    var accum = 0.0
    for (i, p) in probabilities.enumerated() {
        accum += p
        if rnd < accum {
            return i
        }
    }
    // This point might be reached due to floating point inaccuracies:
    return (probabilities.count - 1)
}

//MARK: - Random numbers
extension BinaryInteger {
  static func random(min: Self, max: Self) -> Self {
    assert(min < max, "min must be smaller than max")
    let delta = max - min
    return min + Self(arc4random_uniform(UInt32(delta)))
  }
}

extension FloatingPoint {
  static func random(min: Self, max: Self, resolution: Int = 1000) -> Self {
    let randomFraction = Self(Int.random(min: 0, max: resolution)) / Self(resolution)
    return min + randomFraction * max
  }
}

func randomSize(bounded bounds: CGRect,
                numberOfItems: Int) -> [CGSize]{
    let randomSizes  = (0..<numberOfItems).map { _ in CGSize(width: .random(min: 0, max: bounds.size.width), height: .random(min: 0, max: bounds.size.height)) }
    return randomSizes
}
func randomFloat(_ numberOfItems: Int, max: Float = 0, min: Float = 100000) -> [Float]{
    let randomData = (0..<numberOfItems).map { _ in Float.random(min: min, max: max) }
    return randomData
}
