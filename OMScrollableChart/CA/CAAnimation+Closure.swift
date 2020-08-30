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
@objcMembers
class CALayerHandler: NSObject, CALayerDelegate {
    /// start: A block (closure) object to be executed when the animation starts. This block has no return value and takes no argument.
    var displayLayer: ((CALayer) -> Void)?
    var layoutSublayersLayer: ((CALayer) -> Void)?
    var willDrawLayer: ((CALayer) -> Void)?
    var drawLayer: ((CALayer, CGContext) -> Void)?
    var actionLayer:((CALayer, String) -> CAAction?)?
    func display(_ layer: CALayer) {
        print("[\(layer.name)] display")
        displayLayer?(layer)
    }
    @objc func draw(_ layer: CALayer, in ctx: CGContext) {
        print("[\(layer.name)] draw\(layer.model().frame) clip \(ctx.boundingBoxOfClipPath)")
        drawLayer?(layer, ctx)
    }
    @objc  func layerWillDraw(_ layer: CALayer){
        print("[\(layer.name)] layerWillDraw")
        willDrawLayer?(layer)
    }
    @objc  func layoutSublayers(of layer: CALayer){
        print("[\(layer.name)] \(layer.model().frame) \(layer.presentation()?.frame) layoutSublayers")
        layoutSublayersLayer?(layer)
    }

    @objc  func action(for layer: CALayer, forKey event: String) -> CAAction? {
        print("[\(layer.name)] ACTION \(event)")
        return actionLayer?(layer, event)
    }
}

extension CALayer {
    
//    func animationProgress( layers: [CALayer], progress: CGFloat, animationDuration: TimeInterval) {
//        if (progress == 1) {
//            for bounceLayer in layers {
//                // Continue the animation from wherever it had manually progressed to.
//                var beginTime = bounceLayer.timeOffset;
//                bounceLayer.speed = 1.0
//                beginTime = bounceLayer.convertTime(CACurrentMediaTime(), from: nil) - beginTime;
//                bounceLayer.beginTime = beginTime
//            }
//        } else {
//            let animationDuration = animationDuration
//            for bounceLayer in sublayers! {
//                bounceLayer.timeOffset = Double(progress) * animationDuration
//            }
//        }
//    }

    
    static var handler: CALayerHandler = CALayerHandler()
    var displayLayer: ((CALayer) -> Void)? {
           set {
               if let animationDelegate = delegate as? CALayerHandler {
                   animationDelegate.displayLayer = newValue
               } else {
                let animationDelegate = CALayer.handler
                   animationDelegate.displayLayer = newValue
                   delegate = animationDelegate
               }
           }
           get {
               if let animationDelegate = delegate as? CALayerHandler {
                   return animationDelegate.displayLayer
               }
               
               return nil
           }
       }
    var layoutSublayersLayer: ((CALayer) -> Void)? {
           set {
               if let animationDelegate = delegate as? CALayerHandler {
                   animationDelegate.layoutSublayersLayer = newValue
               } else {
                   let animationDelegate = CALayer.handler
                   animationDelegate.layoutSublayersLayer = newValue
                   delegate = animationDelegate
               }
           }
           get {
               if let animationDelegate = delegate as? CALayerHandler {
                   return animationDelegate.layoutSublayersLayer
               }
               
               return nil
           }
       }
    var willDrawLayer: ((CALayer) -> Void)? {
           set {
               if let animationDelegate = delegate as? CALayerHandler {
                   animationDelegate.willDrawLayer = newValue
               } else {
                   let animationDelegate = CALayer.handler
                   animationDelegate.willDrawLayer = newValue
                   delegate = animationDelegate
               }
           }
           get {
               if let animationDelegate = delegate as? CALayerHandler {
                   return animationDelegate.willDrawLayer
               }
               
               return nil
           }
       }
    var drawLayer: ((CALayer, CGContext) -> Void)? {
           set {
               if let animationDelegate = delegate as? CALayerHandler {
                   animationDelegate.drawLayer = newValue
               } else {
                   let animationDelegate = CALayer.handler
                   animationDelegate.drawLayer = newValue
                   delegate = animationDelegate
               }
           }
           get {
               if let animationDelegate = delegate as? CALayerHandler {
                   return animationDelegate.drawLayer
               }
               
               return nil
           }
       }
    var actionLayer:((CALayer, String) -> CAAction?)? {
           set {
               if let animationDelegate = delegate as? CALayerHandler {
                   animationDelegate.actionLayer = newValue
               } else {
                   let animationDelegate = CALayer.handler
                   animationDelegate.actionLayer = newValue
                   delegate = animationDelegate
               }
           }
           get {
               if let animationDelegate = delegate as? CALayerHandler {
                   return animationDelegate.actionLayer
               }
               
               return nil
           }
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
