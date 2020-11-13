//
//  PolynomialRegression.swift
//  PolynomialRegressionCalc
//
//  Created by Rob Baldwin on 23/04/2020.
//  Copyright © 2020 Rob Baldwin. All rights reserved.
//

import Foundation

struct PolynomialRegression {
    
    /// This calculator is based on the Polynomial Regression
    /// formula from rosettacode, and translated to Swift
    /// https://rosettacode.org/wiki/Polynomial_regression
    ///
    /// This will find an approximating polynomial (y)
    /// of known degree for a given data
    
    let xValues: [Double]
    let yValues: [Double]
    
    func predictYValue(at x: Double) -> Double? {
        
        // Check X/Y values have same number of elements
        guard xValues.count == yValues.count else {
            print("The xValue and yValue Arrays must contain the same number of elements")
            return nil
        }
        
        // There must be at least three elements to produce a result
        guard xValues.count >= 3 else {
            print("At least three X/Y values must be provided")
            return nil
        }
        
        // Calculate the equation coefficients
        let (a, b, c) = calculateCoefficients(xValues, yValues)
        
        // Calcuate and return the result
        return (a + b * x) + (c * x * x)
    }
    
    private func calculateCoefficients(_ xValues: [Double], _ yValues: [Double]) -> (Double, Double, Double) {
        let xm = average(xValues)
        let ym = average(yValues)
        let x2m = average(xValues.map { $0 * $0 })
        let x3m = average(xValues.map { $0 * $0 * $0 })
        let x4m = average(xValues.map { $0 * $0 * $0 * $0 })
        let xym = average(zip(xValues, yValues).map { $0 * $1 })
        let x2ym = average(zip(xValues, yValues).map { $0 * $0 * $1 })

        let sxx = x2m - xm * xm
        let sxy = xym - xm * ym
        let sxx2 = x3m - xm * x2m
        let sx2x2 = x4m - x2m * x2m
        let sx2y = x2ym - x2m * ym
     
        let b = (sxy * sx2x2 - sx2y * sxx2) / (sxx * sx2x2 - sxx2 * sxx2)
        let c = (sx2y * sxx - sxy * sxx2) / (sxx * sx2x2 - sxx2 * sxx2)
        let a = ym - b * xm - c * x2m
     
        return (a, b, c)
    }
    
    // Helper function
    private func average(_ input: [Double]) -> Double {
        return input.reduce(0, +) / Double(input.count)
    }
}
