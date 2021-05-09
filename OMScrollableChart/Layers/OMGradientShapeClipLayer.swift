//
//  OMGradientShapeClipLayer.swift
//  Example
//
//  Created by dsp on 17/10/2020.
//  Copyright © 2020 dsp. All rights reserved.
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
}
