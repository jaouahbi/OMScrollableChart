//
//  OMScrollableChart+PathRide.swift
//
//  Created by Jorge Ouahbi on 30/10/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

extension OMScrollableChart {
    
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
