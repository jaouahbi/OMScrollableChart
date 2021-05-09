// Copyright 2018 Jorge Ouahbi
//
// Licensed under the Apache License, Version 2.0 (the "License")
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

@IBDesignable
class OMBubbleShapeView: UIView {
    @IBInspectable var lineWidth:    CGFloat = 1         { didSet { setNeedsDisplay() } }
    @IBInspectable var calloutSize:  CGFloat = 7.5       { didSet { setNeedsDisplay() } }
    @IBInspectable var fillColor:    UIColor = .paleGrey { didSet { setNeedsDisplay() } }
    @IBInspectable var shadowGradientColor: UIColor = .paleGrey { didSet { setNeedsDisplay() } }
    @IBInspectable var strokeColor:  UIColor = UIColor(white: 0.91, alpha: 1.0)   { didSet { setNeedsDisplay() } }
    @IBInspectable var drawGlossEffect: Bool = true
    @IBInspectable  var isFlipped: Bool = false { didSet {setNeedsDisplay()}}
    var calloutDirection: CalloutDirection = .left { didSet {setNeedsDisplay()}}
    var gradientMask: UIImage? { return isFlipped ? gradientMaskInvert : gradientMaskNormal}
    internal let rgbColorspace = CGColorSpaceCreateDeviceRGB()
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        defaultLayerInitializer()
    }
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setNeedsDisplay()
    }
    func defaultLayerInitializer() {
        let scale =  UIScreen.main.scale
        layer.contentsScale = scale
        layer.needsDisplayOnBoundsChange = true
        layer.drawsAsynchronously = true
        layer.allowsGroupOpacity = true
        layer.shouldRasterize = true
        layer.rasterizationScale = scale
    }
    func drawGlossy(context: CGContext, rect: CGRect, startPoint: CGPoint,  endPoint: CGPoint) {
        // Draw the gloss gradient
        let numberOfLocations = 2
        let locations:[CGFloat] = [ 0.0, 1.0 ]
        let components:[CGFloat] = [ 1.0, 1.0, 1.0, 0.35,   // Start color
            1.0, 1.0, 1.0, 0.06 ] // End color
        if let glossGradient = CGGradient(colorSpace: rgbColorspace,
                                          colorComponents: components,
                                          locations: locations,
                                          count: numberOfLocations) {
            
            context.drawLinearGradient(glossGradient,
                                       start: startPoint,
                                       end: endPoint,
                                       options: CGGradientDrawingOptions(rawValue: 0))
        }
    }
    
    func  drawShadowGradient(context: CGContext,
                             rect: CGRect,
                             shadowColor: UIColor,
                             topCenter: CGPoint,
                             bottomCenter: CGPoint) {
        
        let numberOfLocations = 2
        var locationsShadowGradient:[CGFloat] = [0.0, 1.0]
        var red: CGFloat = 0,
        green: CGFloat = 0,
        blue: CGFloat = 0,
        alpha: CGFloat = 0
        
        if shadowColor.getRed(&red,
                              green: &green,
                              blue: &blue,
                              alpha: &alpha) {
            
            var componentsShadowGradient: [CGFloat] = [red, green, blue, 0,
                                                       red, green, blue, 0.6]
            
            if let shadowGradient = CGGradient(colorSpace: rgbColorspace,
                                               colorComponents: &componentsShadowGradient,
                                               locations: &locationsShadowGradient,
                                               count: numberOfLocations) {
                context.drawLinearGradient(shadowGradient,
                                           start: topCenter,
                                           end: bottomCenter,
                                           options: CGGradientDrawingOptions(rawValue: 0))
            }
        }
    }
    enum CalloutDirection: Int {
        case center
        case left
        case right
    }
    /// Build the callout clip path in the direction drectioin
    /// - Parameters:
    ///   - direction: CalloutDirection
    ///   - isFlipped: filp it?
    /// - Returns: UIBezierPath
    func calloutClipPath( with direction: CalloutDirection,
                          isFlipped: Bool = false) -> UIBezierPath {
        let rect = bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        let path = UIBezierPath()
        // lower left corner
        path.move(to: CGPoint(x: rect.minX + layer.cornerRadius, y: rect.maxY - calloutSize))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - calloutSize - layer.cornerRadius),
                          controlPoint: CGPoint(x: rect.minX, y: rect.maxY - calloutSize))
        // left
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + layer.cornerRadius))
        // upper left corner
        path.addQuadCurve(to: CGPoint(x: rect.minX + layer.cornerRadius, y: rect.minY),
                          controlPoint: CGPoint(x: rect.minX, y: rect.minY))
        
        // top
        path.addLine(to: CGPoint(x: rect.maxX - layer.cornerRadius, y: rect.minY))
        // upper right corner
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + layer.cornerRadius),
                          controlPoint: CGPoint(x: rect.maxX, y: rect.minY))
        // right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - calloutSize - layer.cornerRadius))
        // lower right corner
        path.addQuadCurve(to: CGPoint(x: rect.maxX - layer.cornerRadius,
                                      y: rect.maxY - calloutSize),
                          controlPoint: CGPoint(x: rect.maxX, y: rect.maxY - calloutSize))
        switch direction {
        case .center:
            // bottom center (including callout)
            path.addLine(to: CGPoint(x: rect.midX + calloutSize, y: rect.maxY - calloutSize))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX - calloutSize, y: rect.maxY - calloutSize))
            
        case .left:
            path.addLine(to: CGPoint(x: rect.minX + layer.cornerRadius + calloutSize, y: rect.maxY - calloutSize))
            path.addLine(to: CGPoint(x: rect.minX + calloutSize, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + calloutSize, y: rect.maxY - calloutSize))
            
        case .right:
            path.addLine(to: CGPoint(x: rect.maxX - calloutSize - layer.cornerRadius, y: rect.maxY - calloutSize))
            path.addLine(to: CGPoint(x: rect.maxX - calloutSize, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - calloutSize, y: rect.maxY - calloutSize))
        }
        path.close()
        if isFlipped {
            let mirror = CGAffineTransform(scaleX: 1, y: -1)
            let translate = CGAffineTransform(translationX: 0, y: rect.size.height)
            let concatenated = mirror.concatenating(translate)
            path.apply(concatenated)
        }
        return path
    }
    
    lazy var gradientMaskNormal: UIImage? = {
        var sharedMask: UIImage?
        //create gradient mask
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 2048), true, 0.0)
        let gradientContext = UIGraphicsGetCurrentContext()
        let colors:[CGFloat] = [1.0, 1.0, 0, 1.0] // [1.0, 1.0, 1.0, 0.5] //
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let gradient = CGGradient(colorSpace: colorSpace, colorComponents: colors, locations: nil, count: 2)
        let gradientStartPoint = CGPoint(x: 0, y: 0)
        let gradientEndPoint = CGPoint(x: 0, y: 2048)
        if let gradientContext = gradientContext,
            let gradient = gradient {
            gradientContext.drawLinearGradient(gradient, start: gradientStartPoint,
                                               end: gradientEndPoint, options: .drawsAfterEndLocation)
            if let img = gradientContext.makeImage() {
                sharedMask = UIImage(cgImage: img)
            }
        }
        UIGraphicsEndImageContext()
        return sharedMask
    }()
    
    lazy var gradientMaskInvert: UIImage? = {
        var sharedMask: UIImage?
        //create gradient mask
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 2048), true, 0.0)
        let gradientContext = UIGraphicsGetCurrentContext()
        let colors:[CGFloat] = [0, 1.0, 1.0, 1.0] // [1.0, 1.0, 1.0, 0.5] //
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let gradient = CGGradient(colorSpace: colorSpace, colorComponents: colors, locations: nil, count: 2)
        let gradientStartPoint = CGPoint(x: 0, y: 0)
        let gradientEndPoint = CGPoint(x: 0, y: 2048)
        if let gradientContext = gradientContext,
            let gradient = gradient {
            gradientContext.drawLinearGradient(gradient, start: gradientStartPoint,
                                               end: gradientEndPoint, options: .drawsAfterEndLocation)
            if let img = gradientContext.makeImage() {
                sharedMask = UIImage(cgImage: img)
            }
        }
        UIGraphicsEndImageContext()
        return sharedMask
    }()
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if let ctx = UIGraphicsGetCurrentContext() {
            let calloutPath = calloutClipPath(with: calloutDirection,
                                              isFlipped: isFlipped)
            ctx.addPath(calloutPath.cgPath)
            ctx.clip()
            let fillAlpha: CGFloat = 0.5
            // fill the clip area
            fillColor.withAlphaComponent(fillAlpha).setFill()
            calloutPath.fill()
            
            if drawGlossEffect {
                ctx.addPath(calloutPath.cgPath)
                ctx.clip()
                let backgroundRect = calloutPath.cgPath.boundingBoxOfPath
                // let midCenter = CGPoint(x: backgroundRect.midX, y: backgroundRect.midY)
                let topCenter = CGPoint(x: backgroundRect.midX, y: 0.0)
                let bottomCenter = CGPoint(x: backgroundRect.midX, y: backgroundRect.size.height)
                ctx.beginTransparencyLayer(auxiliaryInfo: nil)
                drawShadowGradient(context: ctx,
                                   rect: backgroundRect,
                                   shadowColor: shadowGradientColor.complementaryColor,
                                   topCenter:  topCenter,
                                   bottomCenter: bottomCenter)
                
                ctx.addPath(calloutPath.cgPath)
                ctx.replacePathWithStrokedPath()
                ctx.clip(to: rect, mask: (gradientMask?.cgImage)!)
                drawShadowGradient(context: ctx,
                                   rect: backgroundRect,
                                   shadowColor: shadowGradientColor,
                                   topCenter: topCenter,
                                   bottomCenter: bottomCenter)
                ctx.endTransparencyLayer()
                
                // Gloss
                
                ctx.beginTransparencyLayer(auxiliaryInfo: nil)
                ctx.addPath(calloutPath.cgPath)
                ctx.clip()
                drawGlossy(context: ctx,
                           rect: backgroundRect,
                           startPoint: CGPoint(x: backgroundRect.minX, y: backgroundRect.minY),
                           endPoint: CGPoint(x: backgroundRect.maxX, y: backgroundRect.maxY))
                
                
                
                ctx.addPath(calloutPath.cgPath)
                ctx.clip(to: backgroundRect, mask: (gradientMask?.cgImage)!)
                drawGlossy(context: ctx,
                           rect: backgroundRect,
                           startPoint: CGPoint(x: backgroundRect.minX, y: backgroundRect.maxY),
                           endPoint: CGPoint(x: backgroundRect.minX, y: backgroundRect.maxY))
                ctx.endTransparencyLayer()
                
                
            } else {
                strokeColor.setStroke()
                calloutPath.lineWidth = lineWidth
                calloutPath.stroke()
            }
        }
    }
}
