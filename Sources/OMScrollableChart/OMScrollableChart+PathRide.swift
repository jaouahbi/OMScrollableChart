//
//  OMScrollableChart+PathRide.swift
//
//  Created by Jorge Ouahbi on 30/10/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit
import LibControl


extension OMScrollableChart {
    
    /// pathRideToPointAnimation
    /// - Parameters:
    ///   - cgPath: CGPath
    ///   - pointIndex: pointIndex
    ///   - timingFunction: CAMediaTimingFunction
    ///   - duration: animation duration
    /// - Returns: CAAnimation?
    private func pathRideToPointAnimation( cgPath: CGPath,
                                           sectionIndex: Int,
                                           startPoint: CGPoint? = nil,
                                   timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut),
                                   duration: TimeInterval) -> CAAnimation? {
        let percent: CFloat =  CFloat(1.0 / Double(self.numberOfSections) * Double(sectionIndex))
        return pathRideAnimation(cgPath: cgPath,
                                 percent: percent,
                                 duration: duration)
    }
    /// pathRideToPoint
    /// - Parameters:
    ///   - cgPath: CGPath
    ///   - sectionIndex: pointIndex
    ///   - startPoint: C GPoint
    ///   - timingFunction: CAMediaTimingFunction
    /// - Returns: CGPoint
    private func pathRideToPoint( cgPath: CGPath,
                                   sectionIndex: Int,
                                   startPoint: CGPoint? = nil,
                                   timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)) -> CGPoint {
        let percent: CFloat =  CFloat(1.0 / Double(self.numberOfSections) * Double(sectionIndex))
        animations.ridePath = Path(withTimingFunction: timingFunction)
        let point = animations.ridePath?.pointForPercentage(pathPercent: Double(percent), startPoint: startPoint) ?? .zero
        print("pointForPercentage",percent, point)
        return point
    }
    /// pathRideAnimation
    /// - Parameters:
    ///   - cgPath: CGPath
    ///   - percent: percent
    ///   - timingFunction: CAMediaTimingFunction
    ///   - duration: animation duration
    /// - Returns: CAAnimation
    private func pathRideAnimation( cgPath: CGPath,
                            percent: CFloat = 1.0,
                            startPoint: CGPoint? = nil,
                            timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut),
                            duration: TimeInterval) -> CAAnimation? {
        animations.ridePath = Path(withTimingFunction: timingFunction)


        let timesForFourthOfAnimation: Double
        let percents = animations.ridePath?.percentagesWhereYIs(y: Double(percent))
        if let curveLengthPercentagesForFourthOfAnimation = percents {
            if curveLengthPercentagesForFourthOfAnimation.count > 0 {
                if let originX = animations.ridePath?.pointForPercentage(pathPercent: curveLengthPercentagesForFourthOfAnimation[0],
                                                         startPoint: startPoint)?.x {
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
    ///   - duration: animation duration [TimeInterval]
    /// - Returns: CAAnimation
    public  func animateLayerPathRideToPoint(_ path: UIBezierPath,
                                     layerToRide: CALayer,
                                     sectionIndex: Int,
                                     duration: TimeInterval = 10.0) -> CAAnimation {
        
        animations.layerToRide = layerToRide
        animations.rideAnim = pathRideToPointAnimation(cgPath: path.cgPath,
                                                       sectionIndex: sectionIndex,
                                                       duration: duration)
        
        let anim = CABasicAnimation(keyPath: AnimationKeyPaths.rideProgresAnimationsKey)
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

