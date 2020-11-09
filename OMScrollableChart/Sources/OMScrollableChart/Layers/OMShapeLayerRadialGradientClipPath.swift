//
//  OMShapeLayerRadialGradientClipPath.swift
//  Example
//
//  Created by dsp on 17/10/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

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
    func defaultInitializer() {
        let scale = UIScreen.main.scale
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
    var locations: [CGFloat]?
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
