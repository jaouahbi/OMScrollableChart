//
//  OMGlassLayer.swift
//
//  Created by Jorge Ouahbi on 28/09/2020.
//  Copyright © 2020 Jorge Ouahbi. All rights reserved.
//

import UIKit

//class OMStrokedShapeLayer: CAShapeLayer {
//    /// Contructors
//    override init() {
//        super.init()
//        setNeedsLayout()
//    }
//
//    override init(layer: Any) {
//        super.init(layer: layer)
//        setNeedsLayout()
//    }
//
//    required public init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        setNeedsLayout()
//    }
//
//    override func layoutSublayers() {
//        super.layoutSublayers()
//        setNeedsDisplay()
//    }
//
//    override func render(in ctx: CGContext) {
//        super.render(in: ctx)
//    }
//    override func draw(in ctx: CGContext) {
//        super.draw(in: ctx)
//        if self.isHidden {
//            // Nothing to do.
//            return
//        }
//        ctx.clear(ctx.boundingBoxOfClipPath)
//        if let path = path {
//            let strokePoints = path.points()
//            ctx.strokeGradient( path: path,
//                           points: strokePoints,
//                           color: UIColor.flatOrange,
//                           lineWidth: 8,
//                           fadeFactor: 0.5)
//        }
//    }
//}

class OMGlassLayer: CALayer {
    private let glassEffectGradient = CGGradient(colorSpace: CGColorSpaceCreateDeviceRGB(),
                                                   colorComponents: [1.0, 1.0, 1.0, 0.2, 1.0, 1.0, 1.0, 0.0], locations: nil, count: 2)!
    private var lowerCircleRadius:CGFloat = 0
    private var lowerCircleCenterPoint:CGPoint = CGPoint.zero
    private var lowerChordLeftPoint:CGPoint  = CGPoint.zero
    private var lowerChordRightPoint:CGPoint = CGPoint.zero
    
    private var upperCircleRadius:CGFloat = 0
    private var upperRectGlassCenterPoint:CGPoint = CGPoint.zero
    private var upperChordLeftPoint:CGPoint = CGPoint.zero
    private var upperChordRightPoint:CGPoint = CGPoint.zero
    
    /// Glass effect
    private var rectGlassLeft:CGRect  = CGRect.zero;
    private var rectGlassRight:CGRect = CGRect.zero;
    
    /// Contructors
    override init() {
        super.init()
        setNeedsLayout()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        setNeedsLayout()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setNeedsLayout()
    }
    
    /// Set glass effect
    public var glassEffect:Bool = true {
        didSet {
            setNeedsLayout()
        }
    }
    /// Draw glass effect
    ///
    /// - Parameter context: current context
    fileprivate func drawGlassEffect(context: CGContext,
                                     glassEffectGradient: CGGradient,
                                     rectGlassLeft: CGRect,
                                     rectGlassRight: CGRect ) {
        
        let options  = CGGradientDrawingOptions(rawValue: 0)
        let endPointLeft = CGPoint(x:bounds.midX ,y: upperChordLeftPoint.y)
        let endPointRight = CGPoint(x:bounds.midX ,y: upperChordRightPoint.y)
        
        // left glass effect
        context.setStrokeColor(UIColor.white.cgColor)
        context.addRect(rectGlassLeft)
        context.closePath()
        context.saveGState()
        //context.strokePath()
        context.clip()
        context.drawLinearGradient(glassEffectGradient,
                                   start: upperChordLeftPoint,
                                   end: endPointLeft,
                                   options: options)
        context.restoreGState()
        
        // right glass effect
        context.addRect(rectGlassRight)
        context.closePath()
        
        context.saveGState()
        //context.strokePath()
        context.clip()
        context.drawLinearGradient(glassEffectGradient,
                                   start: upperChordRightPoint,
                                   end: endPointRight,
                                   options: options)
        context.restoreGState()
    }
    override public func draw(in ctx: CGContext) {
        if self.isHidden {
            // Nothing to do.
            return
        }
        ctx.clear(ctx.boundingBoxOfClipPath)
        // Draw the glass effect.
        if glassEffect {
            drawGlassEffect(context: ctx,
                            glassEffectGradient: glassEffectGradient,
                            rectGlassLeft: rectGlassLeft,
                            rectGlassRight: rectGlassRight)
        }
    }
    override func layoutSublayers() {
        super.layoutSublayers()

        let layerBounds        = self.bounds
        lowerCircleRadius      = layerBounds.height / 8
        lowerCircleCenterPoint = CGPoint(x:self.bounds.midX, y: layerBounds.height - lowerCircleRadius)
        lowerChordLeftPoint    = CGPoint(x:(lowerCircleCenterPoint.x - CGFloat(cos(.pi / 4.0)) * lowerCircleRadius),
                                         y:(lowerCircleCenterPoint.y - CGFloat(sin(.pi / 4.0)) * lowerCircleRadius))
        lowerChordRightPoint   = CGPoint(x:(lowerCircleCenterPoint.x + CGFloat(cos(.pi / 4.0)) * lowerCircleRadius),
                                         y:(lowerCircleCenterPoint.y - CGFloat(sin(.pi / 4.0)) * lowerCircleRadius))
        upperCircleRadius         = (lowerChordRightPoint.x - lowerChordLeftPoint.x) * 0.5
        upperRectGlassCenterPoint = CGPoint(x:self.bounds.midX, y:upperCircleRadius)
        upperChordLeftPoint       = CGPoint(x:lowerChordLeftPoint.x, y:upperRectGlassCenterPoint.y)
        upperChordRightPoint      = CGPoint(x:lowerChordRightPoint.x,y:upperRectGlassCenterPoint.y)
        rectGlassLeft             = CGRect(x:upperChordLeftPoint.x, y:self.bounds.minY,
                                           width:upperRectGlassCenterPoint.x - upperChordLeftPoint.x, height:layerBounds.height)
        rectGlassRight            = CGRect(x:upperRectGlassCenterPoint.x,y:self.bounds.minY,
                                           width:upperChordRightPoint.x - upperRectGlassCenterPoint.x, height:layerBounds.height)
        
        setNeedsDisplay()
    }
}
