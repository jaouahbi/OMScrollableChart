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

public protocol TooltipleableView where Self: UIView {
    func moveTooltip(_ position: CGPoint, duration: TimeInterval)
    func displayTooltip(_ position: CGPoint, duration: TimeInterval)
    func hideTooltip(_ position: CGPoint, duration: TimeInterval)
}

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
// MARK: - OMBubbleTextView -
@IBDesignable
class OMBubbleTextView: OMBubbleShapeView, TooltipleableView {
    
    //  text alignment.b j
    @IBInspectable var textAlignment: NSTextAlignment = .center {
        didSet {setNeedsDisplay()}
    }
    //  text color.
    @IBInspectable var textColor: UIColor = .black {
        didSet {setNeedsDisplay()}
    }
    // text font
    @IBInspectable var font: UIFont = UIFont.systemFont(ofSize: 10, weight: .thin) {
        didSet {setNeedsDisplay()}
    }
    // text
    @IBInspectable var string: String? {
        didSet {
            sizeToFit()
            setNeedsDisplay()
        }
    }
    @IBInspectable var boundInOneLine: Bool = false {
        didSet {
            sizeToFit()
            setNeedsDisplay()
        }
    }
    private var boundingSize: CGSize = .zero
    /// Called when a designable object is created in Interface Builder.
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        self.string = """
        
        The problem is that you are not resizing the layer when the size of the view changes, thus it remains at it's initial value, which mostly depends on how was the view created.
        
        I'd recommend using an UIView subclass, and updating the layer size in the layoutSubviews method, which always gets called when the view resizes:
        
        """
    }
    private var attributtedString: NSAttributedString? {
        if let text = string {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = textAlignment
            if !boundInOneLine {
                paragraphStyle.lineBreakMode = .byWordWrapping
            }
            return NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: font as Any,
                                                                 NSAttributedString.Key.paragraphStyle: paragraphStyle,
                                                                 NSAttributedString.Key.foregroundColor: textColor])
        }
        return nil
    }
    // Summary
    //
    // Asks the view to calculate and return the size that best fits the specified size.
    override func sizeThatFits( _ size: CGSize) -> CGSize {
        var result = super.sizeThatFits(size)
        if let attributtedString = attributtedString {
            
            let forceTextInOneLine = boundInOneLine ?
                CGSize(width: CGFloat.greatestFiniteMagnitude, height: font.lineHeight) :
                CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude)
            
            let boundingRect = attributtedString.boundingRect(with: forceTextInOneLine,
                                                              options: [.usesFontLeading,
                                                                        .usesLineFragmentOrigin,
                                                                        .truncatesLastVisibleLine],
                                                              context: nil)
            if !boundingRect.isEmpty {
                result = boundingRect.insetBy(dx: -5, dy: -4).size
                self.boundingSize = result
            }
            return result
        }
        
        return result
    }
    //
    /// Returns how much is the rect outside of the view, 0 if inside
    /// - Parameters:
    ///   - rect: CGRect
    ///   - inRect: CGRect
    /// - Returns: CGPoint
    private func rectViewOutsideOfSuperviewRect(rect: CGRect, inRect: CGRect) -> CGPoint {
        var offset = CGPoint.zero
        if inRect.contains(rect) {
            return .zero
        }
        if rect.origin.x < inRect.origin.x {
            // It's out to the left
            offset.x = inRect.origin.x - rect.origin.x
        } else if (rect.origin.x + rect.width) > (inRect.origin.x + inRect.width) {
            // It's out to the right
            offset.x = (rect.origin.x + rect.width) - (inRect.origin.x + inRect.width)
        }
        if rect.origin.y < inRect.origin.y {
            // It's out to the top
            offset.y = inRect.origin.y - rect.origin.y
        } else if rect.origin.y + rect.height > inRect.origin.y + inRect.height {
            // It's out to the bottom
            offset.y = (rect.origin.y + rect.height) - (inRect.origin.y + inRect.height)
        }
        return offset
    }
    // Show the view at the position animating it
    public func displayTooltip(_ position: CGPoint, duration: TimeInterval = 0.5) {
        UIView.animate(withDuration: duration,
                       delay: 0.1,
                       options: [.curveEaseOut], animations: {
                        self.alpha = 1.0
                        self.moveTooltip(position)
        }, completion: { finished in
        })
    }
    // Moving the tooltip fixing the superview intersections allowing to the user read the messaje.
    public func moveTooltip(_ position: CGPoint, duration: TimeInterval = 0.2) {
        var yCorrection: CGFloat = 0
        var xCorrection: CGFloat = 0
        var newPosition: CGPoint = .zero
        if let superview = self.superview {
            newPosition = CGPoint(x: position.x, y: position.y)
            let afterSetTheFrame = CGRect(origin: newPosition, size: self.frame.size)
            let resultAfterSet   = rectViewOutsideOfSuperviewRect(rect: afterSetTheFrame,
                                                                  inRect: superview.frame)
            // Correct the frame if it is out of a bounds of it superview
            if resultAfterSet.x > 0 || resultAfterSet.y > 0 {
                let yPosition = ((superview.frame.minY - frame.maxY) + bounds.height)
                let xPosition = ((superview.frame.minX - frame.maxX) + bounds.width)
                if yPosition > 0 {
                    yCorrection = yPosition + bounds.height
                }
                if xPosition > 0 {
                    xCorrection = xPosition + bounds.width
                }
                if resultAfterSet.y > 0 {
                    yCorrection = resultAfterSet.y
                }
                if resultAfterSet.x > 0 {
                    xCorrection = resultAfterSet.x
                }
                if self.frame.origin.x <= 0 {
                    xCorrection = -xCorrection
                }
                if self.frame.origin.y <= 0 {
                    yCorrection = -yCorrection
                }
            }
        }
        UIView.animate(withDuration: 0.6, animations: {
            let frame = CGRect( origin: CGPoint( x: newPosition.x - xCorrection ,
                                                 y: newPosition.y - yCorrection),
                                size: CGSize( width: self.bounds.size.width,
                                              height: self.bounds.size.height ))
            
            self.frame = frame
        }, completion: { finished in
        })
    }
    private func animateRotationAndPerspective( layer: CALayer,
                                                stepAngle: Double = 5.0) {
        var caTransform3DArray = [CATransform3D]()
        for rotationAngleIndex in 0..<4 {
            let rotationAngle = Double(rotationAngleIndex) * stepAngle * .pi / 180.0
            var rotationAndPerspectiveTransform = CATransform3DIdentity
            rotationAndPerspectiveTransform.m34 = 1.0 / -500
            rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform,
                                                                  CGFloat(rotationAngle),
                                                                  0.0,
                                                                  1.0,
                                                                  0.0)
            caTransform3DArray.append(rotationAndPerspectiveTransform)
        }
        caTransform3DArray.append(layer.transform)
        let prespectiveShakeAnimation = CAKeyframeAnimation(keyPath: "transform")
        prespectiveShakeAnimation.duration = 1
        prespectiveShakeAnimation.values = caTransform3DArray.map({NSValue(caTransform3D: $0)})
        prespectiveShakeAnimation.keyTimes = [0.0, 0.1, 0.3, 0.5, 1.0].map { NSNumber(value: $0) }
        prespectiveShakeAnimation.timingFunctions = [
            CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut),
            CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut),
            CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut),
            CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        ]
        prespectiveShakeAnimation.fillMode = CAMediaTimingFillMode.forwards
        prespectiveShakeAnimation.isRemovedOnCompletion = false
        prespectiveShakeAnimation.autoreverses  = true
        
        layer.add(prespectiveShakeAnimation, forKey: nil)
    }
    
    public func hideTooltip(_ location: CGPoint, duration: TimeInterval = 4.0) {
        UIView.animate(withDuration: duration,
                       delay: 0.1,
                       options: [.curveEaseIn],
                       animations: {
                        self.alpha = 0
        }, completion: { finished in
        })
        animateRotationAndPerspective(layer: self.layer)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if let ctx = UIGraphicsGetCurrentContext() {
            UIGraphicsPushContext(ctx)
            ctx.setAllowsFontSmoothing(true)
            ctx.setAllowsAntialiasing(false)
            ctx.beginTransparencyLayer(in: rect, auxiliaryInfo: nil)
            ctx.saveGState()
            defer { ctx.restoreGState() }
            if isFlipped {
                attributtedString?.draw(in: CGRect(origin: CGPoint(x: 0, y: 5), size: boundingSize))
            } else {
                let inRect = CGRect(origin: .zero, size: boundingSize)
                let originX = rect.origin.x + ((rect.size.width - inRect.size.width) * 0.5)
                let originY = rect.origin.y + ((rect.size.height - inRect.size.height) * 0.5)
                let drawRect = CGRect(x: originX, y: originY, width: inRect.size.width, height: inRect.size.height).integral
                attributtedString?.draw(in: drawRect)
            }
            ctx.endTransparencyLayer()
            UIGraphicsPopContext()
        }
    }
}


extension UIView {
    func keyFrameGrowAnimation(duration: CFTimeInterval) -> CAKeyframeAnimation {
        let boundsOvershootAnimation = CAKeyframeAnimation(keyPath: "transform")
        
        let startingScale   = CATransform3DScale(layer.transform, 0, 0, 0)
        let overshootScale  = CATransform3DScale(layer.transform, 1.2, 1.2, 1.0)
        let undershootScale = CATransform3DScale(layer.transform, 0.9, 0.9, 1.0)
        let endingScale     = layer.transform
        
        boundsOvershootAnimation.duration = duration
        
        boundsOvershootAnimation.values = [NSValue(caTransform3D: startingScale),
                                           NSValue(caTransform3D: overshootScale),
                                           NSValue(caTransform3D: undershootScale),
                                           NSValue(caTransform3D: endingScale)]
        
        boundsOvershootAnimation.keyTimes = [0.0, 0.5, 0.9, 1.0].map{ NSNumber(value: $0) }
        
        boundsOvershootAnimation.timingFunctions = [
            CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut),
            CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut),
            CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        ]
        
        boundsOvershootAnimation.fillMode = CAMediaTimingFillMode.forwards
        boundsOvershootAnimation.isRemovedOnCompletion = false
        return boundsOvershootAnimation
        
    }
    func grow(duration: CFTimeInterval) {
        self.layer.add(keyFrameGrowAnimation(duration: duration),
                       forKey: "keyFrameGrowAnimation")
    }
    public func shakeGrow(duration: CFTimeInterval) {
        let translation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        translation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        translation.values = [-5, 5, -5, 5, -3, 3, -2, 2, 0]
        
        let rotation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        rotation.values = [-5, 5, -5, 5, -3, 3, -2, 2, 0].map {
            ( degrees: Double) -> Double in
            let radians: Double = (Double.pi * degrees) / 180.0
            return radians
        }
        let shakeGroup: CAAnimationGroup = CAAnimationGroup()
        shakeGroup.animations = [keyFrameGrowAnimation(duration: duration),
                                 translation,
                                 rotation,
                                 translation,
                                 keyFrameGrowAnimation(duration: duration)]
        shakeGroup.duration = duration
        self.layer.add(shakeGroup, forKey: "shakeIt")
    }
}
