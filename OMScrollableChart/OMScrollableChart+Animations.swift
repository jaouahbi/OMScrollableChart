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
//  OMScrollableChart+Animations
//  CanalesDigitalesGCiOS
//
//  Created by Jorge Ouahbi on 16/08/2020.
//  Copyright © 2020 Banco Caminos. All rights reserved.
//

import UIKit
extension OMScrollableChart {
    func animateLineStrokeEnd( _ layer: CAShapeLayer,
                               fromValue: CGFloat = 0,
                               toValue: CGFloat = 1.0,
                               duration: TimeInterval = 0.4) -> CAAnimation {
        let growAnimation = CABasicAnimation(keyPath: "strokeEnd")
        growAnimation.fromValue = fromValue
        growAnimation.toValue = toValue
        growAnimation.beginTime = CACurrentMediaTime()
        growAnimation.duration = duration
        growAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        growAnimation.fillMode = .forwards
        growAnimation.isRemovedOnCompletion = false
        return growAnimation
    }
    func animateLineStrokeStartStrokeEnd( _ layer: CAShapeLayer,
                                          fromValue: CGFloat = 0,
                                          toValue: CGFloat = 1.0,
                                          rangeValue: CGFloat = 0.2,
                                          duration: TimeInterval = 0.4)  -> CAAnimation {
        let startAnimation = CABasicAnimation(keyPath: "strokeStart")
        startAnimation.fromValue = fromValue
        startAnimation.toValue = toValue - rangeValue
        
        let endAnimation = CABasicAnimation(keyPath: "strokeEnd")
        endAnimation.fromValue = rangeValue
        endAnimation.toValue = toValue
        
        let animGroup = CAAnimationGroup()
        animGroup.animations = [startAnimation, endAnimation]
        animGroup.duration = duration
        
        animGroup.start = {
            animGroup.animations?.forEach({$0.start?()})
        }
        animGroup.completion = { finished in
            animGroup.animations?.forEach({$0.completion?(finished)})
        }
        return animGroup
    }
    
    func animateLayerPath( _ shapeLayer: CAShapeLayer,
                           pathStart: UIBezierPath,
                           pathEnd: UIBezierPath,
                           duration: TimeInterval = 0.5) -> CAAnimation {
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue     = pathStart.cgPath
        animation.toValue       = pathEnd.cgPath
        animation.duration      = duration
        animation.isRemovedOnCompletion  = false
        animation.fillMode = .forwards
        animation.delegate      = self
        animation.completion = {  finished in
            CATransaction.withDisabledActions({
                shapeLayer.path = pathEnd.cgPath
            })
        }
        return animation
    }
    
    func animateFollowingPath(_ shapeLayer: CALayer,
                              _ path: UIBezierPath?,
                              _ duration: TimeInterval = 10.0) -> CAAnimation {
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.duration    = duration
        animation.path        = path?.cgPath
        animation.calculationMode = .paced
        animation.rotationMode = .rotateAuto
        animation.delegate      = self
        animation.isRemovedOnCompletion  = false
        animation.fillMode = .forwards
        
        animation.completion = {  finished in
            if finished {
                let lastPoint = self.renderLayers.flatMap({$0}).max(by: { $0.frame.origin.x <= $1.frame.origin.x})
                let position = lastPoint?.position ?? CGPoint.zero
                CATransaction.withDisabledActions({
                    shapeLayer.position = position
                    shapeLayer.opacity  = 1.0
                })
            }
        }
        
        //
        //       animation.start = {
        ////           let spring = CASpringAnimation(keyPath: "position.x")
        ////           spring.damping = 5
        ////           spring.fromValue = self.contentOffset.x
        ////           spring.toValue  = position.x
        ////           spring.duration = spring.settlingDuration
        ////           shapeLayer.add(spring, forKey: nil)
        //            self.isAnimatingLayers += 1
        //       }
        ////
        ////        let animator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
        ////            shapeLayer.position = position
        ////        }
        ////        animator.fractionComplete = 1.0;
        //
        
        return animation
    }
    
    func animateLineSelection(_ shapeLayer: CAShapeLayer,
                              _ newPath: UIBezierPath,
                              _ duration: TimeInterval = 0.4) -> CAAnimation {
        // the new origin of the CAShapeLayer within its view
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue =  shapeLayer.path
        animation.toValue = newPath
        animation.duration = duration
        animation.isAdditive = true
        animation.delegate = self
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.completion = { finished in
            CATransaction.withDisabledActions({
                shapeLayer.path = newPath.cgPath
            })
        }
        return animation
    }
    
    func animationOpacity(_ layer: CALayer,
                            fromValue: CGFloat = 0,
                            toValue: CGFloat = 1.0,
                            duration: TimeInterval = 4.0) -> CAAnimation {
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.toValue    = toValue
        fadeAnimation.fromValue  = fromValue
        fadeAnimation.fillMode   = .forwards
        fadeAnimation.duration   = duration
        fadeAnimation.isRemovedOnCompletion = false
        fadeAnimation.completion = { finished in
            CATransaction.withDisabledActions {
                layer.opacity = Float(toValue)
            }
        }
        return fadeAnimation
    }
        
    func animationWithFadeGroup(_ layer: CALayer,
                                fromValue: CGFloat = 0,
                                toValue: CGFloat = 1.0,
                                animations: [CAAnimation],
                                duration: TimeInterval = 1.0) -> CAAnimation {
        let duration = duration
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.toValue  = toValue
        fadeAnimation.fromValue  = fromValue
        fadeAnimation.fillMode = .forwards
        fadeAnimation.delegate = self
        fadeAnimation.isRemovedOnCompletion = false
        fadeAnimation.completion = { finished in
            CATransaction.withDisabledActions{
                layer.opacity = Float(toValue)
            }
        }
        let animGroup = CAAnimationGroup()
        animGroup.animations = [fadeAnimation] + animations
        animGroup.duration = duration
        animGroup.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        animGroup.delegate = self
        animGroup.start = {
            animGroup.animations?.forEach({$0.start?()})
        }
        animGroup.completion = { finished in
            animGroup.animations?.forEach({$0.completion?(finished)})
        }
        return animGroup
    }
    func animationWithFade(_ layer: CALayer,
                           fromValue: CGFloat = 0,
                           toValue: CGFloat = 1.0,
                           duration: TimeInterval = 0.4) -> CAAnimation {
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.toValue  = toValue
        fadeAnimation.fromValue  = fromValue
        fadeAnimation.fillMode = .forwards
        fadeAnimation.duration = duration
        fadeAnimation.delegate = self
        fadeAnimation.isRemovedOnCompletion = false
        fadeAnimation.completion = { finished in
            CATransaction.withDisabledActions({
                layer.opacity = Float(toValue)
            })
        }
        return fadeAnimation
    }
    
    
    func pathRideToPointAnimation( cgPath: CGPath,
                                   pointIndex: Int,
                                   timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut),
                                   duration: TimeInterval) -> CAAnimation? {
        let percent: CFloat =  CFloat(1.0 / Double(self.numberOfSections) * Double(pointIndex))
        return pathRideAnimation(cgPath: cgPath,
                                 percent: percent,
                                 duration: duration)
    }
    func pathRideToPoint( cgPath: CGPath,
                                   pointIndex: Int,
                                   timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)) -> CGPoint {
        let percent: CFloat =  CFloat(1.0 / Double(self.numberOfSections) * Double(pointIndex))
        self.ridePath = Path(withTimingFunction: timingFunction)
        let point =  self.ridePath?.pointForPercentage(pathPercent: Double(percent)) ?? .zero
        return point
    }
    func pathRideAnimation( cgPath: CGPath,
                            percent: CFloat = 1.0,
                            timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut),
                            duration: TimeInterval) -> CAAnimation? {
        self.ridePath = Path(withTimingFunction: timingFunction)
        let timesForFourthOfAnimation: Double
        if let curveLengthPercentagesForFourthOfAnimation = ridePath?.percentagesWhereYIs(y: Double(percent)) {
            if curveLengthPercentagesForFourthOfAnimation.count > 0 {
                if let originX = ridePath?.pointForPercentage(pathPercent: curveLengthPercentagesForFourthOfAnimation[0])?.x {
                    timesForFourthOfAnimation = Double(originX)
                } else {
                    timesForFourthOfAnimation = 1
                }
            } else {
                timesForFourthOfAnimation = 1
            }
            let anim = CAKeyframeAnimation(keyPath: "position")
            anim.path = cgPath
            anim.rotationMode = CAAnimationRotationMode.rotateAuto
            anim.fillMode = CAMediaTimingFillMode.forwards
            anim.duration = duration
            anim.timingFunction = timingFunction
            anim.isRemovedOnCompletion = false
            anim.delegate = self
            
            anim.repeatCount = Float(timesForFourthOfAnimation)
            return anim
        }
        return nil
    }
    /// animateLayerPathRideToPoint
    /// - Parameters:
    ///   - path: UIBezierPath
    ///   - layerToRide: CALayer
    ///   - pointIndex: Int
    ///   - duration: TimeInterval
    /// - Returns: CAAnimation
    func animateLayerPathRideToPoint(_ path: UIBezierPath,
                                     layerToRide: CALayer,
                                     pointIndex: Int,
                                     duration: TimeInterval = 10.0) -> CAAnimation {
        self.layerToRide = layerToRide
        self.rideAnim = pathRideToPointAnimation(cgPath: path.cgPath,
                                                 pointIndex: pointIndex,
                                                 duration: duration)
        let anim = CABasicAnimation(keyPath: "rideProgress")
        anim.fromValue = NSNumber(value: 0)
        anim.toValue   = NSNumber(value: 1.0)
        anim.fillMode = .forwards
        anim.duration = duration
        anim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        anim.isRemovedOnCompletion = false
        anim.delegate = self
        
        return anim
    }
}
