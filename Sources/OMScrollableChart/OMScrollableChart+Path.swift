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
    }
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if isAllowedPathDebug {
            return true
        }
        return false
    }
    @objc public func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard ![.ended, .cancelled, .failed].contains(recognizer.state) else {
            if isAllowedPathDebug {
                lineShapeLayer.path = nil
                startPointShapeLayer.path = nil
//                shouldBeginGestureRecognizer = true
            }
            return
        }
        
        if isAllowedPathDebug {
//          shouldBeginGestureRecognizer = false
            layoutBezierPath()
            let location = recognizer.location(in: contentView)
            if let closestPoint = bezier?.findClosestPointOnPath(fromPoint: location) {
                drawLine(fromPoint: location, toPoint: closestPoint)
            }
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
    
    public func makeDebugBezierPath(with path: CGPath) -> Bool {
        if bezier?.cgPath == path {
            return false
        }
        bezier = OMBezierPath(cgPath: path)
        bezier?.generateLookupTable()
        return true
    }
    
    func polylineLayerBezierPathDidLoad(_ layer: CAShapeLayer) {
        if isAllowedPathDebug {
            if let path = layer.path {
                layer.addSublayer(startPointShapeLayer)
                // generate the lut
                let regenerated = makeDebugBezierPath(with: path)
                print("regenerated = \(regenerated) box: \(path.boundingBoxOfPath)")
                // add the layers
                self.contentView.layer.addSublayer(lineShapeLayer)
                self.contentView.layer.addSublayer(startPointShapeLayer)
            }
        }
    }
    
    
    
    
    // MARK: - Drawing
    public func layoutBezierPath() {
        
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
        
        
        
        
        guard  let bezier = bezier else { return }
        if polylineLayer.path != bezier.cgPath {
            if let path = polylineLayer.path {
                let regenerated = makeDebugBezierPath(with: path)
                print("regenerated = \(regenerated) box: \(path.boundingBoxOfPath)")
                
            }
        }
        if showPolylineNearPoints {
            pathDots.forEach{$0.removeFromSuperlayer()}
            pathDots.removeAll()
            bezier.lookupTable.forEach { drawDot(onLayer: self.contentView.layer, atPoint: $0) }
        }
        
    }
    
    func drawLine(fromPoint: CGPoint, toPoint: CGPoint) {
        let path = UIBezierPath()
        path.move(to: fromPoint)
        path.addLine(to: toPoint)
        
        lineShapeLayer.path = path.cgPath
        
        let width: CGFloat = 6.0
        let ovalPath = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: fromPoint.x - width * 0.5, y: fromPoint.y - width * 0.5), size: CGSize(width: width, height: width)))
        startPointShapeLayer.path = ovalPath.cgPath
    }
    

    @discardableResult
    private func drawDot(onLayer parentLayer: CALayer, atPoint point: CGPoint) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let width: CGFloat = 4.0
        let path = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: point.x - width * 0.5, y: point.y - width * 0.5), size: CGSize(width: width, height: width)))
        layer.path = path.cgPath
        layer.lineWidth = 1.0
        layer.strokeColor = UIColor.magenta.withAlphaComponent(0.65).cgColor
        layer.fillColor = UIColor.clear.cgColor
        parentLayer.addSublayer(layer)
        
        pathDots.append(layer)
        return layer
    }

}
