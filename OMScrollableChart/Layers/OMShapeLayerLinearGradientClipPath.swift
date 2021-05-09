//
//  File.swift
//  Example
//
//  Created by dsp on 17/10/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

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
