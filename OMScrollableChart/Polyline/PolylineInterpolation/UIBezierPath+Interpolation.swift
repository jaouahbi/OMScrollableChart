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

/*
 import UIKit
 import PlaygroundSupport

 typealias Radians = CGFloat

 extension UIBezierPath {

     static func simonWedge(innerRadius: CGFloat, outerRadius: CGFloat, centerAngle: Radians, gap: CGFloat) -> UIBezierPath {
         let innerAngle: Radians = CGFloat.pi / 4 - gap / (2 * innerRadius)
         let outerAngle: Radians = CGFloat.pi / 4 - gap / (2 * outerRadius)
         let path = UIBezierPath()
         path.addArc(withCenter: .zero, radius: innerRadius, startAngle: centerAngle - innerAngle, endAngle: centerAngle + innerAngle, clockwise: true)
         path.addArc(withCenter: .zero, radius: outerRadius, startAngle: centerAngle + outerAngle, endAngle: centerAngle - outerAngle, clockwise: false)
         path.close()
         return path
     }

 }

 class SimonWedgeView: UIView {
     override init(frame: CGRect) {
         super.init(frame: frame)
         commonInit()
     }

     required init?(coder decoder: NSCoder) {
         super.init(coder: decoder)
         commonInit()
     }

     var centerAngle: Radians = 0 { didSet { setNeedsDisplay() } }
     var color: UIColor = #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1) { didSet { setNeedsDisplay() } }

     override func draw(_ rect: CGRect) {
         let path = wedgePath()
         color.setFill()
         path.fill()
     }

     private func commonInit() {
         contentMode = .redraw
         backgroundColor = .clear
         isOpaque = false
     }

     private func wedgePath() -> UIBezierPath {
         let bounds = self.bounds
         let outerRadius = min(bounds.size.width, bounds.size.height) / 2
         let innerRadius = outerRadius / 2
         let gap = (outerRadius - innerRadius) / 4
         let path = UIBezierPath.simonWedge(innerRadius: innerRadius, outerRadius: outerRadius, centerAngle: centerAngle, gap: gap)
         path.apply(CGAffineTransform(translationX: bounds.midX, y: bounds.midY))
         return path
     }
 }

 let rootView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
 rootView.backgroundColor = .white

 func addWedgeView(color: UIColor, angle: Radians) {
     let wedgeView = SimonWedgeView(frame: rootView.bounds)
     wedgeView.color = color
     wedgeView.centerAngle = angle
     rootView.addSubview(wedgeView)
 }

 addWedgeView(color: #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1), angle: 0)
 addWedgeView(color: #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1), angle: 0.5 * .pi)
 addWedgeView(color: #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1), angle: .pi)
 addWedgeView(color: #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1), angle: 1.5 * .pi)

 PlaygroundPage.current.liveView = rootView
 */
public enum CatmullRomCurvePrameterization: CGFloat {
    case uniform = 0.0
    case centripetal = 0.5
    case chordal = 1.0
}
extension UIBezierPath {
    convenience init(pointsForLine points: [CGPoint]) {
        self.init()
        move(to: points[0])
        for index in 0..<points.count {
            addLine(to: points[index])
        }
    }
    convenience init?(pointPoints: [CGPoint], pointSize: CGFloat) {
        self.init()
        // Interpolation points drawing
        for point in pointPoints {
            let pointPath = UIBezierPath(ovalIn: CGRect(x: point.x-(pointSize * 0.5),
                                                        y: point.y-(pointSize * 0.5),
                                                        width: pointSize,
                                                        height: pointSize))
            self.append(pointPath)
        }
    }
    convenience init?(points: [CGPoint], maxYPosition: CGFloat, closed: Bool = false) {
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
                //     addLine(to: CGPoint(x: value.x, y: CGFloat(maxYPosition)))
            }
        }
        if closed {
            self.close()
        }
        
    }
    /// Create an UIBezierPath instance from a sequence of points which is drawn smoothly.
    ///
    /// - Parameter points: points of the path.
    /// - Returns: smoothed UIBezierPath.
    convenience init?(smoothedPoints: [CGPoint], maxYPosition: CGFloat = 0, closed: Bool = false) {
        self.init()
        guard smoothedPoints.count > 1 else {
            return nil
        }
        var prevPoint: CGPoint?
        for (index, point) in smoothedPoints.enumerated() {
            if index == 0 {
                self.move(to: CGPoint(x: point.x, y: CGFloat(maxYPosition)))
                if maxYPosition != 0 {
                    
                    self.move(to: CGPoint(x: point.x, y: CGFloat(maxYPosition)))
                } else {
                    self.move(to: point)
                }
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
                if maxYPosition != 0 {
                    addLine(to: CGPoint(x: point.x, y: CGFloat(maxYPosition)))
                }
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
    convenience init?(cubicCurvePoints: [CGPoint], maxYPosition: CGFloat = 0) {
        self.init()
        guard !cubicCurvePoints.isEmpty else { return }
        let controlPoints = CubicCurveAlgorithm().controlPointsFromPoints(data: cubicCurvePoints)
        for index in 0..<cubicCurvePoints.count {
            let point = cubicCurvePoints[index]
            if index == 0 {
                if maxYPosition == 0 {
                    self.move(to: point)
                } else {
                    move(to: CGPoint(x: point.x, y: CGFloat(maxYPosition)))
                }
            } else {
                let segment = controlPoints[index-1]
                self.addCurve(to: point,
                              controlPoint1: segment.firstControlPoint,
                              controlPoint2: segment.secondControlPoint)
                if index == cubicCurvePoints.count - 1 {
                    if maxYPosition != 0 {
                        addLine(to: CGPoint(x: point.x, y: CGFloat(maxYPosition)))
                    }
                }
            }
        }
    }
    ///
    /// Init
    /// - Parameter hermitePoints: points
    /// - Parameter alpha: Commonly used values of alpha are 0.0, 0.5, and 1.0,
    /// corresponding to uniform, centripetal, and chordal parameterizations of the curves.
    convenience init?(hermitePoints: [CGPoint], maxYPosition: CGFloat = 0, alpha: CGFloat = 0.5) {
        self.init()
        guard !hermitePoints.isEmpty else { return }
        
        if maxYPosition == 0 {
            self.move(to: hermitePoints[0])
        } else {
            self.move(to: CGPoint(x: hermitePoints[0].x, y: CGFloat(maxYPosition)))
        }
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
                if maxYPosition != 0 {
                    addLine(to: CGPoint(x: endPoint.x, y: CGFloat(maxYPosition)))
                }
            }
        }
    }
    ///
    /// Init
    /// - Parameter catmullRomPoints: points
    /// - Parameter alpha: Commonly used values of alpha are 0.0, 0.5, and 1.0,
    /// corresponding to uniform, centripetal, and chordal parameterizations of the curves.
    convenience init?(catmullRomPoints: [CGPoint], alpha: CGFloat) {
        if catmullRomPoints.count < 2 {
            return nil
        } else if catmullRomPoints.count < 3 {
            self.init()
            move(to: catmullRomPoints[0])
            addLine(to: catmullRomPoints[1])
            return
        } else {
            var startPoint = [catmullRomPoints[0].addTo(catmullRomPoints[1].deltaTo(catmullRomPoints[0]).multiplyBy(-1))]
            startPoint += catmullRomPoints
            startPoint.append(catmullRomPoints.last!.addTo(catmullRomPoints[catmullRomPoints.count-2].deltaTo(catmullRomPoints[catmullRomPoints.count-1]).multiplyBy(-1)))
            self.init()
            let startIndex = 1
            let endIndex = startPoint.count - 2
            for index in startIndex..<endIndex {
                let p0 = startPoint[index-1 < 0 ? startPoint.count - 1 : index - 1]
                let p1 = startPoint[index]
                let p2 = startPoint[(index+1)%startPoint.count]
                let p3 = startPoint[(index+1)%startPoint.count + 1]
                let d1 = p1.deltaTo(p0).hypotenuse
                let d2 = p2.deltaTo(p1).hypotenuse
                let d3 = p3.deltaTo(p2).hypotenuse
                var b1 = p2.multiplyBy(pow(d1, 2 * alpha))
                b1 = b1.deltaTo(p0.multiplyBy(pow(d2, 2 * alpha)))
                b1 = b1.addTo(p1.multiplyBy(2 * pow(d1, 2 * alpha) + 3 * pow(d1, alpha) * pow(d2, alpha) + pow(d2, 2 * alpha)))
                b1 = b1.multiplyBy(1.0 / (3 * pow(d1, alpha) * (pow(d1, alpha) + pow(d2, alpha))))
                var b2 = p1.multiplyBy(pow(d3, 2 * alpha))
                b2 = b2.deltaTo(p3.multiplyBy(pow(d2, 2 * alpha)))
                b2 = b2.addTo(p2.multiplyBy(2 * pow(d3, 2 * alpha) + 3 * pow(d3, alpha) * pow(d2, alpha) + pow(d2, 2 * alpha)))
                b2 = b2.multiplyBy(1.0 / (3 * pow(d3, alpha) * (pow(d3, alpha) + pow(d2, alpha))))
                if index == startIndex {
                    move(to: p1)
                }
                addCurve(to: p2, controlPoint1: b1, controlPoint2: b2)
            }
        }
    }
    convenience init(hermiteInterpolation points: [CGPoint], tauX: CGFloat = 1/3, tauY: CGFloat = 1/3, bufferRatio: CGFloat? = nil) {
        self.init()
        guard points.count > 1 else { return }
        guard points.count > 2 else {
            self.move(to: points[0])
            self.addLine(to: points[1])
            return
        }
        self.move(to: points.first!)
        let numberOfCurves = points.count - 1
        var prevPoint = points.first!
        var currentPoint : CGPoint
        var nextPoint : CGPoint
        var endPoint : CGPoint
        for index in 0..<numberOfCurves{
            currentPoint = points[index]
            nextPoint = points[index+1]
            endPoint = nextPoint
            var mPointX: CGFloat
            var mPointY: CGFloat
            var preventCurveX: CGFloat = 1
            var preventCurveY: CGFloat = 1
            if index > 0 {
                mPointX = (nextPoint.x - prevPoint.x) * 0.5
                mPointY = (nextPoint.y - prevPoint.y) * 0.5
                if let bufferRatio = bufferRatio{
                    let ratioX = (currentPoint.x - prevPoint.x)/(nextPoint.x - currentPoint.x)
                    if ratioX > bufferRatio {
                        preventCurveX = 2/bufferRatio
                    }
                    let ratioY = (currentPoint.y - prevPoint.y)/(nextPoint.y - currentPoint.y)
                    if ratioY > bufferRatio {
                        preventCurveY = 2/bufferRatio
                    }
                }
            } else {
                mPointX = (nextPoint.x - currentPoint.x) * 0.5
                mPointY = (nextPoint.y - currentPoint.y) * 0.5
            }
            let controlPoint1 = CGPoint(x: currentPoint.x + mPointX * tauX * preventCurveX, y: currentPoint.y + mPointY * tauY * preventCurveY)
            prevPoint = currentPoint
            currentPoint = nextPoint
            nextPoint = index + 2 > numberOfCurves ? points[0] : points[index+2]
            preventCurveX = 1
            preventCurveY = 1
            if index < numberOfCurves - 1 {
                mPointX = (nextPoint.x - prevPoint.x) * 0.5
                mPointY = (nextPoint.y - prevPoint.y) * 0.5
                if let bufferRatio = bufferRatio{
                    let ratioX = (nextPoint.x - currentPoint.x)/(currentPoint.x - prevPoint.x)
                    if ratioX > bufferRatio {
                        preventCurveX = 2/bufferRatio
                    }
                    let ratioY = (nextPoint.y - currentPoint.y)/(currentPoint.y - prevPoint.y)
                    if ratioY > bufferRatio {
                        preventCurveY = 2/bufferRatio
                    }
                }
            } else {
                mPointX = (currentPoint.x - prevPoint.x) * 0.5
                mPointY = (currentPoint.y - prevPoint.y) * 0.5
            }
            let controlPoint2 = CGPoint(x: currentPoint.x - mPointX * tauX * preventCurveX, y: currentPoint.y - mPointY * tauY * preventCurveX)
            self.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        }
        return
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
        let points = self.cgPath.elementsPoints()
        let xs = points.map({Double($0.x)})
        let ys = points.map({Double($0.y)})
        let regression = linearRegression(xs, ys)
        return regression
        //        let y1 = linearRegression(1) //Result is 1.6
        //        let y2 = linearRegression(3) //Result is 2.8
    }
}


extension UIBezierPath {
    convenience init(sinusoidFrom point1: CGPoint, point2: CGPoint, frequency: CGFloat, amplitude: CGFloat) {
        self.init()
        let distance = point1.deltaTo(point2).hypotenuse
        let nodes = [CGFloat](stride(from: .pi/2 * frequency, to: distance, by: .pi * frequency))
        let rotation = atan(point1.slopeTo(point2))
        let rotationTransform = CGAffineTransform(rotationAngle: rotation)
        let peaks = nodes.enumerated().map {(index, value) -> CGPoint in
            let amp = index % 2 == 0 ? amplitude : -amplitude
            return CGPoint(x: value, y: amp).applying(rotationTransform).addTo(point1)
        }
        let lastPt = CGPoint(x: nodes.last! + .pi/2 * frequency, y: 0).applying(rotationTransform).addTo(point1)
        let curve = UIBezierPath(catmullRomPoints: [point1] + peaks + [lastPt], alpha: 0.75)!
        self.append(curve)
    }
}
