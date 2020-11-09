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

//
//  CubicCurveAlgorithm.swift
//  Bezier
//
//  Created by Ramsundar Shandilya on 10/12/15.
//  Copyright © 2015 Y Media Labs. All rights reserved.
//

import Foundation
import UIKit
// swiftlint:disable identifier_name
//struct CubicCurveSegment {
//    let controlPoint1: CGPoint
//    let controlPoint2: CGPoint
//}
//
//class CubicCurveAlgorithm {
//    private var firstControlPoints: [CGPoint?] = []
//    private var secondControlPoints: [CGPoint?] = []
//    func controlPointsFromPoints(dataPoints: [CGPoint]) -> [CubicCurveSegment] {
//        //Number of Segments
//        let count = dataPoints.count - 1
//
//        //P0, P1, P2, P3 are the points for each segment, where P0 & P3 are the knots and P1, P2 are the control points.
//        if count == 1 {
//            let P0 = dataPoints[0]
//            let P3 = dataPoints[1]
//
//            //Calculate First Control Point2D
//            //3P1 = 2P0 + P3
//
//            let P1x = (2*P0.x + P3.x)/3
//            let P1y = (2*P0.y + P3.y)/3
//
//            firstControlPoints.append(CGPoint(x: P1x, y: P1y))
//
//            //Calculate second Control Point2D
//            //P2 = 2P1 - P0
//            let P2x = (2*P1x - P0.x)
//            let P2y = (2*P1y - P0.y)
//
//            secondControlPoints.append(CGPoint(x: P2x, y: P2y))
//        } else {
//			firstControlPoints = Array(repeating: nil, count: count)
//
//            var rhsArray = [CGPoint]()
//
//            //Array of Coefficients
//            var a = [Double]()
//            var b = [Double]()
//            var c = [Double]()
//
//			for i in 0..<count {
//				var rhsValueX: CGFloat = 0
//				var rhsValueY: CGFloat = 0
//
//				let P0 = dataPoints[i];
//				let P3 = dataPoints[i+1];
//
//				if i==0 {
//					a.append(0)
//					b.append(2)
//					c.append(1)
//
//					//rhs for first segment
//					rhsValueX = P0.x + 2*P3.x;
//					rhsValueY = P0.y + 2*P3.y;
//
//				} else if i == count-1 {
//					a.append(2)
//					b.append(7)
//					c.append(0)
//
//					//rhs for last segment
//					rhsValueX = 8*P0.x + P3.x;
//					rhsValueY = 8*P0.y + P3.y;
//				} else {
//					a.append(1)
//					b.append(4)
//					c.append(1)
//
//					rhsValueX = 4*P0.x + 2*P3.x;
//					rhsValueY = 4*P0.y + 2*P3.y;
//				}
//
//				rhsArray.append(CGPoint(x: rhsValueX, y: rhsValueY))
//			}
//
//            //Solve Ax=B. Use Tridiagonal matrix algorithm a.k.a Thomas Algorithm
//			for i in 1..<count {
//				let rhsValueX = rhsArray[i].x
//				let rhsValueY = rhsArray[i].y
//
//				let prevRhsValueX = rhsArray[i-1].x
//				let prevRhsValueY = rhsArray[i-1].y
//
//				let m = a[i]/b[i-1]
//
//				let b1 = b[i] - m * c[i-1];
//				b[i] = b1
//
//				let r2x = rhsValueX.f - m * prevRhsValueX.f
//				let r2y = rhsValueY.f - m * prevRhsValueY.f
//
//				rhsArray[i] = CGPoint(x: r2x, y: r2y)
//			}
//            //Get First Control Points
//
//            //Last control Point2D
//            let lastControlPointX = rhsArray[count-1].x.f/b[count-1]
//            let lastControlPointY = rhsArray[count-1].y.f/b[count-1]
//
//            firstControlPoints[count-1] = CGPoint(x: lastControlPointX, y: lastControlPointY)
//
//			for i in (0 ..< count - 1).reversed() {
//				if let nextControlPoint = firstControlPoints[i+1] {
//					let controlPointX = (rhsArray[i].x.f - c[i] * nextControlPoint.x.f)/b[i]
//					let controlPointY = (rhsArray[i].y.f - c[i] * nextControlPoint.y.f)/b[i]
//
//					firstControlPoints[i] = CGPoint(x: controlPointX, y: controlPointY)
//
//				}
//			}
//
//            //Compute second Control Points from first
//
//			for i in 0..<count {
//
//				if i == count-1 {
//					let P3 = dataPoints[i+1]
//
//					guard let P1 = firstControlPoints[i] else{
//						continue
//					}
//
//					let controlPointX = (P3.x + P1.x)/2
//					let controlPointY = (P3.y + P1.y)/2
//
//					secondControlPoints.append(CGPoint(x: controlPointX, y: controlPointY))
//
//				} else {
//					let P3 = dataPoints[i+1]
//
//					guard let nextP1 = firstControlPoints[i+1] else {
//						continue
//					}
//
//					let controlPointX = 2*P3.x - nextP1.x
//					let controlPointY = 2*P3.y - nextP1.y
//
//					secondControlPoints.append(CGPoint(x: controlPointX, y: controlPointY))
//				}
//
//			}
//
//        }
//
//        var controlPoints = [CubicCurveSegment]()
//
//		for i in 0..<count {
//			if let firstControlPoint = firstControlPoints[i],
//				let secondControlPoint = secondControlPoints[i] {
//				let segment = CubicCurveSegment(controlPoint1: firstControlPoint, controlPoint2: secondControlPoint)
//				controlPoints.append(segment)
//			}
//		}
//
//        return controlPoints
//    }
//}
//
//extension CGFloat {
//    var f: Double {
//        return Double(self)
//    }
//}
// swiftlint:enable identifier_name


// https://exploringswift.com/blog/Drawing-Smooth-Cubic-Bezier-Curve-through-prescribed-points-using-Swift

struct CubicCurveSegment {
    var firstControlPoint: CGPoint
    var secondControlPoint: CGPoint
}

class CubicCurveAlgorithm {

  
    var firstControlPoints: [CGPoint?] = []
    var secondControlPoints: [CGPoint?] = []
    
    func controlPointsFromPoints(data: [CGPoint]) -> [CubicCurveSegment] {
        
        
        let segments = data.count - 1
        
        
        if segments == 1 {
            
            // straight line calculation here
            let p0 = data[0]
            let p3 = data[1]
            
            return [CubicCurveSegment(firstControlPoint: p0, secondControlPoint: p3)]
        }else if segments > 1 {
            
            //left hand side coefficients
            var ad = [CGFloat]()
            var d = [CGFloat]()
            var bd = [CGFloat]()
            

            var rhsArray = [CGPoint]()
            
            for i in 0..<segments {
                
                var rhsXValue : CGFloat = 0
                var rhsYValue : CGFloat = 0
                
                let p0 = data[i]
                let p3 = data[i+1]

                if i == 0 {
                    bd.append(0.0)
                    d.append(2.0)
                    ad.append(1.0)
                    
                    rhsXValue = p0.x + 2*p3.x
                    rhsYValue = p0.y + 2*p3.y
                    
                }else if i == segments - 1 {
                    bd.append(2.0)
                    d.append(7.0)
                    ad.append(0.0)
                    
                    rhsXValue = 8*p0.x + p3.x
                    rhsYValue = 8*p0.y + p3.y
                }else {
                    bd.append(1.0)
                    d.append(4.0)
                    ad.append(1.0)
                    
                    rhsXValue = 4*p0.x + 2*p3.x
                    rhsYValue = 4*p0.y + 2*p3.y
                }
                
                rhsArray.append(CGPoint(x: rhsXValue, y: rhsYValue))
            
                
            }
            
            let solution1 = thomasTridiagonalMatrixAlgorithm(bd: bd, d: d, ad: ad, rhsArray: rhsArray, segments: segments, data: data)
            
            return solution1
        }
        
        return []
    }
    
    func thomasTridiagonalMatrixAlgorithm(bd: [CGFloat], d: [CGFloat], ad: [CGFloat], rhsArray: [CGPoint], segments: Int, data: [CGPoint]) -> [CubicCurveSegment] {
        
        var controlPoints : [CubicCurveSegment] = []
        var ad = ad
        let bd = bd
        let d = d
        var rhsArray = rhsArray
        let segments = segments
        
        var solutionSet1 = [CGPoint?]()
        solutionSet1 = Array(repeating: nil, count: segments)
        
        //First segment
       ad[0] = ad[0] / d[0]
       rhsArray[0].x = rhsArray[0].x / d[0]
       rhsArray[0].y = rhsArray[0].y / d[0]

       //Middle Elements
        if segments > 2 {
            for i in 1...segments - 2  {
                let rhsValueX = rhsArray[i].x
                let prevRhsValueX = rhsArray[i - 1].x

                let rhsValueY = rhsArray[i].y
                let prevRhsValueY = rhsArray[i - 1].y

                ad[i] = ad[i] / (d[i] - bd[i]*ad[i-1]);

                let exp1x = (rhsValueX - (bd[i]*prevRhsValueX))
                let exp1y = (rhsValueY - (bd[i]*prevRhsValueY))
                let exp2 = (d[i] - bd[i]*ad[i-1])

                rhsArray[i].x = exp1x / exp2
                rhsArray[i].y = exp1y / exp2
            }
        }

       //Last Element
       let lastElementIndex = segments - 1
       let exp1 = (rhsArray[lastElementIndex].x - bd[lastElementIndex] * rhsArray[lastElementIndex - 1].x)
       let exp1y = (rhsArray[lastElementIndex].y - bd[lastElementIndex] * rhsArray[lastElementIndex - 1].y)
       let exp2 = (d[lastElementIndex] - bd[lastElementIndex] * ad[lastElementIndex - 1])
       rhsArray[lastElementIndex].x = exp1 / exp2
       rhsArray[lastElementIndex].y = exp1y / exp2

       solutionSet1[lastElementIndex] = rhsArray[lastElementIndex]

        for i in (0..<lastElementIndex).reversed() {
            let controlPointX = rhsArray[i].x - (ad[i] * solutionSet1[i + 1]!.x)
            let controlPointY = rhsArray[i].y - (ad[i] * solutionSet1[i + 1]!.y)
            
            solutionSet1[i] = CGPoint(x: controlPointX, y: controlPointY)
        }
        
        firstControlPoints = solutionSet1
        
        for i in (0..<segments) {
            if i == (segments - 1) {
                
                let lastDataPoint = data[i + 1]
                let p1 = firstControlPoints[i]
                guard let controlPoint1 = p1 else { continue }
                
                let controlPoint2X = (0.5)*(lastDataPoint.x + controlPoint1.x)
                let controlPoint2y = (0.5)*(lastDataPoint.y + controlPoint1.y)
                
                let controlPoint2 = CGPoint(x: controlPoint2X, y: controlPoint2y)
                secondControlPoints.append(controlPoint2)
            }else {
                
                let dataPoint = data[i+1]
                let p1 = firstControlPoints[i+1]
                guard let controlPoint1 = p1 else { continue }
                
                let controlPoint2X = 2*dataPoint.x - controlPoint1.x
                let controlPoint2Y = 2*dataPoint.y - controlPoint1.y
                
                secondControlPoints.append(CGPoint(x: controlPoint2X, y: controlPoint2Y))
            }
        }
        
        for i in (0..<segments) {
            guard let firstCP = firstControlPoints[i] else { continue }
            guard let secondCP = secondControlPoints[i] else { continue }
            
            let segmentControlPoint = CubicCurveSegment(firstControlPoint: firstCP, secondControlPoint: secondCP)
            controlPoints.append(segmentControlPoint)
        }
        
        return controlPoints
    }

}
