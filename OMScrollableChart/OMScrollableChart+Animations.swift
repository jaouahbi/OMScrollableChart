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
        animGroup.animating = { progress in
            animGroup.animations?.forEach({$0.animating?(progress)})
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
        animation.autoreverses  = true
        animation.delegate      = self
        animation.completion = {  finished in
            CATransaction.withDisabledActions({
                shapeLayer.path = pathEnd.cgPath
            })
        }
        return animation
    }
    
    func animateFollowingPath(_ shapeLayer: CAShapeLayer,
                              _ path: UIBezierPath?,
                              _ duration: TimeInterval = 5.0) -> CAAnimation {
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.duration    = duration
        animation.path        = path?.cgPath
        animation.calculationMode = .paced
        animation.rotationMode = .rotateAuto
        animation.autoreverses  = true
        animation.delegate      = self
        animation.completion = {  finished in
            guard let lastPoint = self.renderLayers[Renders.points.rawValue].last else {
                return
            }
            CATransaction.withDisabledActions({
                shapeLayer.position = lastPoint.position
                shapeLayer.opacity  = 1.0
            })
        }
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
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        animation.completion = { finished in
            CATransaction.withDisabledActions({
                shapeLayer.path = newPath.cgPath
            })
        }
        return animation
    }
    
    func animationWithFadeGroup(_ layer: CALayer,
                                fromValue: CGFloat = 0,
                                toValue: CGFloat = 1.0,
                                animation: CAAnimation) -> CAAnimation {
        let duration = animation.duration
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.toValue  = toValue
        fadeAnimation.fromValue  = fromValue
        fadeAnimation.fillMode = .forwards
        fadeAnimation.autoreverses = true
        fadeAnimation.isRemovedOnCompletion = false
        fadeAnimation.completion = { finished in
            CATransaction.withDisabledActions({
                layer.opacity = Float(toValue)
            })
        }
        let animGroup = CAAnimationGroup()
        animGroup.animations = [animation, fadeAnimation]
        animGroup.duration = duration
        animGroup.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        animGroup.delegate = self
        animGroup.start = {
            animGroup.animations?.forEach({$0.start?()})
        }
        animGroup.animating = { progress in
            animGroup.animations?.forEach({$0.animating?(progress)})
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
        fadeAnimation.autoreverses = true
        fadeAnimation.duration = duration
        fadeAnimation.isRemovedOnCompletion = false
        fadeAnimation.completion = { finished in
            CATransaction.withDisabledActions({
                layer.opacity = Float(toValue)
            })
        }
        return fadeAnimation
    }
}
