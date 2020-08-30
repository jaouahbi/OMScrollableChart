//
//  CALayer+Extensions.swift
//
//  Created by Jorge Ouahbi on 27/08/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

public extension CALayer {
    static var numberOfRunningAnimations: Int = 0
    func add(_ anim: CAAnimation,
             forKey key: String?,
             withCompletion completion: ((Bool) -> Void)?) {
        CALayer.numberOfRunningAnimations += 1
        anim.completion = {  complete in
            completion?(complete)
            if complete {
                CALayer.numberOfRunningAnimations -= 1
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

public extension CALayer {
    typealias LayerAnimation = (CALayer) -> CAAnimation
    
    var isModel: Bool {
        return self == self.model()
    }
    var rootLayer: CALayer? {
        var parent: CALayer? = self
        var layer: CALayer?
        repeat {
            layer = parent
            parent = parent?.superlayer
        } while (parent != nil)
        return layer
    }
    func isSublayerOfLayer(layer: CALayer) -> Bool {
        var ancestor: CALayer? = self.superlayer
        while (ancestor != nil) {
            if (ancestor == layer) {
                return true
            }
            ancestor = ancestor?.superlayer
        }
        return false
    }
    func sublayerNamed(name: String) -> CALayer? {
        return sublayersNamed(name: name)?.first
    }
    
    func sublayersNamed(name: String) -> [CALayer]? {
        let sublayers =  self.sublayers?.filter({$0.name?.hasPrefix(name) ?? false})
        return sublayers
    }
    // return all animations running by this layer.
    // the returned value is mutable
    var animations: [(String, CAAnimation)] {
        if let keys = animationKeys() {
            return keys.map { return ($0, self.animation(forKey: $0)!.copy() as! CAAnimation) }
        }
        return []
    }
    func flatTransformTo(layer: CALayer) -> CATransform3D {
        var layer = layer
        var trans = layer.transform
        while let superlayer = layer.superlayer, superlayer != self, !(superlayer.delegate is UIWindow) {
            trans = CATransform3DConcat(superlayer.transform, trans)
            layer = superlayer
        }
        return trans
    }

    @objc func tint(withColors colors: [UIColor]) {
        sublayers?.recursiveSearch(leafBlock: {
            backgroundColor = colors.first?.cgColor
        }) {
            $0.tint(withColors: colors)
        }
    }
    func removeAnimations(named name: String) {
        guard let keys = animationKeys() else { return }
        for animationKey in keys where animationKey.hasPrefix(name) {
            removeAnimation(forKey: animationKey)
        }
    }
    func playAnimation(_ layerAnimation: LayerAnimation, key: String, completion: (() -> Void)? = nil) {
        sublayers?.recursiveSearch(leafBlock: {
            DispatchQueue.main.async { CATransaction.begin() }
            DispatchQueue.main.async { CATransaction.setCompletionBlock(completion) }
            add(layerAnimation(self), forKey: key)
            DispatchQueue.main.async { CATransaction.commit() }
        }) {
            $0.playAnimation(layerAnimation, key: key, completion: completion)
        }
    }
    func stopAnimation(forKey key: String) {
        sublayers?.recursiveSearch(leafBlock: {
            removeAnimation(forKey: key)
        }) {
            $0.stopAnimation(forKey: key)
        }
    }
}

extension CAGradientLayer {
    public override func tint(withColors colors: [UIColor]) {
        sublayers?.recursiveSearch(leafBlock: {
            self.colors = colors.map { $0.cgColor }
        }) {
            $0.tint(withColors: colors)
        }
    }
}
