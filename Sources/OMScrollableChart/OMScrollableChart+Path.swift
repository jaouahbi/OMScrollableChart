//
//  OMScrollableChart+Path.swift
//  OMScrollableChart
//
//  Created by Jorge Ouahbi on 12/02/2021.
//

import UIKit
import LibControl

// MARK: - UIGestureRecognizerDelegate -
extension OMScrollableChart {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
        //        self.panGestureRecognizer.isEqual(otherGestureRecognizer)
    }
    //
//    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        if gestureRecognizer == contentPan {
//            if contentView == gestureRecognizer.view, self.zoomScale == 1 {
//                let v = contentPan.velocity(in: nil)
//                return v.y > abs(v.x)
//            }
//            return false
//        } else {
//            return self.pathNearPointsPanGesture.isEqual(gestureRecognizer)
//        }
//    }
    @objc public func pathNearPointsHandlePan(_ recognizer: UIPanGestureRecognizer) {
        guard ![.ended, .cancelled, .failed].contains(recognizer.state) else {
            lineShapeLayer.path = nil
            startPointShapeLayer.path = nil
            return
        }
        let location = recognizer.location(in: self)
        if let  closestPoint = bezier?.findClosestPointOnPath(fromPoint: location) {
            drawLine(fromPoint: location, toPoint: closestPoint)
        }
    }
    
    public var elementWidthPerSectionPerPage: Double {
        Double(sectionWidth) / Double(numberOfSectionsPerPage)
    }
    
    public var numberOfElements: Int {
        self.dataSource?.dataPoints(chart: self,
                                    renderIndex: RenderIdent.points.rawValue, section: 0).count ?? 0
    }
    
    public var elementsPerSectionPerPage: Double {
        Double(numberOfElements) / Double(numberOfSectionsPerPage)
    }
    
    public func makeBezierPathFromPolylinePath(with path: CGPath) -> Bool {
        bezier = BezierPathSegmenter(cgPath: path)
        bezier?.generateLookupTable()
        layoutBezierPath(path: path)
        return true
    }
    
    func polylineLayerBezierPathDidLoad(_ layer: CAShapeLayer) {
        if let path = layer.path {
            let regenerated = makeBezierPathFromPolylinePath(with: path)
            print("regenerated = \(regenerated) box: \(path.boundingBoxOfPath)")
        }
        
    }
    
    // MARK: - Drawing
    public func layoutBezierPath( path: CGPath) {
        
        //        print("""
        //
        //            [LAYOUT] pages \(numberOfPages)
        //                    elements \(numberOfElements)
        //                    element in section \(Double(numberOfSectionsPerPage * numberOfElements) * Double(1.0 / Double(numberOfElements))) %
        //                    sections \(numberOfSections)
        //                    section elements \(elementsPerSectionPerPage)
        //                    selection elements width: \(elementWidthPerSectionPerPage)
        //
        //                    contentOffset \(self.contentOffset)
        //                    contentSize \(self.contentSize)
        //                    bounds \(contentView.bounds) \(bounds)
        //            """)
        
        if path != bezier?.cgPath {
            let regenerated = makeBezierPathFromPolylinePath(with: path)
            print("regenerated = \(regenerated) box: \(path.boundingBoxOfPath)")
        }
        if showPolylineNearPoints {
            dotPathLayers.forEach{$0.removeFromSuperlayer()}
            dotPathLayers.removeAll()
            bezier?.lookupTable.forEach {
                drawDot(onLayer: self.contentView.layer,
                        atPoint: $0,
                        atSize: ScrollableRendersConfiguration.defaultPathPointSize,
                        color: UIColor.navyTwo.lighter,
                        alpha: 0.75)
            }
        }
        
    }

    
    public func addPrivateGestureRecognizer() {
        self.addGestureRecognizer(pathNearPointsPanGesture)
    }
    
    
    private func drawLine(fromPoint: CGPoint, toPoint: CGPoint, width: CGFloat = 6.0) {
        let path = UIBezierPath()
        path.move(to: fromPoint)
        path.addLine(to: toPoint)
        
        lineShapeLayer.path = path.cgPath
        
        let ovalPath = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: fromPoint.x - width * 0.5, y: fromPoint.y - width * 0.5), size: CGSize(width: width, height: width)))
        
        startPointShapeLayer.path = ovalPath.cgPath
    }
    
    @discardableResult
    private func drawDot(onLayer parentLayer: CALayer, atPoint point: CGPoint, atSize size: CGSize,  color: UIColor, alpha: CGFloat = 0.65) -> CAShapeLayer {
        let layer = ShapeRadialGradientLayer()
        let frame = CGRect(origin: CGPoint(x: point.x - size.width * 0.5, y: point.y - size.height * 0.5), size: size)
        let path = UIBezierPath(ovalIn: frame)
        layer.path = path.cgPath
        layer.lineWidth = 1.0
        layer.strokeColor = color.withAlphaComponent(alpha).cgColor
        layer.fillColor = UIColor.clear.cgColor
        parentLayer.addSublayer(layer)
        dotPathLayers.append(layer)
        return layer
    }
    
}

