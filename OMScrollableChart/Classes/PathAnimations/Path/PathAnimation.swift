//
//  PathAnimation.swift
//  Example
//
//  Created by Jorge Ouahbi on 30/08/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

#if os(macOS)
public typealias VectorVal = CGFloat
#else
public typealias VectorVal = Float
#endif
//internal func - (left: CGPoint, right: CGPoint) -> CGPoint {
//    return CGPoint(x: left.x - right.x, y: left.y - right.y)
//}
//internal func + (left: CGPoint, right: CGPoint) -> CGPoint {
//    return CGPoint(x: left.x + right.x, y: left.y + right.y)
//}
internal func * (left: CGPoint, right: VectorVal) -> CGPoint {
    return CGPoint(x: left.x * CGFloat(right), y: left.y * CGFloat(right))
}


public class BezierPath {
    private let points: [CGPoint]
    public init(points: [CGPoint]) {
        self.points = points
    }
    /// Get position along bezier curve at a given time
    ///
    /// - Parameter time: Time as a percentage along bezier curve
    /// - Returns: position on the bezier curve
    public func posAt(time: TimeInterval) -> CGPoint {
        guard let first = self.points.first,
              let last = self.points.last else {
            print("NO POINTS IN BezierPath")
            return .zero
        }
        if time == 0 {
            return first
        } else if time == 1 {
            return last
        }

        #if os(macOS)
        let tFloat = CGFloat(time)
        #else
        let tFloat = Float(time)
        #endif

        var high = self.points.count
        var current = 0
        var rtn = self.points
        while high > 0 {
            while current < high - 1 {
                rtn[current] = rtn[current] * (1 - tFloat) + rtn[current + 1] * tFloat
                current += 1
            }
            high -= 1
            current = 0
        }
        return rtn.first!
    }
    /// Collection of points evenly separated along the bezier curve from beginning to end
    ///
    /// - Parameters:
    ///   - count: how many points you want
    ///   - interpolator: time interpolator for easing
    /// - Returns: array of "count" points the points on the bezier curve
    public func getNPoints(
        count: Int, interpolator: ((TimeInterval) -> TimeInterval)? = nil
    ) -> [CGPoint] {
        var bezPoints: [CGPoint] = Array(repeating: .zero, count: count)
        for time in 0..<count {
            let tNow = TimeInterval(time) / TimeInterval(count - 1)
            bezPoints[time] = self.posAt(
                time: interpolator == nil ? tNow : interpolator!(tNow)
            )
        }
        return bezPoints
    }
}


class BezierPoint: CAShapeLayer {
    init(at position: CGPoint) {
        super.init()
        self.position = position
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//extension Array where Element: BezierPoint {
//    func getBezierPath() -> BezierPath {
//        let positions = self.map { $0.superlayer!.convert($0.position, to: nil) }
//        return BezierPath(points: positions)
//    }
//    func getBezierVertices(count: Int = 100) -> [CGPoint] {
//        let bezPath = self.getBezierPath()
//        return bezPath.getNPoints(count: count)
//    }
//    func getBezierGeometry(with count: Int = 100) -> SCNGeometry {
//        let points = self.getBezierVertices(count: count)
//        return SCNGeometry.line(points: points)
//    }
//}

extension CAAnimation
{
    /// Move along a BezierPath
    ///
    /// - Parameters:
    ///   - path: SCNBezierPath to animate along
    ///   - duration: time to travel the entire path
    ///   - fps: how frequent the position should be updated (default 30)
    ///   - interpolator: time interpolator for easing
    /// - Returns: SCNAction to be applied to a node
    class func moveAlong(
        path: BezierPath,
        duration: TimeInterval,
        fps: Int = 30,
        interpolator: ((TimeInterval) -> TimeInterval)? = nil
    ) -> [CAAnimation] {
        let actions = path.getNPoints(count: Int(duration) * fps, interpolator: interpolator).map { (point) -> CAAnimation in
            let tInt = 1 / TimeInterval(fps)
            let spring = CASpringAnimation(keyPath: "position")
            spring.damping = 5
            spring.duration = tInt
            spring.toValue  = point
            //spring.duration = spring.settlingDuration
            return spring
        }
        //return SCNAction.sequence(actions)
        print(actions)
        return actions
    }

    /// Move along a Bezier Path represented by a list of SCNVector3
    ///
    /// - Parameters:
    ///   - path: List of points to for m Bezier Path to animate along
    ///   - duration: time to travel the entire path
    ///   - fps: how frequent the position should be updated (default 30)
    ///   - interpolator: time interpolator for easing (see InterpolatorFunctions)
    /// - Returns: SCNAction to be applied to a node
    class func moveAlong(
        bezier path: [CGPoint], duration: TimeInterval,
        fps: Int = 30, interpolator: ((TimeInterval) -> TimeInterval)? = nil
    ) -> [CAAnimation] {
        return CAAnimation.moveAlong(
            path: BezierPath(points: path),
            duration: duration, fps: fps,
            interpolator: interpolator
        )
    }
}
