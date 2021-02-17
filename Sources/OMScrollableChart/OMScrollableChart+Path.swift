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
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !self.panGestureRecognizer.isEqual(gestureRecognizer)
    }
    @objc public func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard ![.ended, .cancelled, .failed].contains(recognizer.state) else {
            lineShapeLayer.path = nil
            startPointShapeLayer.path = nil
            return
        }
//        layoutBezierPath()
        let location = recognizer.location(in: contentView)
        if let  closestPoint = bezier?.findClosestPointOnPath(fromPoint: location) {
            drawLine(fromPoint: location, toPoint: closestPoint)
        }
    }
    
    public var elementWidthPerSectionPerPage: Double {
        Double(sectionWidth) / Double(numberOfSectionsPerPage)
    }

    public var numberOfElements: Int {
        self.dataSource?.dataPoints(chart: self,
                                    renderIndex: RenderIdentify.points.rawValue, section: 0).count ?? 0
    }
    
    public var elementsPerSectionPerPage: Double {
        Double(numberOfElements) / Double(numberOfSectionsPerPage)
    }
    
    public func makeBezierPathFromPolylinePath(with path: CGPath) -> Bool {
        bezier = OMBezierPath(cgPath: path)
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
        
        print("""

            [LAYOUT] pages \(numberOfPages)
                    elements \(numberOfElements)
                    element in section \(Double(numberOfSectionsPerPage * numberOfElements) * Double(1.0 / Double(numberOfElements))) %
                    sections \(numberOfSections)
                    section elements \(elementsPerSectionPerPage)
                    selection elements width: \(elementWidthPerSectionPerPage)

                    contentOffset \(self.contentOffset)
                    contentSize \(self.contentSize)
                    bounds \(contentView.bounds) \(bounds)
            """)

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
                             color: UIColor.black.lighter,
                             alpha: 0.75)
            }
        }
        
    }
    
//    func drawLine(fromPoint: CGPoint, toPoint: CGPoint) {
//        let path = UIBezierPath()
//        path.move(to: fromPoint)
//        path.addLine(to: toPoint)
//
//        lineShapeLayer.path = path.cgPath
//
//        let width: CGFloat = 6.0
//        let origin = CGPoint(x: fromPoint.x - width * 0.5, y: fromPoint.y - width * 0.5)
//        let rect = CGRect(origin: origin, size: CGSize(width: width, height: width))
//        let ovalPath = UIBezierPath(ovalIn: rect)
//
//        startPointShapeLayer.path = ovalPath.cgPath
//    }
//
//
//    @discardableResult
//    private func drawDotLines(onLayer parentLayer: CALayer,
//                              atPoint point: CGPoint,
//                              alpha: CGFloat = 0.85) -> ShapeRadialGradientLayer {
//        let layer = ShapeRadialGradientLayer()
//        let width: CGFloat = 4.0
//        let path = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: point.x - width * 0.5, y: point.y - width * 0.5), size: CGSize(width: width, height: width)))
//        layer.path = path.cgPath
//        layer.lineWidth = 1.0
//        layer.strokeColor = UIColor.crayolaNeonCarrotColor.withAlphaComponent(alpha).cgColor
//        layer.fillColor = UIColor.clear.cgColor
//        parentLayer.addSublayer(layer)
//
//        dotPathLayers.append(layer)
//        return layer
//    }
    
    
    public func addPanGestureRecognizer() {
        let recognzer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        contentView.addGestureRecognizer(recognzer)
    }



    // MARK: - Drawing
//    public func drawPath() {
//        guard let bezier = bezier else { return }
//
//        bezierPathLayer.path = bezier.cgPath
//        bezierPathLayer.strokeColor = UIColor.green.cgColor
//        bezierPathLayer.lineWidth = 2.0
//        bezierPathLayer.fillColor = UIColor.clear.cgColor
//
//        bezier.generateLookupTable()
//        for point in bezier.lookupTable {
//            drawDot(onLayer: bezierPathLayer, atPoint: point)
//        }
//    }
//

    private func drawLine(fromPoint: CGPoint, toPoint: CGPoint) {
        let path = UIBezierPath()
        path.move(to: fromPoint)
        path.addLine(to: toPoint)

        lineShapeLayer.path = path.cgPath

        let width: CGFloat = 6.0
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

