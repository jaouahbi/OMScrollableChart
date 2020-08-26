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
//  OMScrollableChart+Layers
//  CanalesDigitalesGCiOS
//
//  Created by Jorge Ouahbi on 16/08/2020.
//  Copyright © 2020 Banco Caminos. All rights reserved.
//

import UIKit

typealias GradientColors = (UIColor, UIColor)


// Layer with clip path
class OMShapeLayerClipPath: CAShapeLayer {
    func addPathAndClipIfNeeded(ctx: CGContext) {
        if let path = self.path {
            ctx.addPath(path)
            if self.strokeColor != nil {
                ctx.setLineWidth(self.lineWidth)
                ctx.replacePathWithStrokedPath()
            }
            ctx.clip()
        }
    }
    override public func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        addPathAndClipIfNeeded(ctx: ctx)
    }
}
// shape layer with clip path and gradient friendly
class OMGradientShapeClipLayer: OMShapeLayerClipPath {
    // Some predefined Gradients (from WebKit)
    
    var gardientColor: UIColor = .clear
    public lazy var insetGradient: GradientColors =  {
        return  (UIColor(red:0 / 255.0, green:0 / 255.0,blue: 0 / 255.0,alpha: 0 ),
                 UIColor(red: 0 / 255.0, green:0 / 255.0,blue: 0 / 255.0,alpha: 0.2 ))
        
    }()
    
    public lazy var shineGradient: GradientColors =  {
        return  (UIColor(red:1, green:1,blue: 1,alpha: 0 ),
                 UIColor(red: 1, green:1,blue:1,alpha: 0.8 ))
        
    }()
    
    
    public lazy var shadeGradient: GradientColors =  {
        return  (UIColor(red: 252 / 255.0, green: 252 / 255.0,blue: 252 / 255.0,alpha: 0.65 ),
                 UIColor(red:  178 / 255.0, green:178 / 255.0,blue: 178 / 255.0,alpha: 0.65 ))
        
    }()
    
    
    public lazy var convexGradient:GradientColors =  {
        return  (UIColor(red:1,green:1,blue:1,alpha: 0.43 ),
                 UIColor(red:1,green:1,blue:1,alpha: 0.5 ))
        
    }()
    
    
    public lazy var concaveGradient:GradientColors =  {
        return  (UIColor(red:1,green:1,blue:1,alpha: 0.0 ),
                 UIColor(red:1,green:1,blue:1,alpha: 0.46 ))
        
    }()
    
//    override var position: CGPoint {
//        didSet {
//            print(name, position)
//        }
//    }
    
}
// MARK: - OMShapeLayerLinearGradientClipPath -
class OMShapeLayerLinearGradientClipPath: OMGradientShapeClipLayer {
    
    var start: CGPoint = CGPoint(x: 0.0, y: 0.5)
    var end: CGPoint = CGPoint(x: 1.0, y: 0.5)
    var locations: [CGFloat]? =  [0.0, 0.1]
    var gradientColor: UIColor = .clear
    var cgColors: [CGColor] {
        return gradientColor.makeGradient().map({ (color) -> CGColor in
            return color.cgColor
        })
    }
    override init() {
        super.init()
        
        defaultInitializer()
    }
//    override var position: CGPoint {
//        didSet {
//            print(name, position)
//        }
//    }
//
    override init(layer: Any) {
        super.init(layer: layer)
        
        defaultInitializer()
    }
    
    func defaultInitializer() {
        let scale =  UIScreen.main.scale
        contentsScale = scale
        needsDisplayOnBoundsChange = true
        drawsAsynchronously = true
        allowsGroupOpacity = true
        shouldRasterize = true
        rasterizationScale = scale
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        defaultInitializer()
    }
    
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: colorSpace,
                                        colors: cgColors as CFArray,
                                        locations: locations) else {
            return
        }
        ctx.saveGState()
        ctx.drawLinearGradient(gradient, start: start, end: end, options: [])
        ctx.restoreGState()
    }
}

// MARK: - OMShapeLayerRadialGradientClipPath -
class OMShapeLayerRadialGradientClipPath: OMGradientShapeClipLayer {
    
    override init() {
        super.init()
        
        defaultInitializer()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        
        defaultInitializer()
    }
//    override var position: CGPoint {
//        didSet {
//            print(name, position)
//        }
//    }
    func defaultInitializer() {
        let scale =  UIScreen.main.scale
        contentsScale = scale
        needsDisplayOnBoundsChange = true
        drawsAsynchronously = true
        allowsGroupOpacity = true
        shouldRasterize = true
        rasterizationScale = scale
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        defaultInitializer()
    }
    
    var center: CGPoint {
        return CGPoint(x: bounds.width/2, y: bounds.height/2)
    }
    
    var startRadius: CGFloat?
    var endRadius: CGFloat?
    var locations: [CGFloat]? = [0, 1.0]
    var gradientColor: UIColor = .clear
    var cgColors: [CGColor] {
        return gradientColor.makeGradient().map({ (color) -> CGColor in
            return color.cgColor
        })
        
    }
    
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let gradient = CGGradient(colorsSpace: colorSpace,
                                        colors: cgColors as CFArray,
                                        locations: locations) else {
                                            return
        }
        let startRadius = self.startRadius ?? (bounds.width + bounds.height)/2
        let endRadius   = self.endRadius ?? sqrt(pow(startRadius, 2) + pow(startRadius, 2))
        ctx.saveGState()
        ctx.drawRadialGradient(gradient,
                               startCenter: center,
                               startRadius: 0,
                               endCenter: center,
                               endRadius: endRadius,
                               options: [.drawsAfterEndLocation])
        ctx.restoreGState()
    }
}

//var kUpY: CGFloat = 115
//var kDownY: CGFloat = 310

extension OMScrollableChart {
    
//    func touchDown() {
//        animateTouchLayer(layer: self.layer, toY:kDownY, baseY:kUpY)
//    }
//
//    func touchUp(){
//        animateTouchLayer(layer: self.layer, toY:kUpY, baseY:kDownY)
//    }
//
//    func animateTouchLayer(layer: CALayer, toY: CGFloat, baseY: CGFloat)  {
//        let fromValue = layer.presentation()?.position ?? .zero
//        let toValue = CGPoint(x:fromValue.x,y:toY)
//
//        layer.position = toValue
//
//        let animation = CABasicAnimation()
//        animation.fromValue = NSValue(cgPoint: fromValue)
//        animation.toValue = NSValue(cgPoint: toValue)
//        animation.duration = CFTimeInterval(2.0 * (toValue.y - fromValue.y) / (toY - baseY))
//        layer.add(animation, forKey:animation.keyPath)
//
//    }
    /// animatePoints
    /// - Parameters:
    ///   - layers: CAShapeLayer
    ///   - delay: TimeInterval delay [0.1]
    ///   - duration: TimeInterval duration [ 2.0]
    func animatePoints(_ layers: [OMGradientShapeClipLayer],
                       delay: TimeInterval = 0.1,
                       duration: TimeInterval = 2.0) {
        var currentDelay = delay
        for point in layers {
            point.opacity = 1
            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
            fadeAnimation.toValue = 0.3
            fadeAnimation.beginTime = CACurrentMediaTime() + currentDelay
            fadeAnimation.duration = duration
            fadeAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            fadeAnimation.fillMode = CAMediaTimingFillMode.forwards
            fadeAnimation.isRemovedOnCompletion = false
            point.add(fadeAnimation, forKey: nil)
            currentDelay += 0.05
        }
    }
    
//    func animateLayerOpacy( _ layer: CALayer,
//                            fromValue: CGFloat,
//                            toValue: CGFloat,
//                            duration: TimeInterval = 1.0) {
//        //layer.removeAllAnimations()
//        //let fromValue =  self.contentSize.width /  self.contentOffset.x == 0 ? 1 :  self.contentOffset.x
//        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
//        fadeAnimation.toValue = toValue
//        fadeAnimation.fromValue = fromValue
//        fadeAnimation.beginTime = CACurrentMediaTime() + 0.5
//        fadeAnimation.duration = duration
//        fadeAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
//        fadeAnimation.fillMode = CAMediaTimingFillMode.forwards
//        fadeAnimation.isRemovedOnCompletion = true
//        layer.add(fadeAnimation, forKey: nil)
//    }
    
    /// animateOnRenderLayerSelection
    /// - Parameters:
    ///   - selectedLayer: OMGradientShapeClipLayer
    ///   - renderIndex: render index
    ///   - duration: TimeInterval [2.0]
    func animateOnRenderLayerSelection(_ selectedLayer: OMGradientShapeClipLayer?,
                                       renderIndex:Int,
                                       duration: TimeInterval = 2.0) {
        var index: Int = 0
        guard renderLayers.count > 0 else {
            return
        }
        if let selectedLayer = selectedLayer {
            index = self.renderLayers[renderIndex].firstIndex(of: selectedLayer) ?? 0
        }
        let count = self.renderLayers[renderIndex].count - 1
        let pointBegin = self.renderLayers[renderIndex].takeElements(index)
        let pointEnd   = self.renderLayers[renderIndex].takeElements(count - index,
                                                                     startAt: index + 1)
        animatePoints(pointBegin.reversed(), duration: duration)
        animatePoints(pointEnd, duration: duration)
        
    }

    
    func animateDashLinesPhase() {
        for layer in dashLineLayers {
            let animation = CABasicAnimation(keyPath: "lineDashPhase")
            animation.fromValue = 0
            animation.toValue = layer.lineDashPattern?.reduce(0) { $0 - $1.intValue } ?? 0
            animation.duration = 1
            animation.repeatCount = .infinity
            layer.add(animation, forKey: "line")
        }
    }
    //let fromValue =  self.contentSize.width /  self.contentOffset.x == 0 ? 1 :  self.contentOffset.x
     // self.contentOffset.x / self.contentSize.width
    
   
}
