//
//  OMScrollableChart+Shapes.swift
//  CanalesDigitalesGCiOS
//
//  Created by Jorge Ouahbi on 16/08/2020.
//  Copyright © 2020 Banco Caminos. All rights reserved.
//

import UIKit
func formatCurrency(_ value: Double,
                    fractionDigits: Int = 2,
                    locale: Locale? = Locale(identifier: "ES_es"),
                    alwaysShowsDecimalSeparator: Bool = true) -> String {
    let currencyFormatter = NumberFormatter()
    currencyFormatter.formatterBehavior = .behavior10_4
    currencyFormatter.alwaysShowsDecimalSeparator = alwaysShowsDecimalSeparator
    if fractionDigits == 0 {
        currencyFormatter.generatesDecimalNumbers = false
        currencyFormatter.maximumFractionDigits = 0
        currencyFormatter.minimumFractionDigits = 0
    } else {
        currencyFormatter.generatesDecimalNumbers = true
        currencyFormatter.maximumFractionDigits = fractionDigits
        currencyFormatter.minimumFractionDigits = fractionDigits
    }
    currencyFormatter.numberStyle = .decimal
    // Localize to your grouping and decimal separator
//    if let locale = locale {
//        currencyFormatter.locale = locale
//    } else {
//        currencyFormatter.locale = Locale.current
//    }
    currencyFormatter.decimalSeparator  = ","
    currencyFormatter.groupingSeparator = "."
    // We'll force unwrap with the !, if you've got defined data you may need more error checking
    let result = currencyFormatter.string(from: NSNumber(value: value )) ?? " "
    return "\(result)  \((locale?.currencySymbol ?? ""))"
}


extension OMScrollableChart {
    
    
    func animateLayerPath( _ shapeLayer: CAShapeLayer,
                           pathStart: UIBezierPath,
                           pathEnd: UIBezierPath,
                           duration: TimeInterval = 10) {
        //: Start with star1
        shapeLayer.path = pathStart.cgPath
        //: Create the animation from star1 to star2 (infinitely repeat, autoreverse)
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = shapeLayer.path
        animation.toValue = pathEnd.cgPath
        animation.duration = duration
        animation.autoreverses = true
        shapeLayer.add(animation, forKey: animation.keyPath)
        //shapeLayer.path = pathEnd.cgPath
        
    }
    
    private func privateDataLayers(_ render: Int,
                                    points: [CGPoint]) -> [OMGradientShapeClipLayer] {
        switch render {
        case 0:
            let layers = updatePolylineLayer(lineWidth: 4,
                                             color: .greyishBlue)
            layers.forEach({$0.name = "polyline"})
            return layers
        case 1:
            let layers = createPointsLayers(points,
                                            size: CGSize(width: 8, height: 8),
                                            color: .greyishBlue)
            layers.forEach({$0.name = "point"})
            return layers
            
        default:
            return []
        }
    }
    
   func renderLayers(_ renderIndex: Int,
                         renderAs: OMScrollableChart.RenderData) {
           
           guard let dataSource = dataSource else {
               return
           }
           let data = dataPointsRender[renderIndex]
           if let discreteData = makeRawPoints(data: data, size: contentSize) {
               switch renderAs {
               case .approximation:
                   if let approximationData = makeApproximationPoints( data: discreteData, size: contentSize) {
                       self.approximationData.insert(approximationData, at: renderIndex)
                       self.pointsRender.insert(approximationData.0, at: renderIndex)
                       var layers = dataSource.dataLayers(renderIndex, points: approximationData.0)
                       // accumulate layers
                       if layers.isEmpty {
                           layers = privateDataLayers(renderIndex,
                                                      points: approximationData.0)
                       }
                       
                       self.renderLayers.insert(layers, at: renderIndex)
                   }
               case .averaged:
                   if let averagedData = makeAveragedPoints(data: data, size: contentSize) {
                       self.averagedData.insert(averagedData, at: renderIndex)
                       self.pointsRender.insert(averagedData.0, at: renderIndex)
                       var layers = dataSource.dataLayers(renderIndex, points: averagedData.0)
                       // accumulate layers
                       if layers.isEmpty {
                           layers = privateDataLayers(renderIndex,
                                                      points: averagedData.0)
                       }
                       // accumulate layers
                       self.renderLayers.insert(layers, at: renderIndex)
                   }
               case .discrete:
                   
                   //                      let linregressData = makeLinregressPoints(data: discreteData,
                   //                                                                size: contentSize,
                   //                                                                numberOfElements: 1)
                   
                   self.discreteData.insert(discreteData, at: renderIndex)
                   self.pointsRender.insert(discreteData.0, at: renderIndex)
                   var layers = dataSource.dataLayers(renderIndex, points: discreteData.0)
                   // accumulate layers
                   if layers.isEmpty {
                       layers = privateDataLayers(renderIndex,
                                                  points: discreteData.0)
                   }
                   // accumulate layers
                   self.renderLayers.insert(layers, at: renderIndex)
               case .linregress:
                   let linregressData = makeLinregressPoints(data: discreteData, size: contentSize,numberOfElements: discreteData.0.count + 1)
                   self.linregressData.insert(linregressData, at: renderIndex)
                   self.pointsRender.insert(linregressData.0, at: renderIndex)
                   var layers = dataSource.dataLayers(renderIndex, points: linregressData.0)
                   // accumulate layers
                   if layers.isEmpty {
                       layers = privateDataLayers(renderIndex,
                                                  points: linregressData.0)
                   }
                   // accumulate layers
                   self.renderLayers.insert(layers, at: renderIndex)
               }
               self.renderType.insert(renderAs, at: renderIndex)
           }
       }
    
    func updatePolylineLayer(  lineWidth: CGFloat, color: UIColor) -> [OMGradientShapeClipLayer] {
        
        guard  let polylinePath = polylinePath else {
            return []
        }
        
        let polylineLayer: OMGradientShapeClipLayer =  OMGradientShapeClipLayer()
        
        self.lineWidth = lineWidth
        self.lineColor = color
        
        polylineLayer.path          = polylinePath.cgPath
        polylineLayer.fillColor     = UIColor.clear.cgColor
        polylineLayer.strokeColor   = self.lineColor.withAlphaComponent(0.8).cgColor
        polylineLayer.lineWidth     = self.lineWidth
        //
        polylineLayer.shadowColor   = UIColor.black.cgColor
        polylineLayer.shadowOffset  = CGSize(width: 0, height:  self.lineWidth * 2)
        polylineLayer.shadowOpacity = 0.5
        polylineLayer.shadowRadius  = 6.0
        
        // Update the frame
        polylineLayer.frame             = contentView.bounds
        
        return [polylineLayer]
    }
    func createPointsLayers( _ points: [CGPoint], size: CGSize, color: UIColor) -> [OMShapeLayerRadialGradientClipPath] {
        var layers =  [OMShapeLayerRadialGradientClipPath]()
        for point in points {
            let circleLayer = OMShapeLayerRadialGradientClipPath()
            circleLayer.bounds = CGRect(x: 0,
                                        y: 0,
                                        width: size.width,
                                        height: size.height)
            let path = UIBezierPath(ovalIn: circleLayer.bounds).cgPath
            circleLayer.gradientColor   = color
            circleLayer.path            = path
            circleLayer.fillColor       = color.cgColor
            circleLayer.position        = point
            circleLayer.strokeColor     = nil //UIColor.black.cgColor
            circleLayer.lineWidth       = 0.5
            
            circleLayer.shadowColor     = UIColor.black.cgColor
            circleLayer.shadowOffset    = pointsLayersShadowOffset
            circleLayer.shadowOpacity   = 0.7
            circleLayer.shadowRadius    = 3.0
            circleLayer.isHidden        = false
            //circleLayer.opacity         = showPoints ? 1 : 0
            circleLayer.bounds = circleLayer.path!.boundingBoxOfPath
            layers.append(circleLayer)
        }
        return layers
    }
    func createInverseRectanglePaths( _ points: [CGPoint], columnIndex: Int, count: Int) -> [UIBezierPath] {
        var paths =  [UIBezierPath]()
        for currentPointIndex in 0..<points.count - 1 {
            let width = abs(points[currentPointIndex].x - points[currentPointIndex+1].x)
            let widthDivisor = width / CGFloat(count)
            let originX = points[currentPointIndex].x + (widthDivisor * CGFloat(columnIndex))
            let point = CGPoint(x: originX, y: points[currentPointIndex].y)
            let height = self.frame.maxY - points[currentPointIndex].y - footerViewHeight
            let path = UIBezierPath(
                rect: CGRect(
                    x: point.x,
                    y: point.y + height,
                    width: width / CGFloat(count),
                    height: footerViewHeight)
            )
            
            paths.append(path)
        }
        
        return paths
    }
    func createRectangleLayers( _ points: [CGPoint], columnIndex: Int, count: Int, color: UIColor) -> [OMGradientShapeClipLayer] {
        var layers =  [OMGradientShapeClipLayer]()
        for currentPointIndex in 0..<points.count - 1 {
            let width = abs(points[currentPointIndex].x - points[currentPointIndex+1].x)
            let widthDivisor = width / CGFloat(count)
            let originX = points[currentPointIndex].x + (widthDivisor * CGFloat(columnIndex))
            let point = CGPoint(x: originX, y: points[currentPointIndex].y)
            let path = UIBezierPath(
                rect: CGRect(
                    x: point.x,
                    y: point.y,
                    width: width / CGFloat(count),
                    height: self.frame.maxY - points[currentPointIndex].y - footerViewHeight)
            )
            let rectangleLayer = OMShapeLayerLinearGradientClipPath()
            rectangleLayer.gardientColor   = color
            rectangleLayer.path            = path.cgPath
            rectangleLayer.fillColor       = color.withAlphaComponent(0.6).cgColor
            rectangleLayer.position        = point
            rectangleLayer.strokeColor     = color.cgColor
            rectangleLayer.lineWidth       = 1
            rectangleLayer.anchorPoint     = .zero
            rectangleLayer.shadowColor     = UIColor.black.cgColor
            rectangleLayer.shadowOffset    = pointsLayersShadowOffset
            rectangleLayer.shadowOpacity   = 0.7
            rectangleLayer.shadowRadius    = 3.0
            rectangleLayer.isHidden        = false
            rectangleLayer.bounds          = rectangleLayer.path!.boundingBoxOfPath
            layers.insert(rectangleLayer, at: currentPointIndex)
        }
        return layers
    }
    func selectRenderLayer(_ layer: OMGradientShapeClipLayer, renderIndex: Int) {
        let allUnselectedRenderLayers = self.renderLayers[renderIndex].filter { $0 != layer }
        print("allUnselectedRenderLayers = \(allUnselectedRenderLayers.count)")
        allUnselectedRenderLayers.forEach { (layer: OMGradientShapeClipLayer) in
            layer.gardientColor = self.unselectedColor
            layer.opacity   = self.unselectedOpacy
        }
        layer.gardientColor = self.selectedColor
        layer.opacity   = self.selectedOpacy
    }
    func locationToNearestLayer( _ location: CGPoint, renderIndex: Int) -> OMGradientShapeClipLayer? {
        let mapped = renderLayers[renderIndex].map {
            return $0.frame.origin.distance(from: location)
        }
        guard let index = mapped.indexOfMin else {
            return nil
        }
        return renderLayers[renderIndex][index]
    }
    func touchPointAsFarLayer( _ location: CGPoint, renderIndex: Int) -> OMGradientShapeClipLayer? {
        let mapped = renderLayers[renderIndex].map {
            return $0.frame.origin.distance(from: location)
        }
        guard let index = mapped.indexOfMax else {
            return nil
        }
        return renderLayers[renderIndex][index]
    }
    func hitTestAsLayer( _ location: CGPoint) -> CALayer? {
        if let layer = contentView.layer.hitTest(location) { // If you hit a layer and if its a Shapelayer
            return layer
        }
        return nil
    }
    
  
    
    fileprivate func didSelectedIndex(_ dataIndex: Int) {
        if let footer = footerRule as? OMScrollableChartRuleFooter {
                footer.arrangedSubviews[dataIndex].shakeGrow(duration: 1.0)
    
            
        }
    }
    
    func selectPointLayer(_ layerPoint: OMGradientShapeClipLayer,
                          selectedPoint: CGPoint,
                          animateFixLocation: Bool = false,
                          renderIndex: Int) {
        //selectRenderLayer(layerPoint, renderIndex: renderIndex)
        if animatePointLayers {
            animateOnSelectPoint(layerPoint, renderIndex: renderIndex)
        }
        let dataIndex = dataIndexFromPoint(layerPoint.position,
                                           renderIndex: renderIndex)
        
        didSelectedIndex(dataIndex)
        //print("dataIndex: \(dataIndex)")
        let tooltipText = dataSource?.dataPointTootipText(chart: self,
                                                          renderIndex: renderIndex,
                                                          dataIndex: dataIndex,
                                                          section: 0)
        var tooltipPosition = CGPoint.zero,
        tooltipPositionFix = CGPoint.zero
        if animateFixLocation {
            tooltipPositionFix = layerPoint.position
        }
        
        tooltipPosition = CGPoint(x: layerPoint.position.x, y: selectedPoint.y)
        
        let dataSection = dataSource?.dataSectionForIndex(chart: self,
                                                          dataIndex: dataIndex,
                                                          section: 0) ?? ""
        if let tooltipText = tooltipText {
            tooltip.string = "\(dataSection) \(tooltipText)"
            tooltip.displayTooltip(tooltipPosition)
        } else {
            if let string = dataStringFromPoint(layerPoint.position, renderIndex: renderIndex) {
                tooltip.string = "\(dataSection) \(string)"
            } else {
                let amount = Double(dataPointsRender[renderIndex][dataIndex])
                tooltip.string = "\(dataSection) \(formatCurrency(amount))"
            }
            tooltip.displayTooltip(tooltipPosition)
        }
        
        if animateFixLocation {
            let distance = tooltipPositionFix.distance(to: tooltipPosition)
            let factor: TimeInterval = TimeInterval(1 / (self.bounds.height / distance))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.tooltip.moveTooltip(tooltipPositionFix,
                                               duration: 2.0 / factor)
             }
        }
    }
    func locationFromTouch(_ touches: Set<UITouch>) -> CGPoint {
        if let touch = touches.first {
            return touch.location(in: self.contentView)
        }
        return .zero
    }
    func indexForPoint(_ point: CGPoint, renderIndex: Int) -> Int? {
        let newPoint = CGPoint(x: point.x, y: point.y)
        return discreteData[renderIndex]?.points.map{ $0.distance(to: newPoint)}.indexOfMin
    }
    func dataStringFromPoint(_ point: CGPoint, renderIndex: Int) -> String? {
        if self.renderType[renderIndex] == .averaged {
            if let render = discreteData[renderIndex],
                let firstIndex = indexForPoint(point, renderIndex: renderIndex) {
                let item: Double = Double(render.data[firstIndex])
                if let currentStep = currencyFormatter.string(from: NSNumber(value: item)) {
                    return  currentStep
                }
            }
        } else {
            if let render = discreteData[renderIndex],
                let firstIndex = render.points.firstIndex(of: point) {
                let item: Double = Double(render.data[firstIndex])
                if let currentStep = currencyFormatter.string(from: NSNumber(value: item)) {
                    return currentStep
                }
            }
        }
        return nil
    }
    func dataFromPoint(_ point: CGPoint, renderIndex: Int) -> Float {
        if self.renderType[renderIndex] == .averaged {
            if let render = discreteData[renderIndex],
                let firstIndex = indexForPoint(point, renderIndex: renderIndex) {
                return Float(render.data[firstIndex])
            }
        } else {
            if let render = discreteData[renderIndex],
                let firstIndex = render.points.firstIndex(of: point) {
                return Float(render.data[firstIndex])
            }
        }
        return 0
    }
    func dataIndexFromPoint(_ point: CGPoint, renderIndex: Int) -> Int {
        if self.renderType[renderIndex] == .averaged {
            if let firstIndex = indexForPoint(point, renderIndex: renderIndex) {
                return firstIndex
            }
        } else {
            if let render = discreteData[renderIndex] {
                if let firstIndex = render.points.firstIndex(of: point) {
                    return firstIndex
                }
            }
        }
        return 0
    }
}
