//
//  CAAnimation+Closure.swift
//  CAAnimation+Closures
//
//  Created by Honghao Zhang on 2/5/15.
//  Copyright (c) 2015 Honghao Zhang. All rights reserved.
//

import QuartzCore

import UIKit
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

/// CAAnimation Delegation class implementation

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
