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


import UIKit
import LibControl

// MARK: - UIGestureRecognizerDelegate -
extension OMScrollableChart {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    @objc public func pathNearPointsHandlePan(_ recognizer: UIPanGestureRecognizer) {
        guard ![.ended, .cancelled, .failed].contains(recognizer.state) else {
            lineShapeLayer.path = nil
            startPointShapeLayer.path = nil
            return
        }
        let location = recognizer.location(in: self)
        if let  closestPoint = bezier?.findClosestPointOnPath(fromPoint: location) {
            drawLine(fromPoint: location,
                     toPoint: closestPoint)
        }
    }
    
    public var elementWidthPerSectionPerPage: Double {
        Double(sectionWidth) / Double(numberOfSectionsPerPage)
    }
    
    public var numberOfElements: Int {
        self.dataSource?.dataPoints(chart: self,
                                    renderIndex: RenderIdent.points.rawValue, section: 0).count ?? 0
    }
    
    public var elementsPerSectionPerPage: Double {
        Double(numberOfElements) / Double(numberOfSectionsPerPage)
    }
    
    
    
    /// animationScrollingProgressToPage
    /// - Parameters:
    ///   - duration: TimeInterval
    ///   - page: Int
    public func animationScrollingProgressToPage(_ duration: TimeInterval, page: Int, completion: (() -> Void)? = nil) {
        let delay: TimeInterval = 0.5
        let preTimeOffset: TimeInterval = 1.0
        let duration: TimeInterval = duration + delay - preTimeOffset
        layoutIfNeeded()
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: .curveEaseInOut,
                       animations: {
                        self.contentOffset.x = (self.bounds.size.width / CGFloat(self.numberOfPages)) * CGFloat(page)
                       }, completion: { completed in
                        if self.animations.isAnimatePointsClearOpacity,
                           !self.animations.isAnimatePointsClearOpacityDone
                        {
                            self.animatePointsClearOpacity()
                            self.animations.isAnimatePointsClearOpacityDone = true
                        }
                        
                        if completed {
                            completion?()
                        }
                       })
    }
    
    public func animationProgressRide(layerToRide: CALayer?,
                                                 renderIndex: Int,
                                                 scrollAnimation: Bool = false,
                                                 page: Int = 1) {
        if let anim = animations.rideAnim {
            if let layerRide = layerToRide {
                CATransaction.withDisabledActions {
                    layerRide.transform = CATransform3DIdentity
                }
                if scrollAnimation {
                    animationScrollingProgressToPage(anim.duration, page: page) {
                        
                    }
                }
                
                layerRide.add(anim, forKey: AnimationKeyPaths.aroundAnimationKey, withCompletion: { _ in
                    if let presentationLayer = layerRide.presentation() {
                        CATransaction.withDisabledActions {
                            layerRide.position = presentationLayer.position
                            layerRide.transform = presentationLayer.transform
                        }
                    }
                    self.animationDidEnded(renderIndex: Int(renderIndex), animation: anim)
                    layerRide.removeAnimation(forKey: AnimationKeyPaths.aroundAnimationKey)
                })
            }
        }
    }


    public func debugLayoutLimit() {
           print("""
                        [LAYOUT] pages \(numberOfPages)
                        elements \(numberOfElements)
                        element in section \(Double(numberOfSectionsPerPage * numberOfElements) * Double(1.0 / Double(numberOfElements))) %
                       sections \(numberOfSections)
                       section elements \(elementsPerSectionPerPage)
                       selection elements width: \(elementWidthPerSectionPerPage)
               
                       contentOffset \(self.contentOffset)
                       contentSize \(self.contentSize)
                       bounds \(contentView.bounds) \(bounds)
               """)
    }


    
    public func addPrivateGestureRecognizer() {
        self.addGestureRecognizer(pathNearPointsPanGesture)
        self.addGestureRecognizer(longPress)
    }
    
    
    public func drawLine(fromPoint: CGPoint, toPoint: CGPoint, width: CGFloat = 6.0) {
        let path = UIBezierPath()
        path.move(to: fromPoint)
        path.addLine(to: toPoint)
        
        lineShapeLayer.path = path.cgPath
        
        let ovalPath = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: fromPoint.x - width * 0.5, y: fromPoint.y - width * 0.5), size: CGSize(width: width, height: width)))
        
        startPointShapeLayer.path = ovalPath.cgPath
    }
    
    @discardableResult
    public func drawDot(onLayer parentLayer: CALayer, atPoint point: CGPoint, atSize size: CGSize,  color: UIColor, alpha: CGFloat = 0.65) -> CAShapeLayer {
        let layer = ShapeRadialGradientLayer()
        let frame = CGRect(origin: CGPoint(x: point.x - size.width * 0.5, y: point.y - size.height * 0.5), size: size)
        let path = UIBezierPath(ovalIn: frame)
        layer.path = path.cgPath
        layer.lineWidth = 1.0
        layer.strokeColor = color.withAlphaComponent(alpha).cgColor
        layer.fillColor = UIColor.clear.cgColor
        parentLayer.addSublayer(layer)
        dotPathLayers.append(layer)
        return layer
    }
}

