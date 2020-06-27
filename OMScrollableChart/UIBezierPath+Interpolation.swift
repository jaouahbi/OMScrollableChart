// Copyright 2018 Jorge Ouahbi
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
import Foundation
import UIKit

let epsilon: CGFloat = 0.01 //0.00001
// https://spin.atomicobject.com/2014/05/28/ios-interpolating-points/
// https://github.com/jnfisher/ios-curve-interpolation/blob/master/Curve%20Interpolation/UIBezierPath%2BInterpolation.m

//
// SwiftSimplify.swift
// Simplify
//
// Created by Daniele Margutti on 28/06/2019.
// Copyright (c) 2019 Daniele Margutti. All rights reserved
// Original work by https://mourner.github.io/simplify-js/
//
// Web:     http://www.danielemargutti.com
// Mail:    hello@danielemargutti.com
// Twitter: http://www.twitter.com/danielemargutti
// GitHub:  http://www.github.com/malcommac
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
import Foundation
import UIKit


public enum CatmullRomCurvePrameterization: CGFloat {
    case uniform = 0.0
    case centripetal = 0.5
    case chordal = 1.0
}

extension UIBezierPath {
    
    /// Create an UIBezierPath instance from a sequence of points which is drawn smoothly.
    ///
    /// - Parameter points: points of the path.
    /// - Returns: smoothed UIBezierPath.
    convenience init?(smoothedPoints: [CGPoint], maxYPosition: CGFloat, closed: Bool = true) {
        self.init()
        guard smoothedPoints.count > 1 else {
            return nil
        }
        
        var prevPoint: CGPoint?
        for (index, point) in smoothedPoints.enumerated() {
            if index == 0 {
                self.move(to: CGPoint(x: point.x, y: CGFloat(maxYPosition)))
                addLine(to: point)
            } else {
                //                if index == 1 {
                //                    self.addLine(to: point)
                //                }
                if let prevPoint = prevPoint {
                    let midPoint = prevPoint.midPointForPointsTo(point)
                    self.addQuadCurve(to: midPoint, controlPoint: midPoint.controlPointToPoint(prevPoint))
                    self.addQuadCurve(to: point, controlPoint: midPoint.controlPointToPoint(point))
                }
            }
            prevPoint = point
            if index == smoothedPoints.count - 1 {
                addLine(to: CGPoint(x: point.x, y: CGFloat(maxYPosition)))
            }
        }
        if closed {
            self.close()
        }
    }
    convenience init?(pointPoints: [CGPoint], pointSize: CGFloat) {
        self.init()
        // Interpolation points drawing
        for point in pointPoints {
            let pointPath = UIBezierPath(ovalIn: CGRect(x:point.x-(pointSize * 0.5),
                                                        y:point.y-(pointSize * 0.5),
                                                        width: pointSize,
                                                        height: pointSize))
            self.append(pointPath)
        }
    }
    
    convenience init?(points: [CGPoint], maxYPosition: CGFloat, closed: Bool = true) {
        self.init()
        guard !points.isEmpty else { return }
        for index in 0..<points.count {
            let value = points[index]
            if index == 0 {
                self.move(to: CGPoint(x: value.x, y: CGFloat(maxYPosition)))
                addLine(to: value)
            } else {
                self.addLine(to: value)
            }
            
            if index == points.count - 1 {
                addLine(to: CGPoint(x: value.x, y: CGFloat(maxYPosition)))
            }
        }
        if closed {
            self.close()
        }
        
    }
    
    // helper func  to test if CGFloat is close enough to zero
    // to be considered zero
    
    func isZero(_ input: CGFloat) -> Bool {
        return abs(input) < epsilon
    }
    
    func pointsFormALine(_ points: [CGPoint]) -> CGFloat {
        // variables for computing linear regression
        var sumXX: CGFloat = 0  // sum of X^2
        var sumXY: CGFloat = 0  // sum of X * Y
        var sumX:  CGFloat = 0  // sum of X
        var sumY:  CGFloat = 0  // sum of Y
        
        for point in points {
            sumXX += point.x * point.x
            sumXY += point.x * point.y
            sumX  += point.x
            sumY  += point.y
        }
        
        // n is the number of points
        let numberOfPoints = CGFloat(points.count)
        
        // compute numerator and denominator of the slope
        let num = numberOfPoints * sumXY - sumX * sumY
        let den = numberOfPoints * sumXX - sumX * sumX
        
        // is the line vertical or horizontal?
        if isZero(num) || isZero(den) {
            return 0
        }
        
        // calculate slope of line
        let slopeOfLine = num / den
        
        // calculate the y-intercept
        let  yIntercept = (sumY - slopeOfLine * sumX) / numberOfPoints
        
        //print("y = \(m)x + \(b)")
        
        // check fit by summing the squares of the errors
        var error: CGFloat = 0
        var predictedY : CGFloat = 0
        for point in points {
            // apply equation of line y = mx + b to compute predicted y
            predictedY = slopeOfLine * point.x + yIntercept
            error += pow(predictedY - point.y, 2)
        }
        //print(error)
        return error
    }
    ///
    /// Init
    /// - Parameter cubicCurvePoints: points
    convenience init?(cubicCurvePoints: [CGPoint], maxYPosition: CGFloat) {
        self.init()
        guard !cubicCurvePoints.isEmpty else { return }
        let controlPoints = CubicCurveAlgorithm().controlPointsFromPoints(dataPoints: cubicCurvePoints)
        for index in 0..<cubicCurvePoints.count {
            let point = cubicCurvePoints[index]
            if index==0 {
                self.move(to: point)
                move(to: CGPoint(x: point.x, y: CGFloat(maxYPosition)))
            } else {
                let segment = controlPoints[index-1]
                self.addCurve(to: point,
                              controlPoint1: segment.controlPoint1,
                              controlPoint2: segment.controlPoint2)
                if index == cubicCurvePoints.count - 1 {
                    addLine(to: CGPoint(x: point.x, y: CGFloat(maxYPosition)))
                }
            }
        }
    }
    ///
    /// Init
    /// - Parameter hermitePoints: points
    /// - Parameter alpha: Commonly used values of alpha are 0.0, 0.5, and 1.0,
    /// corresponding to uniform, centripetal, and chordal parameterizations of the curves.
    convenience init?(hermitePoints: [CGPoint], maxYPosition: CGFloat, alpha: CGFloat = 0.5) {
        self.init()
        guard !hermitePoints.isEmpty else { return }
        self.move(to: hermitePoints[0])
        self.move(to: CGPoint(x: hermitePoints[0].x, y: CGFloat(maxYPosition)))
        let numberOfHermitePoints = hermitePoints.count - 1
        for index in 0..<numberOfHermitePoints {
            var currentPoint = hermitePoints[index]
            var nextIndex = (index + 1) % hermitePoints.count
            var prevIndex = index == 0 ? hermitePoints.count - 1 : index - 1
            var previousPoint = hermitePoints[prevIndex]
            var nextPoint = hermitePoints[nextIndex]
            let endPoint = nextPoint
            var mx: CGFloat
            var my: CGFloat
            if index > 0 {
                mx = (nextPoint.x - previousPoint.x) / 2.0
                my = (nextPoint.y - previousPoint.y) / 2.0
            } else {
                mx = (nextPoint.x - currentPoint.x) / 2.0
                my = (nextPoint.y - currentPoint.y) / 2.0
            }
            let controlPoint1 = CGPoint(x: currentPoint.x + mx * alpha, y: currentPoint.y + my * alpha)
            currentPoint = hermitePoints[nextIndex]
            nextIndex = (nextIndex + 1) % hermitePoints.count
            prevIndex = index
            previousPoint = hermitePoints[prevIndex]
            nextPoint = hermitePoints[nextIndex]
            if index < numberOfHermitePoints - 1 {
                mx = (nextPoint.x - previousPoint.x) / 2.0
                my = (nextPoint.y - previousPoint.y) / 2.0
            } else {
                mx = (currentPoint.x - previousPoint.x) / 2.0
                my = (currentPoint.y - previousPoint.y) / 2.0
            }
            let controlPoint2 = CGPoint(x: currentPoint.x - mx * alpha, y: currentPoint.y - my * alpha)
            self.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
            if index == numberOfHermitePoints - 1 {
                addLine(to: CGPoint(x: endPoint.x, y: CGFloat(maxYPosition)))
            }
        }
    }
    ///
    /// Init
    /// - Parameter catmullRomPoints: points
    /// - Parameter closed: close the path
    /// - Parameter alpha: Commonly used values of alpha are 0.0, 0.5, and 1.0,
    /// corresponding to uniform, centripetal, and chordal parameterizations of the curves.
    convenience init?(catmullRomPoints: [CGPoint], maxYPosition: CGFloat, closed: Bool = true, alpha: CGFloat = 0.5) {
        self.init()
        guard !catmullRomPoints.isEmpty else { return }
        if catmullRomPoints.count < 4 {
            return nil
        }
        let startIndex = closed ? 0 : 1
        let endIndex = closed ? catmullRomPoints.count : catmullRomPoints.count - 2
        for index in startIndex...endIndex - 1 {
            let p0 = catmullRomPoints[index-1 < 0 ? catmullRomPoints.count - 1 : index - 1]
            let p1 = catmullRomPoints[index]
            let p2 = catmullRomPoints[(index+1)%catmullRomPoints.count]
            let p3 = catmullRomPoints[((index+1)%catmullRomPoints.count + 1) % catmullRomPoints.count]
            
            let d1 = p1.deltaTo(a: p0).length()
            let d2 = p2.deltaTo(a: p1).length()
            let d3 = p3.deltaTo(a: p2).length()
            
            var b1 = p2.multiplyBy(value: pow(d1, 2 * alpha))
            b1 = b1.deltaTo(a: p0.multiplyBy(value: pow(d2, 2 * alpha)))
            b1 = b1.add(a: p1.multiplyBy(value: 2 * pow(d1, 2 * alpha) + 3 * pow(d1, alpha) * pow(d2, alpha) + pow(d2, 2 * alpha)))
            b1 = b1.multiplyBy(value: 1.0 / (3 * pow(d1, alpha) * (pow(d1, alpha) + pow(d2, alpha))))
            
            var b2 = p1.multiplyBy(value: pow(d3, 2 * alpha))
            b2 = b2.deltaTo(a: p3.multiplyBy(value: pow(d2, 2 * alpha)))
            b2 = b2.add(a: p2.multiplyBy(value: 2 * pow(d3, 2 * alpha) + 3 * pow(d3, alpha) * pow(d2, alpha) + pow(d2, 2 * alpha)))
            b2 = b2.multiplyBy(value: 1.0 / (3 * pow(d3, alpha) * (pow(d3, alpha) + pow(d2, alpha))))
            
            if index == startIndex {
                move(to: CGPoint(x: p1.x, y: CGFloat(maxYPosition)))
                addLine(to: p1)
            }
            addCurve(to: p2, controlPoint1: b1, controlPoint2: b2)
        }
        
        addLine(to: CGPoint(x: catmullRomPoints.last!.x, y: CGFloat(maxYPosition)))
        if closed {
            close()
        }
    }
}
// MARK: - Linear regression -
extension UIBezierPath {
    func average(_ input: [Double]) -> Double {
        return input.reduce(0, +) / Double(input.count)
    }
    func multiply(_ argumentA: [Double], _ argumentB: [Double]) -> [Double] {
        return zip(argumentA, argumentB).map(*)
    }
    func linearRegression(_ xs: [Double], _ ys: [Double]) -> (Double) -> Double {
        let sum1 = average(multiply(ys, xs)) - average(xs) * average(ys)
        let sum2 = average(multiply(xs, xs)) - pow(average(xs), 2)
        let slope = sum1 / sum2
        let intercept = average(ys) - slope * average(xs)
        return { argument in intercept + slope * argument }
    }
    var linearRegression: (Double) -> Double {
        let points = self.cgPath.getPathElementsPoints()
        let xs = points.map({Double($0.x)})
        let ys = points.map({Double($0.y)})
        let regression = linearRegression(xs, ys)
        return regression
        //        let y1 = linearRegression(1) //Result is 1.6
        //        let y2 = linearRegression(3) //Result is 2.8
    }
}


