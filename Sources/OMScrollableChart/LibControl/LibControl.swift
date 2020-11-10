//
//  LibControl.swift
//
//  Created by Jorge Ouahbi on 24/09/2020.
//

import UIKit


//extension CGRect {
//    var topCenter: CGPoint { return CGPoint(x: self.midX, y: 0.0) }
//    var bottomCenter: CGPoint { return CGPoint(x: self.midX, y: self.size.height) }
//}



class LibControl {
    class func drawInnerShadow( ctx: CGContext,
                                bounds: CGRect,
                                shadowRadius: CGFloat,
                                shadowEdgeMask: UInt,
                                color: UIColor?) {
        ctx.clear(bounds);
        let rect = bounds.insetBy(dx:-4*shadowRadius, dy: -4*shadowRadius)
        ctx.addRect(rect);
        
        // Set up a path outside our bounds so the shadow will be cast into the bounds but no fill.  Push each edge out based on whether we want a shadow on that edge.  If we do,
        var interiorRect = bounds;
        let noShadowOutset = 2*shadowRadius;
        
        if ((shadowEdgeMask & (1<<CGRectEdge.minXEdge.rawValue)) == 0) {
            interiorRect.origin.x -= noShadowOutset;
            interiorRect.size.width += noShadowOutset;
        }
        if ((shadowEdgeMask & (1<<CGRectEdge.minYEdge.rawValue)) == 0) {
            interiorRect.origin.y -= noShadowOutset;
            interiorRect.size.height += noShadowOutset;
        }
        if ((shadowEdgeMask & (1<<CGRectEdge.maxXEdge.rawValue)) == 0) {
            interiorRect.size.width += noShadowOutset;
        }
        if ((shadowEdgeMask & (1<<CGRectEdge.maxYEdge.rawValue)) == 0) {
            interiorRect.size.height += noShadowOutset;
        }
        ctx.addRect(interiorRect)
        
        let defaultColor = UIColor(white: 0, alpha: 0.8)
        
        let shadowColor = color != nil ? color?.withAlphaComponent(0.8) ?? defaultColor : defaultColor
        
        ctx.setShadow(offset: CGSize(width: 0, height: 2),
                      blur: shadowRadius,
                      color: shadowColor.cgColor)
        
        ctx.setFillColor(gray: 0, alpha: 0.8)
        ctx.drawPath(using: .eoFill)
    }
    
    class func  createShadowImage( with size: CGSize,
                                   shadowRadius: CGFloat,
                                   shadowEdgeMask: UInt,
                                   color: UIColor?) -> CGImage?
    {
        assert(size.width >= 1);
        assert(size.height >= 1);
        let componentCount: CGFloat = 4;
        let alphaInfo: CGImageAlphaInfo = .premultipliedFirst;
        let pixelsWide = ceil(size.width);
        let pixelsHigh = ceil(size.height);
        let bytesPerRow = componentCount * pixelsWide; // alpha
        // We can cast directly from CGImageAlphaInfo to CGBitmapInfo because the first component in the latter is an alpha info mask
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil,
                                  width: Int(pixelsWide),
                                  height: Int(pixelsHigh),
                                  bitsPerComponent: 8,
                                  bytesPerRow: Int(bytesPerRow),
                                  space: colorSpace,
                                  bitmapInfo: alphaInfo.rawValue) else {
                                    return nil;
                                    
        }
        let bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height);
        drawInnerShadow(ctx: ctx, bounds: bounds, shadowRadius: shadowRadius, shadowEdgeMask: shadowEdgeMask, color: color);
        ctx.flush()
        let shadowImage = ctx.makeImage()
        return shadowImage;
    }
}

extension UIView {
    func adjustLayoutToSuperview( trailing: CGFloat = 0,
                                  leading: CGFloat = 0,
                                  botton: CGFloat = 0,
                                  top: CGFloat = 0) {
        guard let superview = superview else {
            print("The view must has a superview.")
            return
        }
        self.translatesAutoresizingMaskIntoConstraints = false
        let trailingAnchor = superview.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: trailing)
        let leadingAnchor = superview.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: leading)
        let topAnchor = superview.topAnchor.constraint(equalTo: self.topAnchor, constant: top)
        let bottomAnchor = superview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: botton)
        NSLayoutConstraint.activate([trailingAnchor, leadingAnchor, topAnchor, bottomAnchor])
        
    }
    
    func adjustLeftRightLayoutToSuperview( left: CGFloat = 0, right: CGFloat = 0) {
        guard let superview = superview else {
            print("The view must has a superview.")
            return
        }
        self.translatesAutoresizingMaskIntoConstraints = false
        superview.leftAnchor.constraint(equalTo: self.leftAnchor, constant: left).isActive = true
        superview.rightAnchor.constraint(equalTo: self.rightAnchor, constant: right).isActive = true
        
    }
    
    /// fixedAnchorSize
    /// - Parameters:
    ///   - width: GCFloat
    ///   - height: GCFloat
    func fixedAnchorSize(width: CGFloat = 0, height: CGFloat = 0) {
        self.translatesAutoresizingMaskIntoConstraints = false
        if height != 0 {
            self.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        if width != 0 {
            self.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
    }
    /// Center
    func centerXY() {
        self.translatesAutoresizingMaskIntoConstraints = false
        guard let superview = self.superview else { return  }
        self.centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
        self.centerYAnchor.constraint(equalTo: superview.centerYAnchor).isActive = true
    }
    func centerX() {
        self.translatesAutoresizingMaskIntoConstraints = false
        guard let superview = self.superview else { return  }
        self.centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
    }
    func centerY() {
        self.translatesAutoresizingMaskIntoConstraints = false
        guard let superview = self.superview else { return  }
        self.centerYAnchor.constraint(equalTo: superview.centerYAnchor).isActive = true
    }
}


/*
 let layer = CAShapeLayer()
 
 // Setup layer...
 
 // Gradient Direction: →
 let gradientLayer1 = layer.applyGradient(of: UIColor.yellow, UIColor.red, at: 0)
 
 // Gradient Direction: ↗︎
 let gradientLayer2 = layer.applyGradient(of: UIColor.purple, UIColor.yellow, UIColor.green, at: -45)
 
 // Gradient Direction: ←
 let gradientLayer3 = layer.applyGradient(of: UIColor.yellow, UIColor.blue, UIColor.green, at: 180)
 
 // Gradient Direction: ↓
 let gradientLayer4 = layer.applyGradient(of: UIColor.red, UIColor.blue, at: 450)
 Mathematical Explanation
 
 So I actually just recently spent a lot of time trying to answer this myself. Here are some example angles just to help understand and visualize the clockwise direction of rotation.
 
 Example Angles
 
 If you are interested in how I figured it out, I made a table to visualize essentially what I am doing from 0° - 360°.
 
 Table
 share  improve this answer   follow
 answered Jan 26 '19 at 0:20
 
 Noah Wilder
 
 https://stackoverflow.com/questions/41019686/how-to-fill-a-cashapelayer-with-an-angled-gradient
 */

public extension CALayer {
    func applyGradient(of colors: UIColor..., atAngle angle: CGFloat) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = frame
        gradientLayer.colors = colors
        gradientLayer.calculatePoints(for: angle)
        self.addSublayer(gradientLayer)
        return gradientLayer
    }
}

extension UIImage {
    func blend(with topImage: UIImage,
               blendMode: CGBlendMode = .normal, alpha: CGFloat = 0.5) -> UIImage {
        let bottomImage = self
        
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        
        let areaSize = CGRect(x: 0, y: 0, width: bottomImage.size.width, height: bottomImage.size.height)
        bottomImage.draw(in: areaSize, blendMode: .normal, alpha: alpha)
        topImage.draw(in: areaSize,
                      blendMode: blendMode,
                      alpha: alpha)
        let mergedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return mergedImage
    }
}

//class OMGlossLayer: CALayer {
//    private let reflectEffectGradient = CGGradient(colorSpace: CGColorSpaceCreateDeviceRGB(),
//                                                   colorComponents: [ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0], locations: nil, count: 2)!
//    private let glassEffectGradient   = CGGradient(colorSpace: CGColorSpaceCreateDeviceRGB(),
//                                                   colorComponents: [1.0, 1.0, 1.0, 0.2, 1.0, 1.0, 1.0, 0.0], locations: nil, count: 2)!
//    private var lowerCircleRadius:CGFloat = 0
//    private var lowerCircleCenterPoint:CGPoint = CGPoint.zero
//    private var lowerChordLeftPoint:CGPoint  = CGPoint.zero
//    private var lowerChordRightPoint:CGPoint = CGPoint.zero
//    
//    
//    private var upperCircleRadius:CGFloat = 0
//    private var upperRectGlassCenterPoint:CGPoint = CGPoint.zero
//    private var upperChordLeftPoint:CGPoint = CGPoint.zero
//    private var upperChordRightPoint:CGPoint = CGPoint.zero
//    
//    /// Glass effect
//    private var rectGlassLeft:CGRect  = CGRect.zero;
//    private var rectGlassRight:CGRect = CGRect.zero;
//
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
//    /// Set glass effect
//    public var glassEffect:Bool = true {
//        didSet {
//            setNeedsLayout()
//        }
//    }
//    
//    /// Draw glass effect
//    ///
//    /// - Parameter context: current context
//    
//    fileprivate func drawGlassEffect(context: CGContext,
//                                     glassEffectGradient: CGGradient,
//                                     rectGlassLeft: CGRect,
//                                     rectGlassRight: CGRect ) {
//        
//        let options  = CGGradientDrawingOptions(rawValue: 0)
//        let endPointLeft = CGPoint(x:bounds.midX ,y: upperChordLeftPoint.y)
//        let endPointRight = CGPoint(x:bounds.midX ,y: upperChordRightPoint.y)
//        
//        // left glass effect
//        //context.setStrokeColor(UIColor.white.cgColor)
//        context.addRect(rectGlassLeft)
//        context.closePath()
//        context.saveGState()
//        //context.strokePath()
//        context.clip()
//        context.drawLinearGradient(glassEffectGradient,
//                                   start: upperChordLeftPoint,
//                                   end: endPointLeft,
//                                   options: options)
//        context.restoreGState()
//        
//        // right glass effect
//        context.addRect(rectGlassRight)
//        context.closePath()
//        
//        context.saveGState()
//        //context.strokePath()
//        context.clip()
//        context.drawLinearGradient(glassEffectGradient,
//                                   start: upperChordRightPoint,
//                                   end: endPointRight,
//                                   options: options)
//        context.restoreGState()
//    }
//    
//    override public func draw(in ctx: CGContext) {
//        super.draw(in: ctx)
//        if self.isHidden {
//            // Nothing to do.
//            return
//        }
//        //ctx.clear(ctx.boundingBoxOfClipPath)
//        // Draw the glass effect.
//        if glassEffect {
//            drawGlassEffect(context: ctx,
//                            glassEffectGradient: glassEffectGradient,
//                            rectGlassLeft: rectGlassLeft,
//                            rectGlassRight: rectGlassRight)
//        }
//    }
//    
//    override func layoutSublayers() {
//        super.layoutSublayers()
//        
//        let layerBounds        = self.bounds
//        lowerCircleRadius      = layerBounds.height / 8
//        lowerCircleCenterPoint = CGPoint(x:layerBounds.midX, y: layerBounds.height - lowerCircleRadius)
//        lowerChordLeftPoint    = CGPoint(x:(lowerCircleCenterPoint.x - CGFloat(cos(.pi / 4.0)) * lowerCircleRadius),
//                                         y:(lowerCircleCenterPoint.y - CGFloat(sin(.pi / 4.0)) * lowerCircleRadius))
//        lowerChordRightPoint   = CGPoint(x:(lowerCircleCenterPoint.x + CGFloat(cos(.pi / 4.0)) * lowerCircleRadius),
//                                         y:(lowerCircleCenterPoint.y - CGFloat(sin(.pi / 4.0)) * lowerCircleRadius))
//        upperCircleRadius         = (lowerChordRightPoint.x - lowerChordLeftPoint.x) * 0.5
//        upperRectGlassCenterPoint = CGPoint(x:layerBounds.midX, y:upperCircleRadius)
//        upperChordLeftPoint       = CGPoint(x:lowerChordLeftPoint.x, y:upperRectGlassCenterPoint.y)
//        upperChordRightPoint      = CGPoint(x:lowerChordRightPoint.x,y:upperRectGlassCenterPoint.y)
//        rectGlassLeft             = CGRect(x:upperChordLeftPoint.x, y:layerBounds.minY,
//                                           width:upperRectGlassCenterPoint.x - upperChordLeftPoint.x, height:layerBounds.height)
//        rectGlassRight            = CGRect(x:upperRectGlassCenterPoint.x,y:layerBounds.minY,
//                                           width:upperChordRightPoint.x - upperRectGlassCenterPoint.x, height:layerBounds.height)
//        
//        setNeedsDisplay()
//    }
//}


extension CGRect {
    init(p1: CGPoint, p2: CGPoint) {
        self.init(x: Swift.min(p1.x, p2.x),
                  y: Swift.min(p1.y, p2.y),
                  width: abs(p1.x - p2.x),
                  height: abs(p1.y - p2.y))
    }
}

extension UIView {
    func addBackgroundShadow(size: CGSize,
                             color: UIColor,
                             shadowRadius: CGFloat,
                             shadowEdgeMask: UInt)  {
        
        if let shadowImage = LibControl.createShadowImage(with: size,
                                                               shadowRadius: shadowRadius,
                                                               shadowEdgeMask: shadowEdgeMask,
                                                               color: color) {
            
            self.backgroundColor = UIColor(patternImage: UIImage(cgImage: shadowImage))
        }
    }
}



//extension CGPoint {
//    func projectLine( _ point:CGPoint, length:CGFloat) -> CGPoint  {
//        var newPoint = CGPoint(x: point.x, y: point.y)
//        let originX = (point.x - self.x);
//        let originY = (point.y - self.y);
//        if (originX.floatingPointClass == .negativeZero) {
//            newPoint.y += length;
//        } else if (originY.floatingPointClass == .negativeZero) {
//            newPoint.x += length;
//        } else {
//            #if CGFLOAT_IS_DOUBLE
//            let angle = atan(y / x);
//            
//            if (angle.floatingPointClass == .quietNaN) {
//                newPoint.y += length;
//                newPoint.x += length;
//            } else {
//                newPoint.x += sin(angle) * length;
//                newPoint.y += cos(angle) * length;
//            }
//            #else
//            let angle = atanf(Float(originY) / Float(originX));
//            
//            if (angle.floatingPointClass == .quietNaN) {
//                newPoint.y += length;
//                newPoint.x += length;
//            } else {
//                newPoint.x += CGFloat(sinf(angle) * Float(length));
//                newPoint.y += CGFloat(cosf(angle) * Float(length));
//            }
//            #endif
//        }
//        return newPoint;
//    }
//}
//
//extension  CGContext {
//    /// projectLineStrokeGradient
//    /// - Parameters:
//    ///   - internalPoints: [CGPoints]]
//    ///   - ctx: CGContext
//    ///   - gradient: CGGradient
//    func projectLineStrokeGradient(_ gradient: CGGradient, bounds: CGRect,
//                                   internalPoints: [CGPoint],
//                                   lineWidth: CGFloat) {
//        self.saveGState()
//        for index in 0..<internalPoints.count - 1  {
//            var start: CGPoint = internalPoints[index]
//            // The ending point of the axis, in the shading's target coordinate space.
//            var end: CGPoint  = internalPoints[index+1]
//            // Draw the gradient in the clipped region
//            let hw = lineWidth * 0.5
//            start  = end.projectLine(start, length: hw)
//            end    = start.projectLine(end, length: -hw)
//            self.scaleBy(x: bounds.size.width,
//                         y: bounds.size.height )
//            self.drawLinearGradient(gradient,
//                                    start: start,
//                                    end: end,
//                                    options: [])
//        }
//        self.restoreGState()
//    }
//}
//extension CGContext {
//    func strokeGradient( path: CGPath,
//                         points: [CGPoint]?,
//                         color: UIColor,
//                         lineWidth: CGFloat,
//                         fadeFactor: CGFloat = 0.4)  {
//        let locations =  [0, fadeFactor, 1 - fadeFactor, 1]
//        let gradient = CGGradient(colorsSpace: nil,
//                                  colors: [UIColor.white.withAlphaComponent(0.1).cgColor,
//                                           color.cgColor,
//                                           color.withAlphaComponent(fadeFactor).cgColor ,
//                                           UIColor.white.withAlphaComponent(0.8).cgColor] as CFArray,
//                                  locations: locations )!
//        // Clip to the path, stroke and enjoy.
//      
//        self.setStrokeColor(color.cgColor)
//        //color.setStroke()
//        let curPath = UIBezierPath(cgPath: path)
//        self.setLineWidth(lineWidth)
//        //curPath.lineWidth = lineWidth
//        self.addPath(path)
//        self.replacePathWithStrokedPath()
//        self.clip()
//        //curPath.stroke()
//        //curPath.addClip()
//        //self.addPath(path)
//
//        //self.clip()
//            // if we are using the stroke, we offset the from and to points
//            // by half the stroke width away from the center of the stroke.
//            // Otherwise we tend to end up with fills that only cover half of the
//            // because users set the start and end points based on the center
//            // of the stroke.
//            if let internalPoints = points {
//                projectLineStrokeGradient( gradient,
//                                           bounds: self.boundingBoxOfClipPath,
//                                           internalPoints: internalPoints,
//                                           lineWidth: lineWidth)
//            }
//        }
//}

extension CGContext {

class func contextGray(_ pixelsWide: Int, _ pixelsHigh: Int) -> CGContext? {
    
    // gradient is always black-white and the mask must be in the gray colorspace
    let colorSpace = CGColorSpaceCreateDeviceGray()
    
    // create the bitmap context
    let bitmapContext = CGContext(data: nil, width: pixelsWide, height: pixelsHigh,
                                  bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
    
    return bitmapContext
}

class func contextBGRA(_ pixelsWide: Int, _ pixelsHigh: Int) -> CGContext? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    // create the bitmap context
    let bitmapContext = CGContext(data: nil,
                                  width: pixelsWide,
                                  height: pixelsHigh,
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,       // let it calculate
        space: colorSpace,
        // this will give us an optimal BGRA format for the device:
        bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
    
    return bitmapContext
}
}

////MARK: - Image Reflection
//extension CGImage {
//    class func gradientMask(_ pixelsWide: Int, _ pixelsHigh: Int) -> CGImage? {
//
//        // gradient is always black-white and the mask must be in the gray colorspace
//        let colorSpace = CGColorSpaceCreateDeviceGray()
//
//        // create the bitmap context
//        let gradientBitmapContext = CGContext.contextGray(pixelsWide, pixelsHigh)
//
//        // define the start and end grayscale values (with the alpha, even though
//        // our bitmap context doesn't support alpha the gradient requires it)
//        let colors: [CGFloat] = [0.0, 1.0, 1.0, 1.0]
//
//        // create the CGGradient and then release the gray color space
//        let grayScaleGradient = CGGradient(colorSpace: colorSpace, colorComponents: colors, locations: nil, count: 2)
//
//        // create the start and end points for the gradient vector (straight down)
//        let gradientStartPoint = CGPoint.zero
//        let gradientEndPoint = CGPoint(x: 0, y: CGFloat(pixelsHigh))
//
//        // draw the gradient into the gray bitmap context
//        gradientBitmapContext?.drawLinearGradient(grayScaleGradient!, start: gradientStartPoint,
//                                                  end: gradientEndPoint,  options: .drawsAfterEndLocation)
//
//        // convert the context into a CGImageRef and release the context
//        // return the imageref containing the gradient
//        return gradientBitmapContext?.makeImage()
//    }
//}

//extension CALayer {
//    func reflectedLayer( withHeight height: NSInteger) {
//        guard height > 0 else {
//            return
//        }
//        // create a bitmap graphics context the size of the image
//        let offscreenContext = CGContext.contextBGRA(Int(self.bounds.size.width), height)
//        // draw the image into the bitmap context
//        if let ctx = offscreenContext {
//            self.render(in: ctx)
//            // create a 2 bit CGImage containing a gradient that will be used for masking the
//            // main view content to create the 'fade' of the reflection.  The CGImageCreateWithMask
//            // function will stretch the bitmap image as required, so we can create a 1 pixel wide gradient
//            let gradientMaskImage = CGImage.gradientMask(1, height)
//            // create an image by masking the bitmap of the mainView content with the gradient view
//            // then release the  pre-masked content bitmap and the gradient bitmap
//            ctx.clip(to: CGRect(x: 0.0, y: 0.0, width: self.bounds.size.width, height: CGFloat(height)),
//                     mask: gradientMaskImage!)
//            // In order to grab the part of the image that we want to render, we move the context origin to the
//            // height of the image that we want to capture, then we flip the context so that the image draws upside down.
//            ctx.translateBy(x: 0.0, y: CGFloat(height))
//            ctx.scaleBy(x: 1.0, y: -1.0)
//            self.contents = ctx.makeImage()
//        }
//    }
//    func imageReflectedLayer( withHeight height: NSInteger) -> CGImage? {
//        guard height > 0 else {
//            return nil
//        }
//        // create a bitmap graphics context the size of the image
//        let offscreenContext = CGContext.contextBGRA(Int(self.bounds.size.width), height)
//        // draw the image into the bitmap context
//        if let ctx = offscreenContext {
//            self.render(in: ctx)
//            // create a 2 bit CGImage containing a gradient that will be used for masking the
//            // main view content to create the 'fade' of the reflection.  The CGImageCreateWithMask
//            // function will stretch the bitmap image as required, so we can create a 1 pixel wide gradient
//            let gradientMaskImage = CGImage.gradientMask(1, height)
//            // create an image by masking the bitmap of the mainView content with the gradient view
//            // then release the  pre-masked content bitmap and the gradient bitmap
//            ctx.clip(to: CGRect(x: 0.0, y: 0.0, width: self.bounds.size.width, height: CGFloat(height)),
//                     mask: gradientMaskImage!)
//            // In order to grab the part of the image that we want to render, we move the context origin to the
//            // height of the image that we want to capture, then we flip the context so that the image draws upside down.
//            ctx.translateBy(x: 0.0, y: CGFloat(height))
//            ctx.scaleBy(x: 1.0, y: -1.0)
//            return ctx.makeImage()
//        }
//        return nil
//    }
//}
//
//class CALayerReflected: CALayer {
//    override init() {
//        super.init()
//        defaultInitializer()
//    }
//    override init(layer: Any) {
//        super.init(layer: layer)
//        defaultInitializer()
//    }
//    func defaultInitializer() {
//        let scale = UIScreen.main.scale
//        contentsScale = scale
//        needsDisplayOnBoundsChange = true
//        drawsAsynchronously = true
//        allowsGroupOpacity = true
//        shouldRasterize = true
//        rasterizationScale = scale
//    }
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        defaultInitializer()
//    }
//    var reflectionPercent: CGFloat = 0.2
//
//    override func draw(in ctx: CGContext) {
//        super.draw(in: ctx)
//        let height = self.bounds.size.height * reflectionPercent
//        guard height > 0 else {
//            return
//        }
//        // create a bitmap graphics context the size of the image
//        let mainViewContentContext =  CGContext.contextBGRA(Int(self.bounds.size.width), Int(height))
//
//        // create a 2 bit CGImage containing a gradient that will be used for masking the
//        // main view content to create the 'fade' of the reflection.  The CGImageCreateWithMask
//        // function will stretch the bitmap image as required, so we can create a 1 pixel wide gradient
//        let gradientMaskImage = CGImage.gradientMask(1, Int(height))
//
//        // create an image by masking the bitmap of the mainView content with the gradient view
//        // then release the  pre-masked content bitmap and the gradient bitmap
//        mainViewContentContext?.clip(to: CGRect(x: 0.0, y: 0.0, width: self.bounds.size.width, height: CGFloat(height)), mask: gradientMaskImage!)
//        ctx.clip(to: CGRect(x: 0.0, y: 0.0, width: self.bounds.size.width, height: CGFloat(height)), mask: gradientMaskImage!)
//
//        // In order to grab the part of the image that we want to render, we move the context origin to the
//        // height of the image that we want to capture, then we flip the context so that the image draws upside down.
//        mainViewContentContext?.translateBy(x: 0.0, y: CGFloat(height))
//        mainViewContentContext?.scaleBy(x: 1.0, y: -1.0)
//
//
//        ctx.translateBy(x: 0.0, y: CGFloat(height))
//        ctx.scaleBy(x: 1.0, y: -1.0)
//
//
//
//        if let img = ctx.makeImage() {
//            let image = UIImage(cgImage: img)
//            print(image)
//
//            mainViewContentContext?.draw(img, in: self.bounds)
//            if let img = mainViewContentContext?.makeImage() {
//                let image = UIImage(cgImage: img)
//                print(image)
//            }
//        }
//    }
//}


extension CALayer {
    
    // Combine the original and new mask into one.
    
    func appendMask( clipPath: UIBezierPath) {
        
        // Create new path and mask
        let newMask = CAShapeLayer()
        let newPath = clipPath
        
        // Create path to clip
        let newClipPath = UIBezierPath(rect: self.bounds)
        newClipPath.append(newPath)
        
        // If view already has a mask
        if let originalMask = self.mask,
            let originalShape = originalMask as? CAShapeLayer,
            let originalPath = originalShape.path {
            
            // Create bezierpath from original mask's path
            let originalBezierPath = UIBezierPath(cgPath: originalPath)
            
            // Append view's bounds to "reset" the mask path before we re-apply the original
            newClipPath.append(UIBezierPath(rect: self.bounds))
            
            // Combine new and original paths
            newClipPath.append(originalBezierPath)
        }
        
        // Apply new mask
        newMask.path = newClipPath.cgPath
        newMask.fillRule = CAShapeLayerFillRule.evenOdd
        self.mask = newMask
    }
    
    var image: CGImage? {
        let ctx = self.context
        if let ctx = ctx {
            render(in: ctx)
            return ctx.makeImage()
        } else {
            return nil
        }
    }
    
    var context: CGContext? {
        let width = Int(frame.size.width)
        let height = Int(frame.size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let rawData = malloc(height * bytesPerRow)
        let bitsPerComponent = 8
        guard let context = CGContext(data: rawData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else {
                                        return nil
        }
        // Before you render the layer check if the layer turned over.
        if contentsAreFlipped() {
            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: frame.size.height)
            context.concatenate(flipVertical)
        }
        return context
    }
}


//
//// Layer with clip path
//class OMShapeLayerClipPath: CAShapeLayer {
//    override init() {
//        super.init()
//        defaultInitializer()
//    }
//    override init(layer: Any) {
//        super.init(layer: layer)
//        defaultInitializer()
//    }
//    func defaultInitializer() {
//        let scale = UIScreen.main.scale
//        contentsScale = scale
//        needsDisplayOnBoundsChange = true
//        drawsAsynchronously = true
//        allowsGroupOpacity = true
//        shouldRasterize = true
//        rasterizationScale = scale
//    }
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        defaultInitializer()
//    }
//    func addPathAndClipIfNeeded(ctx: CGContext) {
//        if let path = self.path {
//            ctx.addPath(path)
//            if self.strokeColor != nil {
//                ctx.setLineWidth(self.lineWidth)
//                ctx.replacePathWithStrokedPath()
//            }
//            ctx.clip()
//        }
//    }
//    override public func draw(in ctx: CGContext) {
//        super.draw(in: ctx)
//
//        let cgImg = self.image
//         if let cgImg = cgImg {
//             let image = UIImage(cgImage: cgImg)
//             print(image)
//         }
//
//        addPathAndClipIfNeeded(ctx: ctx)
//
//        let cgImg2 = self.image
//        if let cgImg = cgImg2 {
//            let image = UIImage(cgImage: cgImg)
//            print(image)
//        }
//    }
//    override public func render(in ctx: CGContext) {
//        super.render(in: ctx)
//        addPathAndClipIfNeeded(ctx: ctx)
//    }
//}
//// Shape layer with clip path and gradient friendly
//class OMGradientShapeClipLayer: OMShapeLayerClipPath {
//
//    // Some predefined Gradients
//    var gardientColor: UIColor = .clear
//    public lazy var insetGradient: GradientColors =  {
//        return  (UIColor(red:0 / 255.0, green:0 / 255.0,blue: 0 / 255.0,alpha: 0 ),
//                 UIColor(red: 0 / 255.0, green:0 / 255.0,blue: 0 / 255.0,alpha: 0.2 ))
//    }()
//    public lazy var shineGradient: GradientColors =  {
//        return  (UIColor(red:1, green:1,blue: 1,alpha: 0 ),
//                 UIColor(red:1, green:1,blue:1,alpha: 0.8 ))
//    }()
//    public lazy var shadowGradient: GradientColors =  {
//        return  (UIColor(red:0, green:0,blue: 0,alpha: 0 ),
//                 UIColor(red:0, green:0,blue: 0,alpha: 0.6 ))
//    }()
//    public lazy var shadeGradient: GradientColors =  {
//        return  (UIColor(red: 252 / 255.0, green: 252 / 255.0,blue: 252 / 255.0,alpha: 0.65 ),
//                 UIColor(red:  178 / 255.0, green:178 / 255.0,blue: 178 / 255.0,alpha: 0.65 ))
//    }()
//    public lazy var convexGradient: GradientColors =  {
//        return  (UIColor(red:1,green:1,blue:1,alpha: 0.43 ),
//                 UIColor(red:1,green:1,blue:1,alpha: 0.5 ))
//    }()
//    public lazy var concaveGradient: GradientColors =  {
//        return  (UIColor(red:1.0,green:1,blue:1,alpha: 0.0 ),
//                 UIColor(red:1,green:1,blue:1,alpha: 0.46 ))
//    }()
//    public lazy var glossGradient: GradientColors =  {
//        return  (UIColor(red:1.0,green:1.0,blue:1.0,alpha: 0.35 ),
//                 UIColor(red:1.0,green:1.0,blue:1.0,alpha: 0.6 ))
//
//    }()
//}

public extension CAGradientLayer {
    
    /// Sets the start and end points on a gradient layer for a given angle.
    ///
    /// - Important:
    /// *0°* is a horizontal gradient from left to right.
    ///
    /// With a positive input, the rotational direction is clockwise.
    ///
    ///    * An input of *400°* will have the same output as an input of *40°*
    ///
    /// With a negative input, the rotational direction is clockwise.
    ///
    ///    * An input of *-15°* will have the same output as *345°*
    ///
    /// - Parameters:
    ///     - angle: The angle of the gradient.
    ///
    func calculatePoints(for angle: CGFloat) {
        
        
        var ang = (-angle).truncatingRemainder(dividingBy: 360)
        
        if ang < 0 { ang = 360 + ang }
        
        let n: CGFloat = 0.5
        
        let tanx: (CGFloat) -> CGFloat = { tan($0 * CGFloat.pi / 180) }
        
        switch ang {
            
        case 0...45, 315...360:
            let a = CGPoint(x: 0, y: n * tanx(ang) + n)
            let b = CGPoint(x: 1, y: n * tanx(-ang) + n)
            startPoint = a
            endPoint = b
            
        case 45...135:
            let a = CGPoint(x: n * tanx(ang - 90) + n, y: 1)
            let b = CGPoint(x: n * tanx(-ang - 90) + n, y: 0)
            startPoint = a
            endPoint = b
            
        case 135...225:
            let a = CGPoint(x: 1, y: n * tanx(-ang) + n)
            let b = CGPoint(x: 0, y: n * tanx(ang) + n)
            startPoint = a
            endPoint = b
            
        case 225...315:
            let a = CGPoint(x: n * tanx(-ang - 90) + n, y: 0)
            let b = CGPoint(x: n * tanx(ang - 90) + n, y: 1)
            startPoint = a
            endPoint = b
            
        default:
            let a = CGPoint(x: 0, y: n)
            let b = CGPoint(x: 1, y: n)
            startPoint = a
            endPoint = b
            
        }
    }
}

extension CGGradient {
    func verticalImage(
        height: size_t,
        opaque: Bool,
        flip: Bool,
        colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()) -> CGImage?
    {
        let width: size_t = 1;
        var componentCount: size_t  = colorSpace.numberOfComponents;
        var alphaInfo: CGImageAlphaInfo
        var gradientColorSpace = colorSpace
        if (opaque) {
            alphaInfo = CGImageAlphaInfo.none;
        } else {
            // gray+alpha isn't supported, but alpha-only is (seem to be {black,alpha}). Unclear if you can make it {white,alpha} or any generic color).  Sadly, at least in some cases alpha-only seems to have some weird issues (see OQHoleLayer). So, upsample to RGBA.
            
            gradientColorSpace = CGColorSpaceCreateDeviceRGB()
            componentCount = 4;
            alphaInfo = CGImageAlphaInfo.premultipliedFirst;
        }
        
        // We can cast directly from CGImageAlphaInfo to CGBitmapInfo because the first component in the latter is an alpha info mask
        let bytesPerRow = componentCount * width;
        
        guard let ctx = CGContext(data: nil,
                                  width: Int(width),
                                  height: Int(height),
                                  bitsPerComponent: 8,
                                  bytesPerRow: Int(bytesPerRow),
                                  space: gradientColorSpace,
                                  bitmapInfo: alphaInfo.rawValue) else {
                                    return nil;
                                    
        }
        
        let bounds = CGRect(x: 0, y: 0, width: width, height: height);
        ctx.addRect(bounds);
        ctx.clip();
        
        var startPoint = bounds.origin;
        var endPoint   = CGPoint(x: bounds.minX, y: bounds.maxY)
        
        if (flip) {
            let temp = startPoint
            startPoint = endPoint
            endPoint = temp
        }
        ctx.drawLinearGradient(self, start: startPoint, end: endPoint, options: []);
        ctx.flush();
        return  ctx.makeImage();
    }
    func verticalGray( minGray: CGFloat, maxGray: CGFloat) -> CGGradient? {
        let minGrayColorRef = UIColor(white: minGray, alpha: 1.0);
        let maxGrayColorRef = UIColor(white: maxGray, alpha: 1.0)
        let colorSpace = CGColorSpaceCreateDeviceGray();
        let gradient = CGGradient(colorsSpace: colorSpace, colors: [minGrayColorRef, maxGrayColorRef] as CFArray, locations: nil)
        return gradient
    }
}

extension CGAffineTransform {
    func shear(_ xShear: CGFloat, yShear: CGFloat) -> CGAffineTransform {
        var transform = self
        transform.c = -xShear
        transform.b = yShear
        return transform
    }
    static func shearX(_ xShear: CGFloat = 0.3) -> CGAffineTransform  {
        return CGAffineTransform(a: 1, b: 0, c: xShear, d: 1, tx: 0, ty: 0)
    }
    static func shearY(_ yShear: CGFloat = 0.3) -> CGAffineTransform  {
        return CGAffineTransform(a: 1, b: yShear, c: 0, d: 1, tx: 0, ty: 0)
    }
    static func shear( xShear: CGFloat,  yShear: CGFloat) -> CGAffineTransform {
        return CGAffineTransform(a: 1, b: yShear, c: xShear, d: 1, tx: 0, ty: 0);
    }
}
