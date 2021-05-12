//
//  ExampleTests.swift
//  ExampleTests
//
//  Created by Jorge Ouahbi on 29/10/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import XCTest
@testable import Example

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
fileprivate extension BinaryInteger {
  static func random(min: Self, max: Self) -> Self {
    assert(min < max, "min must be smaller than max")
    let delta = max - min
    return min + Self(arc4random_uniform(UInt32(delta)))
  }
}

fileprivate extension FloatingPoint {
  static func random(min: Self, max: Self, resolution: Int = 1000) -> Self {
    let randomFraction = Self(Int.random(min: 0, max: resolution)) / Self(resolution)
    return min + randomFraction * max
  }
}

class ExampleTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    var result1 = [CGPoint]()
    var result2 = [CGPoint]()
    var result3 = [CGPoint]()
    var result4 = [CGPoint]()
    
    func randomSize(bounded bounds: CGRect,
                    numberOfItems: Int) -> [CGSize]{
        let randomSizes  = (0..<numberOfItems).map { _ in CGSize(width: .random(min: 0, max: bounds.size.width), height: .random(min: 0, max: bounds.size.height)) }
        return randomSizes
    }
    func randomFloat(_ numberOfItems: Int, max: Float = 0, min: Float = 100000) -> [Float]{
        let randomData = (0..<numberOfItems).map { _ in Float.random(min: min, max: max) }
        return randomData
    }
    
    
    
    
    func testSimplification() {

        let numberOfItems = 300
        let randomPoints  = (0..<numberOfItems).map { _ in CGPoint(x: .random(min: 0, max: UIScreen.main.bounds.size.width),
                                                                y: .random(min: 0, max: UIScreen.main.bounds.size.height)) }

        
        print("X",
              "Vis",
              "DglsHQ",
              "DglsPc",
              "Deci")
        
        for index in (0..<numberOfItems) {
            result1 = PolylineSimplify.visvalingamSimplify(randomPoints, limit: CGFloat(index) )
            result2 = PolylineSimplify.simplifyDouglasPeuckerRadial(randomPoints, tolerance: CGFloat(index), highestQuality: true)
            result3 = PolylineSimplify.simplifyDouglasPeuckerRadial(randomPoints, tolerance: CGFloat(index), highestQuality: false)
            result4 = PolylineSimplify.simplifyDouglasPeuckerDecimate(randomPoints)
            
            print(index,
                  result1.count,
                  result2.count,
                  result3.count,
                  result4.count)
        }
    }
    
    func testScaledPointsGenerator() {
        let numberOfItems = 300
        let sizes = randomSize(bounded: UIScreen.main.bounds, numberOfItems: numberOfItems)
        let scaler = DiscreteScaledPointsGenerator()
        for size in sizes {
            let randomData = randomFloat(numberOfItems)
            let points  = scaler.makePoints(data: randomData, size: size)
            points.forEach { CGRect(origin: .zero, size: size).contains($0) }
            let points2 = ScaledPointsGenerator(randomData, size: size, insets: .zero).makePoints()
            points2.forEach { CGRect(origin: .zero, size: size).contains($0)}
            XCTAssert(points == points2)
        }
    }
}
