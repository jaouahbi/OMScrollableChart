//
//  OMPointLayer.swift
//  Example
//
//  Created by dsp on 29/06/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

class OMPointLayer: CAShapeLayer {
    override init(layer: Any) {
        super.init(layer: layer)
    }
    var center: CGPoint {
        return CGPoint(x: bounds.width/2, y: bounds.height/2)
    }
    var radius: CGFloat {
        return (bounds.width + bounds.height)/2
    }
    var colors: [UIColor] = [UIColor.clear, UIColor.clear] {
        didSet {
            setNeedsDisplay()
        }
    }
    var locations: [CGFloat] = [0.0, 1.0]
    var cgColors: [CGColor] {
        return colors.map({ (color) -> CGColor in
            return color.cgColor
        })
    }
    override init() {
        super.init()
        needsDisplayOnBoundsChange = true
    }
    required init(coder aDecoder: NSCoder) {
        super.init()
    }
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        ctx.saveGState()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors as CFArray, locations: locations) else {
            return
        }
        let endRadius = sqrt(pow(frame.width/2, 2) + pow(frame.height/2, 2))
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0.0, endCenter: center, endRadius: endRadius, options: CGGradientDrawingOptions(rawValue: 0))
    }
}
