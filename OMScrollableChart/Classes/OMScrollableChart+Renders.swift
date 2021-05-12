// Copyright 2018 Jorge Ouahbi
//
// Licensed under the Apache License, Version 2.0 (the "License");
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

extension Date {
    var mouthTimeElapsedPercent: CGFloat {
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date)
        let currentDay = components.day ?? 1
        let range = calendar.range(of: .day, in: .month, for: date)
        let numberOfDaysInMouth = range!.count
        let displacementInSection: CGFloat = CGFloat(1.0) / CGFloat(numberOfDaysInMouth) * CGFloat(currentDay)
        return displacementInSection
    }
}


/*
 La idea es que el usuario facilmente pueda crear representacion
 para sus datos.
 
 El motor usa como herramientas de construccion los diferentes `renders` que se le proporcione,
 Los 'renders´ proporcionan layers al motor cuando quieran representa datos, animaciones
 cuando se quiera animar los datos representados...etc
 
 Yo proporcionno los 6 primeros. Llamados: 'legacy renders´
 
 polyline:  Mantiene una linea uniendo todos los puntos de información de la representación de los datos, la            linea por defecto está interpolada usando 'Catmull-Rom splines`, aunque es completamente
 configurable.
 puntos  :  Representa cada punto de información de la representación de los datos.
 punto seleccionado
 punto actual
 segmento de seccion
 */


extension OMScrollableChart {
    private func renderDefaultLayers(_ renderIndex: Int, points: [CGPoint]) -> [OMGradientShapeClipLayer] {
        switch Renders(rawValue: renderIndex) {
        case .polyline:
            let lineWidth: CGFloat = 4
            let color  = UIColor.greyishBlue
            let layers = updatePolylineLayer(lineWidth: lineWidth, color: color)
            layers.forEach({$0.name = "polyline"})
            return layers
        case .segments:
            
            guard let subPaths = self.polylinePath?.cgPath.subpaths, subPaths.count > 0 else {
                print("[RENDER][ERROR] Empty polyline subpaths.")
                return []
            }
            let strokeSegmentsColor: UIColor = lineColor.withAlphaComponent(0.1)
            let segmentsFillColor: UIColor   = selectedColor.withAlphaComponent(0.11)
            
            let colors: [UIColor] = [UIColor.greyishBlue.adjust(by: 0.7).withAlphaComponent(0.41),
                                     UIColor.greyishBlue.adjust(by: 0.5).withAlphaComponent(0.74),
                                     UIColor.greyishBlue.adjust(by: 0.4).withAlphaComponent(0.61),
                                     UIColor.greyishBlue.adjust(by: 0.5).withAlphaComponent(0.71),
                                     UIColor.greyishBlue.adjust(by: 0.7).withAlphaComponent(0.41)]
            
            let layers = createSegmentLayers(subPaths,
                                                  lineWidth * 2,
                                                  colors,
                                                  strokeSegmentsColor,
                                                  segmentsFillColor)
            
            #if DEBUG
                layers.enumerated().forEach { $1.name = "line segment \($0)" } // debug
            #endif

            return layers
        case .points:
            let pointSize = CGSize(width: 8, height: 8)
            let layers = createPointsLayers(points,
                                            size: pointSize,
                                            color: .greyishBlue)
            layers.forEach({$0.name = "point"})
            return layers
        case .selectedPoint:
            if let point = maxPoint(in: renderIndex) {
                let layer = createPointLayer(point,
                                             size: CGSize(width: 13, height: 13),
                                             color: .darkGreyBlueTwo)
                layer.name = "selectedPointDefault"
                return [layer]
            }
        case .currentPoint:
            if let point = maxPoint(in: renderIndex) {
                let layer = createPointLayer(point,
                                             size: CGSize(width: 11, height: 11),
                                             color: .paleGrey)
                layer.name = "selectedPointDefault"
                return [layer]
            }
        default:
            return []
        }
        return []
    }
    var polylinePath: UIBezierPath? {
        guard  let polylinePoints =  polylinePoints,
            let polylinePath = polylineInterpolation.asPath(points: polylinePoints) else {
                return nil
        }
        return polylinePath
    }
    func updatePolylineLayer( lineWidth: CGFloat,
                              color: UIColor) -> [OMGradientShapeClipLayer] {
        guard  let polylinePath = polylinePath else {
            return []
        }
        let polylineLayer: OMGradientShapeClipLayer =  OMGradientShapeClipLayer()
        self.lineWidth = lineWidth
        self.lineColor = color
        polylineLayer.path          = polylinePath.cgPath
        polylineLayer.fillColor     = UIColor.clear.cgColor
        polylineLayer.strokeColor   = self.lineColor.withAlphaComponent(0.5).cgColor
        polylineLayer.lineWidth     = self.lineWidth
        polylineLayer.shadowColor   = UIColor.black.cgColor
        polylineLayer.shadowOffset  = CGSize(width: 0, height:  self.lineWidth * 2)
        polylineLayer.shadowOpacity = 0.5
        polylineLayer.shadowRadius  = 6.0
        // Update the frame
        polylineLayer.frame         = contentView.bounds
        
        return [polylineLayer]
    }
    func makeApproximation(_ data: [Float], _ renderIndex: Int, _ dataSource: OMScrollableChartDataSource) {
        let discretePoints = makeRawPoints(data, size: contentView.bounds.size)
        
        if discretePoints.count > 0 {
            let chartData = (discretePoints, data)
            if let approximationPoints =  makeApproximationPoints( points: discretePoints,
                                                                   tolerance: approximationTolerance) {
                if approximationPoints.count > 0 {
                    self.approximationData.insert(chartData, at: renderIndex)
                    self.pointsRender.insert(approximationPoints, at: renderIndex)
                    var layers = dataSource.dataLayers(chart: self,
                                                       renderIndex: renderIndex,
                                                       section: 0, points: approximationPoints)
                    // accumulate layers
                    if layers.isEmpty {
                        layers = renderDefaultLayers(renderIndex,
                                                     points: approximationPoints)
                    }
                    
                    self.renderLayers.insert(layers, at: renderIndex)
                }
            }
        }
    }
    
    func makeAverage(_ data: [Float], _ renderIndex: Int, _ dataSource: OMScrollableChartDataSource) {
        if let points = makeAveragedPoints(data: data,
                                                   size: contentView.bounds.size,
                                                   elementsToAverage: numberOfElementsToAverage) {
            let chartData = (points, data)
            self.averagedData.insert(chartData, at: renderIndex)
            self.pointsRender.insert(points, at: renderIndex)
            var layers = dataSource.dataLayers(chart: self,
                                               renderIndex: renderIndex,
                                               section: 0,
                                               points: points)
            // accumulate layers
            if layers.isEmpty {
                layers = renderDefaultLayers(renderIndex, points: points)
            }
            // accumulate layers
            self.renderLayers.insert(layers, at: renderIndex)
        }
    }
    
    func makeDiscrete(_ data: [Float],
                                  _ renderIndex: Int,
                                  _ dataSource: OMScrollableChartDataSource) {
        //                      let linregressData = makeLinregressPoints(data: discreteData,
        //                                                                size: contentSize,
        //                                                                numberOfElements: 1)
        let points = makeRawPoints(data, size: contentView.bounds.size)
        if points.count > 0 {
            let chartData = (points, data)
            self.discreteData.insert(chartData, at: renderIndex)
            self.pointsRender.insert(points, at: renderIndex)
            
            var layers = dataSource.dataLayers(chart: self,
                                               renderIndex: renderIndex,
                                               section: 0,
                                               points: points)
            //  use the private
            if layers.isEmpty {
                layers = renderDefaultLayers(renderIndex,
                                             points: points)
            }
            // accumulate layers
            self.renderLayers.insert(layers, at: renderIndex)
        }
    }
    
    private func makeLinregress(_ data: [Float],
                                    _ renderIndex: Int,
                                    _ dataSource: OMScrollableChartDataSource) {
        let points = makeRawPoints(data, size: contentView.bounds.size)
        if points.count > 0{
            let chartData = (points, data)
            let linregressData = makeLinregressPoints(data: chartData,
                                                      size: contentView.bounds.size,
                                                      numberOfElements: points.count + 1,
                                                      renderIndex: renderIndex)
            self.linregressData.insert(linregressData, at: renderIndex)
            self.pointsRender.insert(linregressData.0, at: renderIndex)
            var layers = dataSource.dataLayers(chart: self,
                                               renderIndex: renderIndex,
                                               section: 0,
                                               points: linregressData.0)
            // accumulate layers
            if layers.isEmpty {
                layers = renderDefaultLayers(renderIndex,
                                             points: linregressData.0)
            }
            
            // accumulate layers
            self.renderLayers.insert(layers, at: renderIndex)
        }
    }
    
    /// renderLayers
    /// - Parameters:
    ///   - renderIndex: render index
    ///   - renderAs: RenderData
    func renderLayers(_ renderIndex: Int, renderAs: OMScrollableChart.RenderType) {
        guard let dataSource = dataSource else {
            return
        }
        let currentRenderData = renderDataPoints[renderIndex]
        switch renderAs {
        case .approximation: makeApproximation(currentRenderData, renderIndex, dataSource)
        case .averaged: makeAverage(currentRenderData, renderIndex, dataSource)
        case .discrete: makeDiscrete(currentRenderData, renderIndex, dataSource)
        case .linregress: makeLinregress(currentRenderData, renderIndex, dataSource)
        }
        self.renderType.insert(renderAs, at: renderIndex)
    }
    
    func createPointsLayers( _ points: [CGPoint], size: CGSize, color: UIColor) -> [OMShapeLayerRadialGradientClipPath] {
        var layers = [OMShapeLayerRadialGradientClipPath]()
        for point in points {
            let circleLayer = createPointLayer(point, size: size, color: color)
            layers.append(circleLayer)
        }
        return layers
    }
    
    private func createPointLayer( _ point: CGPoint, size: CGSize, color: UIColor) -> OMShapeLayerRadialGradientClipPath {
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
        circleLayer.strokeColor     = nil
        circleLayer.lineWidth       = 0.5
        
        circleLayer.shadowColor     = UIColor.black.cgColor
        circleLayer.shadowOffset    = pointsLayersShadowOffset
        circleLayer.shadowOpacity   = 0.7
        circleLayer.shadowRadius    = 3.0
        circleLayer.isHidden        = false
        circleLayer.bounds          = circleLayer.path!.boundingBoxOfPath
        
        return circleLayer
    }
    
    func createInverseRectanglePaths( _ points: [CGPoint],
                                      columnIndex: Int,
                                      count: Int) -> [UIBezierPath] {
        var paths =  [UIBezierPath]()
        for currentPointIndex in 0..<points.count - 1 {
            let width = abs(points[currentPointIndex].x - points[currentPointIndex+1].x)
            let widthDivisor = width / CGFloat(count)
            let originX = points[currentPointIndex].x + (widthDivisor * CGFloat(columnIndex))
            let point = CGPoint(x: originX, y: points[currentPointIndex].y)
            let height = contentView.frame.maxY - points[currentPointIndex].y
            let path = UIBezierPath(
                rect: CGRect(
                    x: point.x,
                    y: point.y + height,
                    width: width / CGFloat(count),
                    height: 1)
            )
            paths.append(path)
        }
        
        return paths
    }
    func createRectangleLayers( _ points: [CGPoint],
                                columnIndex: Int,
                                count: Int,
                                color: UIColor) -> [OMGradientShapeClipLayer] {
        
        var layers =  [OMGradientShapeClipLayer]()
        for currentPointIndex in 0..<points.count - 1 {
            
            let width = abs(points[currentPointIndex].x - points[currentPointIndex+1].x)
            let height =  contentView.frame.maxY - points[currentPointIndex].y
            let widthDivisor = width / CGFloat(count)
            let originX = points[currentPointIndex].x + (widthDivisor * CGFloat(columnIndex))
            let point = CGPoint(x: originX, y: points[currentPointIndex].y)
            let path = UIBezierPath(
                rect: CGRect(
                    x: point.x,
                    y: point.y,
                    width: width / CGFloat(count),
                    height: height) //self.frame.maxY - points[currentPointIndex].y - footerViewHeight)
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
    
    
    ///
    /// createSegmentLayers
    ///
    /// - Parameters:
    ///   - segmentsPaths: [UIBezierPath]
    ///   - lineWidth: lineWidth
    ///   - color: UIColor
    ///   - strokeColor: UIColor
    /// - Returns: [GlowPathLayer]
    ///
    ///
    func createSegmentLayers(_ segmentsPaths: [UIBezierPath],
                             _ lineWidth: CGFloat = 0.5,
                             _ colors: [UIColor] = [.white, .red],
                             _ fillColor: UIColor? = .clear,
                             _ strokeColor: UIColor? = nil) -> [OMGradientShapeClipLayer] {
        var layers = [OMGradientShapeClipLayer]()
        for (idx, path) in segmentsPaths.enumerated() {
            if idx % 4 == 0 {
                continue
            }
            let shapeSegmentLayer = OMGradientShapeClipLayer()
            let color = colors[idx % colors.count]
            shapeSegmentLayer.strokeColor = color.withAlphaComponent(0.8).cgColor
            
            shapeSegmentLayer.lineWidth     = lineWidth
            shapeSegmentLayer.path          = path.cgPath
            let box = path.bounds

            shapeSegmentLayer.position      = box.origin
            shapeSegmentLayer.fillColor     = color.darker.withAlphaComponent(0.12).cgColor
            shapeSegmentLayer.bounds        =  box //.insetBy(dx: -(lineWidth), dy: -(lineWidth))
            shapeSegmentLayer.anchorPoint   = .zero
            shapeSegmentLayer.zPosition     =  40
            shapeSegmentLayer.lineCap       = .square
            shapeSegmentLayer.lineJoin      = .round
            shapeSegmentLayer.opacity       = 1.0

            shapeSegmentLayer.setGlow( with: color)
            
            layers.append(shapeSegmentLayer)
            shapeSegmentLayer.setNeedsLayout()
        
        }
        return layers
    }
}


extension CALayer {
    public func setGlow(with color: UIColor) {
        masksToBounds = false
        shadowColor =  color.cgColor
        shadowOpacity = 1
        shadowRadius  = 4.0
        shadowOpacity = 0.9
        shadowOffset  = CGSize(width: 0,height: 3)
    }
}
