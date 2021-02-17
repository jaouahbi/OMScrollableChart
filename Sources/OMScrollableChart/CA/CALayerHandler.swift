//
//  CALayerHandler.swift
//  Example
//
//  Created by Jorge Ouahbi on 30/08/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit
//
//
//@objcMembers
//class CALayerHandler: NSObject, CALayerDelegate {
//    /// start: A block (closure) object to be executed when the animation starts. This block has no return value and takes no argument.
//    var displayLayer: ((CALayer) -> Void)?
//    var layoutSublayersLayer: ((CALayer) -> Void)?
//    var willDrawLayer: ((CALayer) -> Void)?
//    var drawLayer: ((CALayer, CGContext) -> Void)?
//    var actionLayer:((CALayer, String) -> CAAction?)?
//    func display(_ layer: CALayer) {
//        print("[\(layer.name)] display")
//        displayLayer?(layer)
//    }
//    @objc func draw(_ layer: CALayer, in ctx: CGContext) {
//        print("[\(layer.name)] draw\(layer.model().frame) clip \(ctx.boundingBoxOfClipPath)")
//        drawLayer?(layer, ctx)
//    }
//    @objc  func layerWillDraw(_ layer: CALayer){
//        print("[\(layer.name)] layerWillDraw")
//        willDrawLayer?(layer)
//    }
//    @objc  func layoutSublayers(of layer: CALayer){
//        print("[\(layer.name)] \(layer.model().frame) \(layer.presentation()?.frame) layoutSublayers")
//        layoutSublayersLayer?(layer)
//    }
//
//    @objc  func action(for layer: CALayer, forKey event: String) -> CAAction? {
//        print("[\(layer.name)] ACTION \(event)")
//        return actionLayer?(layer, event)
//    }
//}
//
//extension CALayer {
//
////    func animationProgress( layers: [CALayer], progress: CGFloat, animationDuration: TimeInterval) {
////        if (progress == 1) {
////            for bounceLayer in layers {
////                // Continue the animation from wherever it had manually progressed to.
////                var beginTime = bounceLayer.timeOffset;
////                bounceLayer.speed = 1.0
////                beginTime = bounceLayer.convertTime(CACurrentMediaTime(), from: nil) - beginTime;
////                bounceLayer.beginTime = beginTime
////            }
////        } else {
////            let animationDuration = animationDuration
////            for bounceLayer in sublayers! {
////                bounceLayer.timeOffset = Double(progress) * animationDuration
////            }
////        }
////    }
//
//
//    static var handler: CALayerHandler = CALayerHandler()
//    var displayLayer: ((CALayer) -> Void)? {
//           set {
//               if let animationDelegate = delegate as? CALayerHandler {
//                   animationDelegate.displayLayer = newValue
//               } else {
//                let animationDelegate = CALayer.handler
//                   animationDelegate.displayLayer = newValue
//                   delegate = animationDelegate
//               }
//           }
//           get {
//               if let animationDelegate = delegate as? CALayerHandler {
//                   return animationDelegate.displayLayer
//               }
//
//               return nil
//           }
//       }
//    var layoutSublayersLayer: ((CALayer) -> Void)? {
//           set {
//               if let animationDelegate = delegate as? CALayerHandler {
//                   animationDelegate.layoutSublayersLayer = newValue
//               } else {
//                   let animationDelegate = CALayer.handler
//                   animationDelegate.layoutSublayersLayer = newValue
//                   delegate = animationDelegate
//               }
//           }
//           get {
//               if let animationDelegate = delegate as? CALayerHandler {
//                   return animationDelegate.layoutSublayersLayer
//               }
//
//               return nil
//           }
//       }
//    var willDrawLayer: ((CALayer) -> Void)? {
//           set {
//               if let animationDelegate = delegate as? CALayerHandler {
//                   animationDelegate.willDrawLayer = newValue
//               } else {
//                   let animationDelegate = CALayer.handler
//                   animationDelegate.willDrawLayer = newValue
//                   delegate = animationDelegate
//               }
//           }
//           get {
//               if let animationDelegate = delegate as? CALayerHandler {
//                   return animationDelegate.willDrawLayer
//               }
//
//               return nil
//           }
//       }
//    var drawLayer: ((CALayer, CGContext) -> Void)? {
//           set {
//               if let animationDelegate = delegate as? CALayerHandler {
//                   animationDelegate.drawLayer = newValue
//               } else {
//                   let animationDelegate = CALayer.handler
//                   animationDelegate.drawLayer = newValue
//                   delegate = animationDelegate
//               }
//           }
//           get {
//               if let animationDelegate = delegate as? CALayerHandler {
//                   return animationDelegate.drawLayer
//               }
//
//               return nil
//           }
//       }
//    var actionLayer:((CALayer, String) -> CAAction?)? {
//           set {
//               if let animationDelegate = delegate as? CALayerHandler {
//                   animationDelegate.actionLayer = newValue
//               } else {
//                   let animationDelegate = CALayer.handler
//                   animationDelegate.actionLayer = newValue
//                   delegate = animationDelegate
//               }
//           }
//           get {
//               if let animationDelegate = delegate as? CALayerHandler {
//                   return animationDelegate.actionLayer
//               }
//
//               return nil
//           }
//       }
//}

public extension CALayer {
    static var isAnimatingLayers: Int = 0
    func add(_ anim: CAAnimation,
             forKey key: String?,
             withCompletion completion: ((Bool) -> Void)?) {
        CALayer.isAnimatingLayers += 1
        anim.completion = {  complete in
            completion?(complete)
            if complete {
                CALayer.isAnimatingLayers -= 1
            }
        }
        add(anim, forKey: key)
    }
//    func addSublayer(_ layer: CALayer, delegate: CALayerDelegate? = nil) {
//        if let delegate = delegate {
//            layer.delegate = delegate
//        }
//        addSublayer(layer)
//    }
//     func insertSublayer(_ layer: CALayer, at idx: UInt32, delegate: CALayerDelegate? = nil) {
//        if let delegate = delegate {
//            layer.delegate = delegate
//        }
//        insertSublayer(layer, at: idx)
//    }
//    func insertSublayer(_ layer: CALayer, below sibling: CALayer?, delegate: CALayerDelegate? = nil){
//        if let delegate = delegate {
//            layer.delegate = delegate
//        }
//        insertSublayer(layer, below: sibling)
//    }
//    func insertSublayer(_ layer: CALayer, above sibling: CALayer?, delegate: CALayerDelegate? = nil){
//        if let delegate = delegate {
//            layer.delegate = delegate
//        }
//        insertSublayer(layer, above: sibling)
//    }
//    func replaceSublayer(_ oldLayer: CALayer, with newLayer: CALayer, delegate: CALayerDelegate? = nil) {
//        if let delegate = delegate {
//            newLayer.delegate = delegate
//        }
//        //remplazcd the delagte?
//        replaceSublayer(oldLayer, with: newLayer)
//    }
}
