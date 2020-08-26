//
//  CAAnimation+Closure.swift
//  CAAnimation+Closures
//
//  Created by Honghao Zhang on 2/5/15.
//  Copyright (c) 2015 Honghao Zhang. All rights reserved.
//

import QuartzCore
/// CAAnimation Delegation class implementation
class CAAnimationHandler: NSObject, CAAnimationDelegate {
    /// start: A block (closure) object to be executed when the animation starts. This block has no return value and takes no argument.
    var start: (() -> Void)?
    /// completion: A block (closure) object to be executed when the animation ends.
    /// This block has no return value and takes a single Boolean argument that indicates
    ///  whether or not the animations actually finished.
    var completion: ((Bool) -> Void)?
	/**
	Called when the animation begins its active duration.
	
	- parameter theAnimation: the animation about to start
	*/
    func animationDidStart(_ theAnimation: CAAnimation) {
        start?()
    }
	
	/**
	Called when the animation completes its active duration or is removed from the object it is attached to.
	
	- parameter theAnimation: the animation about to end
	- parameter finished:     A Boolean value indicates whether or not the animations actually finished.
	*/
    func animationDidStop(_ theAnimation: CAAnimation, finished: Bool) {
        completion?(finished)
    }
}

public extension CAAnimation {
    /// A block (closure) object to be executed when the animation starts. This block has no return value and takes no argument.
    var start: (() -> Void)? {
        set {
			if let animationDelegate = delegate as? CAAnimationHandler {
				animationDelegate.start = newValue
			} else {
				let animationDelegate = CAAnimationHandler()
				animationDelegate.start = newValue
				delegate = animationDelegate
			}
        }
        
        get {
			if let animationDelegate = delegate as? CAAnimationHandler {
				return animationDelegate.start
			}
			
			return nil
        }
    }
    
    /// A block (closure) object to be executed when the animation ends.
    /// This block has no return value and takes a single Boolean argument that indicates whether or not the animations actually finished.
    var completion: ((Bool) -> Void)? {
        set {
			if let animationDelegate = delegate as? CAAnimationHandler {
				animationDelegate.completion = newValue
			} else {
				let animationDelegate = CAAnimationHandler()
				animationDelegate.completion = newValue
				delegate = animationDelegate
			}
        }
        
        get {
			if let animationDelegate = delegate as? CAAnimationHandler {
				return animationDelegate.completion
			}
			
			return nil
        }
    }
}

public extension CALayer {
    static var isAnimatingLayers: Int = 0
	/**
	Add the specified animation object to the layer’s render tree. Could provide a completion closure.
	
	- parameter anim:       The animation to be added to the render tree.
     This object is copied by the render tree, not referenced.
     Therefore, subsequent modifications to the object are not propagated into the render tree.
	- parameter key:        A string that identifies the animation.
     Only one animation per unique key is added to the layer.
     The special key kCATransition is automatically used for transition animations.
     You may specify nil for this parameter.
	- parameter completion: A block object to be executed when the animation ends.
     This block has no return value and takes a single Boolean argument that indicates whether
     or not the animations actually finished before the completion handler was called. Default value is nil.
	*/
	func add(_ anim: CAAnimation, forKey key: String?, withCompletion completion: ((Bool) -> Void)?) {
        CALayer.isAnimatingLayers += 1
        anim.completion = {  complete in
            completion?(complete)
            if complete {
                CALayer.isAnimatingLayers -= 1
            }
        }
		add(anim, forKey: key)
	}
}

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
        guard let first = self.points.first, let last = self.points.last else {
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

extension Array where Element: BezierPoint {
    func getBezierPath() -> BezierPath {
        let positions = self.map { $0.superlayer!.convert($0.position, to: nil) }
        return BezierPath(points: positions)
    }
    func getBezierVertices(count: Int = 100) -> [CGPoint] {
        let bezPath = self.getBezierPath()
        return bezPath.getNPoints(count: count)
    }
//    func getBezierGeometry(with count: Int = 100) -> SCNGeometry {
//        let points = self.getBezierVertices(count: count)
//        return SCNGeometry.line(points: points)
//    }
}

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
