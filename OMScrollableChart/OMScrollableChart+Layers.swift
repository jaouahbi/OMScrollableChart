//
//  File.swift
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
    
    var gardientColor: UIColor = .red
    public lazy var insetGradient:GradientColors =  {
        return  (UIColor(red:0 / 255.0, green:0 / 255.0,blue: 0 / 255.0,alpha: 0 ),
                 UIColor(red: 0 / 255.0, green:0 / 255.0,blue: 0 / 255.0,alpha: 0.2 ))
        
    }()
    
    public lazy var shineGradient:GradientColors =  {
        return  (UIColor(red:1, green:1,blue: 1,alpha: 0 ),
                 UIColor(red: 1, green:1,blue:1,alpha: 0.8 ))
        
    }()
    
    
    public lazy var shadeGradient:GradientColors =  {
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
    
}

class OMShapeLayerLinearGradientClipPath: OMGradientShapeClipLayer {
    
    var start: CGPoint = CGPoint(x: 0.0, y: 0.5)
    var end: CGPoint = CGPoint(x: 1.0, y: 0.5)
    var locations: [CGFloat] =  [0.0, 0.1, 0.9, 1.0]
    var cgColors: [CGColor] {
        let color1 = gardientColor.withAlphaComponent(0.5)
        let color2 = gardientColor.withAlphaComponent(1.0)
        return [color1, color2, color2, color1].map({ (color) -> CGColor in
            return color.cgColor
        })
    }
    override init() {
        super.init()
        
        defaultInitializer()
    }
    
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
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors as CFArray, locations: locations) else {
            return
        }
        ctx.saveGState()
        ctx.drawLinearGradient(gradient, start: start, end: end, options: [])
        ctx.restoreGState()
    }
}
class OMShapeLayerRadialGradientClipPath: OMGradientShapeClipLayer {
   
    override init() {
        super.init()
        
        defaultInitializer()
    }
    
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
    
    
    var center: CGPoint {
        return CGPoint(x: bounds.width/2, y: bounds.height/2)
    }
    
    var radius: CGFloat {
        return (bounds.width + bounds.height)/2
    }
    
    var locations: [CGFloat] =  [0.0, 0.1, 0.9, 1.0]
    var gradientColor: UIColor = .red
    var cgColors: [CGColor] {
        
        let color1 = gradientColor.withAlphaComponent(0.5)
        let color2 = gradientColor.withAlphaComponent(1.0)
        return [color1, color2, color2, color1].map({ (color) -> CGColor in
            return color.cgColor
        })
    }
    
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors as CFArray, locations: locations) else {
            return
        }
        let endRadius = sqrt(pow(frame.width/2, 2) + pow(frame.height/2, 2))
        ctx.saveGState()
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0.0, endCenter: center, endRadius: endRadius, options: CGGradientDrawingOptions(rawValue: 0))
        ctx.restoreGState()
    }
}

var kUpY: CGFloat = 115
var kDownY: CGFloat = 310

extension OMScrollableChart {
    
    func touchDown() {
        animateTouchLayer(layer: self.layer, toY:kDownY, baseY:kUpY)
    }

   func touchUp(){
    animateTouchLayer(layer: self.layer, toY:kUpY, baseY:kDownY)
    }
    
    func animateTouchLayer(layer: CALayer, toY: CGFloat, baseY: CGFloat)  {
        let fromValue = layer.presentation()?.position ?? .zero
        let toValue = CGPoint(x:fromValue.x,y:toY)
        
        layer.position = toValue
        
        let animation = CABasicAnimation()
        animation.fromValue = NSValue(cgPoint: fromValue)
        animation.toValue = NSValue(cgPoint: toValue)
        animation.duration = CFTimeInterval(2.0 * (toValue.y - fromValue.y) / (toY - baseY))
        layer.add(animation, forKey:animation.keyPath)
        
    }
    /// animatePoints
    /// - Parameters:
    ///   - layers: CAShapeLayer
    ///   - delay: TimeInterval delay [0.1]
    ///   - duration: TimeInterval duration [ 2.0]
    func animatePoints(_ layers: [OMGradientShapeClipLayer], delay: TimeInterval = 0.1, duration: TimeInterval = 2.0) {
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
    
    func animateLayerOpacy( _ layer: CALayer,
                            fromValue: CGFloat,
                            toValue: CGFloat,
                            duration: TimeInterval = 1.0) {
        //layer.removeAllAnimations()
        //let fromValue =  self.contentSize.width /  self.contentOffset.x == 0 ? 1 :  self.contentOffset.x
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.toValue = toValue
        fadeAnimation.fromValue = fromValue
        fadeAnimation.beginTime = CACurrentMediaTime() + 0.5
        fadeAnimation.duration = duration
        fadeAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        fadeAnimation.fillMode = CAMediaTimingFillMode.forwards
        fadeAnimation.isRemovedOnCompletion = true
        layer.add(fadeAnimation, forKey: nil)
    }
    
    
    func animateOnSelectPoint(_ selectedLayer: OMGradientShapeClipLayer?, renderIndex:Int, duration: TimeInterval = 2.0) {
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
    
    func animateLineSelection(_ layer: OMGradientShapeClipLayer,_ newPath: CGPath, _ duration: TimeInterval = 1) {
        // the new origin of the CAShapeLayer within its view
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue =  layer.path           // animate from current position ...
        animation.toValue = newPath                        // ... to whereever the new position is
        animation.duration = duration
        animation.isAdditive = true
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        // set the shape's final position to be the new position so when the animation is done, it's at its new "home"
        layer.add(animation, forKey: nil)
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
    
    func animateLineOnSelectionPoint() {
       let fromValue = self.contentOffset.x / self.contentSize.width
       let growAnimation = CABasicAnimation(keyPath: "strokeEnd")
       //let fromValue =  self.contentSize.width /  self.contentOffset.x == 0 ? 1 :  self.contentOffset.x
       growAnimation.fromValue = fromValue
       growAnimation.toValue = 1
       growAnimation.beginTime = CACurrentMediaTime() + 0.5
       growAnimation.duration = 1.5
       growAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
       growAnimation.fillMode = CAMediaTimingFillMode.forwards
       growAnimation.isRemovedOnCompletion = false
       self.polylineLayer.add(growAnimation, forKey: "StrokeAnimation")
        
        //        let startAnimation = CABasicAnimation(keyPath: "strokeStart")
        //        startAnimation.fromValue = 0
        //        startAnimation.toValue = 0.8
        //
        //        let endAnimation = CABasicAnimation(keyPath: "strokeEnd")
        //        endAnimation.fromValue = 0.2
        //        endAnimation.toValue = 1.0
        //
        //        let animation = CAAnimationGroup()
        //        animation.animations = [startAnimation, endAnimation]
        //        animation.duration = 2
        //        catmullRomLineLayer.add(animation, forKey: "MyAnimation")
    }
}
