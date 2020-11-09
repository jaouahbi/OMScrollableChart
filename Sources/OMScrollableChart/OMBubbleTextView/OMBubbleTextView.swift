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
        prespectiveShakeAnimation.fillMode = .forwards
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



