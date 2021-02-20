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

import LibControl
import UIKit

struct ScrollableRendersConfiguration {
    static let defaultPointSize = CGSize(width: 8, height: 8)
    static let defaultPathPointSize = CGSize(width: 10, height: 10)
    static let defaultSelectedPointSize = CGSize(width: 13, height: 13)
    static let defaultLineWidth: CGFloat = UIScreen.main.bounds.height / 250

    static let animationPointsClearOpacityKey: String = "animationPointsClearOpacityKey"


}

public extension OMScrollableChart {
    /// makeApproximation
    /// - Parameters:
    ///   - data: [Float]]
    ///   - renderIndex: index
    ///   - dataSource: OMScrollableChartDataSource
    func makeScalePointsSimplifyAndLayers(_ render: BaseRender,
                                          _ size: CGSize,
                                          _ simplifyType: SimplifyType,
                                          _ tolerance: CGFloat)
    {
        let points = render.makePoints(size)
        if points.count > 0 {
            if let simplifyPoints = simplifyPoints(points: points,
                                                   type: simplifyType,
                                                   tolerance: tolerance)
            {
                // remove the index from data
                let difference = simplifyPoints.difference(from: points)
                var diffedData = render.data.data.map { $0 }
                for change in difference {
                    switch change {
                    case .remove(let offset, _, _):
                        diffedData.remove(at: offset)
                    case .insert: break
                        // diffedData.insert(newElement, at: offset)
                    }
                }
                let data = RenderData(data: diffedData, points: simplifyPoints)
                render.data = data
                if simplifyPoints.count > 0 {
                    var layers = dataSource?.dataLayers(chart: self,
                                                        renderIndex: render.index,
                                                        section: 0,
                                                        data: data) ?? []
                    // accumulate layers
                    if layers.isEmpty {
//                        print("Unexpected empty layers, lets use the default renders.")
                        layers = self.renderDefaultLayers(render, data: data)
                    }
                    render.layers.append(contentsOf: layers)
                    
                    flowDelegate?.updateRenderLayers(index: render.index,
                                                     with: render.layers)
                } else {
//                    print("Unexpected empty simplify points.")
                }
            }
        } else {
//            print("Unexpected empty discrete points for simplify.")
        }
    }
    
    
    
    /// Make mean points
    /// - Parameters:
    ///   - data: [Float]
    ///   - renderIndex: index
    ///   - dataSource: OMScrollableChartDataSource
    func makeStadisticsScaledPointsAndLayers(
        _ render: BaseRender,
        _ size: CGSize,
        _ grouping: CGFloat) {
        let renderData = make(data: render.data.data,
                              size: size,
                              grouping: CGFloat(grouping),
                              function: {
                                  switch $0 {
                                  default:
                                      // TODO:
                                      return $0.mean()
                                  }
                              })
        if renderData.points.count > 0 {
            var layers = dataSource?.dataLayers(chart: self,
                                                renderIndex: render.index,
                                                section: 0,
                                                data: renderData) ?? []
            // accumulate layers
            if layers.isEmpty {
//                print("Unexpected empty render layers, let's use the default renders.")
                layers = self.renderDefaultLayers(render, data: renderData)
            }
            render.data = renderData
            render.layers.append(contentsOf: layers)
            
            flowDelegate?.updateRenderLayers(index: render.index,
                                             with: render.layers)
        } else {
//            print("Unexpected empty points.")
        }
    }
    
    /// makeDiscrete points
    /// - Parameters:
    ///   - data: [Float]
    ///   - renderIndex: index
    ///   - dataSource: OMScrollableChartDataSource
    func makeDiscreteScalePointsAndLayers(_ render: BaseRender,
                                          _ size: CGSize) {
        let points = render.makePoints(size)
        if points.count > 0 {
//            print("making render \(render.index) layers.")
            let datRebuilded = RenderData(data: render.data.data, points: points)
            var layers = dataSource?.dataLayers(chart: self,
                                                renderIndex: render.index,
                                                section: 0,
                                                data: datRebuilded) ?? []
            render.data = datRebuilded
            //  use the default renders
            if layers.isEmpty {
//                print("Unexpected empty layers render \(render.index), lets use the default renders.")
                layers = self.renderDefaultLayers(render, data: datRebuilded)
            }
            // accumulate layers
//            print("Accumulating \(layers.count) layers.")
            
            flowDelegate?.updateRenderLayers(index: render.index,
                                             with: render.layers)
            
            render.layers.append(contentsOf: layers)
        } else {
//            print("Unexpected empty discrete points (makeRawPoints).")
        }
    }
    
    /// makeLinregressScaledPointsAndLayers
    /// - Parameters:
    ///   - render:  BaseRender
    ///   - size: size
    ///   - numberOfElements: Int
    func makeLinregressScaledPointsAndLayers(_ render: BaseRender,
                                             _ size: CGSize,
                                             _ numberOfElements: Int)
    {
        let points = render.makePoints(size)
        if points.count > 0 {
            let chartData = RenderData(data: render.data.data, points: points)
            let linregressData = makeLinregressPoints(data: chartData,
                                                      size: size,
                                                      numberOfElements: numberOfElements,
                                                      renderIndex: render.index)
            
            //            let linregressData = makeLinregressPoints(data: chartData,
            //                                                      size: contentView.bounds.size,
            //                                                      numberOfElements: points.count + 1,
            //                                                      renderIndex: renderIndex)
            render.data = linregressData
            var layers = dataSource?.dataLayers(chart: self,
                                                renderIndex: render.index,
                                                section: 0,
                                                data: linregressData) ?? []
            // accumulate layers
            if layers.isEmpty {
//                print("Unexpected empty layers render \(render.index), lets use the default renders.")
                layers = self.renderDefaultLayers(render,
                                                  data: linregressData)
            }
            // accumulate layers
//            print("Accumulating \(layers.count) layers.")
            render.layers.append(contentsOf: layers)
            
            flowDelegate?.updateRenderLayers(index: render.index,
                                             with: render.layers)
        } else {
//            print("Unexpected empty discrete points (makeRawPoints).")
        }
    }
}

// MARK: - Renders -

public extension OMScrollableChart {
    // Render the internal layers:
    // 0 - Polyline
    // 1 - Discrete points
    // 2 - Selected point
    internal func renderDefaultLayers(_ render: BaseRender, data: RenderData) -> [GradientShapeLayer] {
        switch render.index {
        case RenderIdent.polyline.rawValue:
            // let color = UIColor.greyishBlue
            let layers = self.updatePolylineLayer()
            #if DEBUG
            if layers.first?.name == nil {
                layers.forEach { $0.name = "polyline" }
            }
            #endif
            return layers
        case RenderIdent.points.rawValue:
            let layers = self.createPointsLayers(data.points,
                                                 size: ScrollableRendersConfiguration.defaultPointSize,
                                                 shadowOffset: pointsLayersShadowOffset,
                                                 color: pointColor)
            #if DEBUG
            if layers.first?.name == nil {
                layers.enumerated().forEach { $1.name = "point \($0)" }
            }
            #endif
            return layers
        case RenderIdent.selectedPoint.rawValue:
            if let point = render.data.maxPoint {
                let layer = self.createPointLayer(point,
                                                  size: ScrollableRendersConfiguration.defaultSelectedPointSize,
                                                  color: selectedPointColor,
                                                  shadowOffset: pointsLayersShadowOffset)
                #if DEBUG
                layer.name = "selectedPoint"
                #endif
                return [layer]
            }
        default:
            return []
        }
        return []
    }
    
    //
    // Get the polyline render sub paths
    //
    // output: [UIBezierPath]
    //
    var polylineSubpaths: [UIBezierPath] {
        guard let polylinePath = polylinePath else {
//            print("Unexpected empty polylinePath (UIBezierPath).")
            return []
        }
        return polylinePath.cgPath.subpaths
    }
    
    //
    // Get the polyline bezier paths
    //
    // output: [UIBezierPath]
    //

    var polylinePath: UIBezierPath? {
        let polylinePoints = engine.renders[RenderIdent.polyline.rawValue].data.points
        guard let polylinePath = polylineInterpolation.asPath(points: polylinePoints) else {
//            print("Unexpected empty polylinePath (UIBezierPath).")
            return nil
        }
        return polylinePath
    }
    
    /// regenerateFromBezier
    /// - Parameter path: CGPath
    func regenerateFromBezier(withBezier path: CGPath?,
                              dotColor: UIColor) {
        if let path = path {
            bezier = BezierPathSegmenter(cgPath: path)
            bezier?.generateLookupTable()
            
//            glassLayer.frame = contentView.bounds
//            glassLayer.path = path
////            glassLayer.fillColor = lineColor.cgColor
//            glassLayer.strokeColor = pointColor.cgColor
////            let points = Path(cgPath: path).destinationPoints()
//            contentView.layer.mask = glassLayer
            
//            strokeGradient(ctx: UIGraphicsGetCurrentContext(),
//                     layer: glassLayer,
//                     points: points,
//                     color: UIColor.greenSea,
//                     lowColor: UIColor.greenSea.complementaryColor,
//                     lineWidth: lineWidth,
//                     fadeFactor: 0.8)
            
//            self.contentView.layer.addSublayer(layer)
            //      debugLayoutLimit()
            if showPolylineNearPoints {
                dotPathLayers.forEach{$0.removeFromSuperlayer()}
                dotPathLayers.removeAll()
                bezier?.lookupTable.forEach {
                    drawDot(onLayer: self.contentView.layer,
                            atPoint: $0,
                            atSize: ScrollableRendersConfiguration.defaultPathPointSize,
                            color: dotColor,
                            alpha: 0.75)
                }
            }
//            print("Regenerate path: \(path.boundingBoxOfPath)")
        }
    }
    
    /// updatePolylinePath
    /// - Parameter polylinePath: UIBezierPath
    func updatePolylinePath(_ polylinePath: UIBezierPath) {
        // Update the polyline path
        polylineLayer.path = polylinePath.cgPath
        print(
            """
                \(RenderIdent.polyline)
                ´\(String(describing: layer.name))´ path change in layer
            """)
        
        regenerateFromBezier(withBezier: polylineLayer.path,
                             dotColor: ScrollableChartColorConfiguration.bezierColor)
    }
    
    ///  Update the polyline layer with UIBezierPath, strokeColor, lineWidth
    // TODO: complete the shadow.
    /// - Returns: [GradientShapeLayer]
    func updatePolylineLayer(_ strokeAlpha: CGFloat = 0.64) -> [GradientShapeLayer] {
        guard let polylinePath = polylinePath else {
            print("Unexpected empty polylinePath (UIBezierPath).")
            return []
        }
        
        self.updatePolylinePath(polylinePath)
        
        polylineLayer.fillColor = UIColor.clear.cgColor
        polylineLayer.strokeColor = (self.strokeLineColor ?? self.lineColor.withAlphaComponent(strokeAlpha)).cgColor
        polylineLayer.lineWidth = self.lineWidth
        polylineLayer.shadowColor = UIColor.black.cgColor
        polylineLayer.shadowOffset = CGSize(width: 0, height: self.lineWidth * 2)
        polylineLayer.shadowOpacity = 0.5
        polylineLayer.shadowRadius = 6.0
        // Update the frame
        polylineLayer.frame = contentView.bounds
        return [polylineLayer]
    }
    
    /// Render layers of render ´renderIndex´ as ´RenderType´
    /// - Parameters:
    ///   - renderIndex: render index
    ///   - renderAs: RenderDataType
    private func renderLayers(from renderIndex: Int, size: CGSize, renderAs: RenderType) {
        // get the data points
        let render = engine.renders[renderIndex]
        switch renderAs {
        case .discrete:
            self.makeDiscreteScalePointsAndLayers(render, size)
        case .simplify(let type, let tol):
            self.makeScalePointsSimplifyAndLayers(render, size, type, tol)
        case .stadistics(let elements):
            self.makeStadisticsScaledPointsAndLayers(render, size, elements)
        case .regress(let elements):
            self.makeLinregressScaledPointsAndLayers(render, size, elements)
        }
        // Update the type if needed.
        if render.data.dataType != renderAs {
            render.data = RenderData(data: render.data.data,
                                     points: render.data.points,
                                     type: renderAs)
            
            flowDelegate?.updateRenderData(index: render.index,
                                           data: render.data)
        }
    }
    /// renderLayers
    /// - Parameters:
    ///   - render: render description
    ///   - size: size description
    func renderLayers(with render: BaseRender, size: CGSize) {
        // get the data poiunt
        switch render.data.dataType {
        case .discrete:
            self.makeDiscreteScalePointsAndLayers(render, size)
        case .simplify(let type, let tol):
            self.makeScalePointsSimplifyAndLayers(render, size, type, tol)
        case .stadistics(let elements):
            self.makeStadisticsScaledPointsAndLayers(render, size, elements)
        case .regress(let elements):
            self.makeLinregressScaledPointsAndLayers(render, size, elements)
        }
    }
    
    /// createPointsLayers
    /// - Parameters:
    ///   - points: [CGPoint]
    ///   - size: CGSize
    ///   - color: UIColor
    /// - Returns:  [ShapeRadialGradientLayer]
    func createPointsLayers(_ points: [CGPoint],
                            size: CGSize,
                            shadowOffset: CGSize,
                            color: UIColor) -> [ShapeRadialGradientLayer] {
        return points.map { createPointLayer($0,
                                             size: size,
                                             color: color,
                                             shadowOffset: shadowOffset ) }
    }
    
    /// Create a point layer
    /// - Parameters:
    ///   - point: CGPoint
    ///   - size: CGSize
    ///   - color: UIColor
    /// - Returns: ShapeRadialGradientLayer
    func createPointLayer(_ point: CGPoint,
                          size: CGSize,
                          color: UIColor,
                          shadowOffset: CGSize) -> ShapeRadialGradientLayer {
        let circleLayer = ShapeRadialGradientLayer()
        circleLayer.bounds = CGRect(x: 0,
                                    y: 0,
                                    width: size.width,
                                    height: size.height)
        let path = UIBezierPath(ovalIn: circleLayer.bounds).cgPath
        circleLayer.gradientColor = color
        circleLayer.path = path
        circleLayer.fillColor = color.cgColor
        circleLayer.position = point
        circleLayer.strokeColor = nil
        circleLayer.lineWidth = 0.5
        
        circleLayer.shadowColor = UIColor.black.cgColor
        circleLayer.shadowOffset = shadowOffset
        circleLayer.shadowOpacity = 0.7
        circleLayer.shadowRadius = 3.0
        circleLayer.opacity = 1.0
        circleLayer.bounds = circleLayer.path!.boundingBoxOfPath
        
        return circleLayer
    }
    
    /// createInverseRectanglePaths
    /// - Parameters:
    ///   - points: [CGPoint]
    ///   - columnIndex: columnIndex
    ///   - count: count
    /// - Returns: [UIBezierPath]
    func createInverseRectanglePaths(_ points: [CGPoint],
                                     columnIndex: Int,
                                     count: Int) -> [UIBezierPath] {
        var paths = [UIBezierPath]()
        for currentPointIndex in 0..<points.count - 1 {
            let width = abs(points[currentPointIndex].x - points[currentPointIndex + 1].x)
            let widthDivisor = width / CGFloat(count)
            let originX = points[currentPointIndex].x + (widthDivisor * CGFloat(columnIndex))
            let point = CGPoint(x: originX, y: points[currentPointIndex].y)
            let height = contentView.frame.maxY - points[currentPointIndex].y
            let path = UIBezierPath(
                rect: CGRect(
                    x: point.x,
                    y: point.y + height,
                    width: width / CGFloat(count),
                    height: 1
                )
            )
            paths.append(path)
        }
        
        return paths
    }
    
    /// createRectangleLayers
    /// - Parameters:
    ///   - points:  [CGPoint]
    ///   - columnIndex: columnIndex
    ///   - count: count
    ///   - color: UIColor
    /// - Returns: [GradientShapeLayer]
    func createRectangleLayers(_ points: [CGPoint],
                               columnIndex: Int,
                               count: Int,
                               color: UIColor) -> [ShapeLinearGradientLayer]
    {
        var layers = [ShapeLinearGradientLayer]()
        for currentPointIndex in 0..<points.count - 1 {
            let width = abs(points[currentPointIndex].x - points[currentPointIndex + 1].x)
            let height = contentView.frame.maxY - points[currentPointIndex].y
            let widthDivisor = width / CGFloat(count)
            let originX = points[currentPointIndex].x + (widthDivisor * CGFloat(columnIndex))
            let point = CGPoint(x: originX, y: points[currentPointIndex].y)
            let path = UIBezierPath(
                rect: CGRect(
                    x: point.x,
                    y: point.y,
                    width: width / CGFloat(count),
                    height: height
                ) // self.frame.maxY - points[currentPointIndex].y - footerViewHeight)
            )
            let rectangleLayer = ShapeLinearGradientLayer()
            rectangleLayer.gardientColor = color
            rectangleLayer.path = path.cgPath
            rectangleLayer.fillColor = color.withAlphaComponent(0.6).cgColor
            rectangleLayer.position = point
            rectangleLayer.strokeColor = color.cgColor
            rectangleLayer.lineWidth = 1
            rectangleLayer.anchorPoint = .zero
            rectangleLayer.shadowColor = UIColor.black.cgColor
            rectangleLayer.shadowOffset = pointsLayersShadowOffset
            rectangleLayer.shadowOpacity = 0.7
            rectangleLayer.shadowRadius = 3.0
            rectangleLayer.opacity = 0.0
            rectangleLayer.bounds = rectangleLayer.path!.boundingBoxOfPath
            layers.insert(rectangleLayer, at: currentPointIndex)
        }
        return layers
    }
    
    /// createSegmentLayers
    /// - Parameters:
    ///   - segmentsPaths: [UIBezierPath]
    ///   - lineWidth: lineWidth
    ///   - color: UIColor
    ///   - strokeColor: UIColor
    /// - Returns: [GradientShapeLayer]
    func createSegmentLayers(_ segmentsPaths: [UIBezierPath],
                             _ lineWidth: CGFloat = 0.5,
                             _ gardientColor: UIColor = .black,
                             _ fillColor: UIColor? = .clear,
                             _ strokeColor: UIColor? = nil) -> [ShapeLinearGradientLayer]
    {
        var layers = [ShapeLinearGradientLayer]()
        for currentPointIndex in 0..<segmentsPaths.count - 1 {
            let path = segmentsPaths[currentPointIndex]
            let shapeSegmentLayer = ShapeLinearGradientLayer()
            shapeSegmentLayer.gardientColor = gardientColor
            shapeSegmentLayer.path = path.cgPath
            shapeSegmentLayer.position = path.bounds.origin
            shapeSegmentLayer.strokeColor = strokeColor?.cgColor
            shapeSegmentLayer.fillColor = fillColor?.cgColor
            shapeSegmentLayer.lineWidth = lineWidth
            shapeSegmentLayer.anchorPoint = .zero
            shapeSegmentLayer.lineCap = .round
            shapeSegmentLayer.lineJoin = .round
            shapeSegmentLayer.opacity = 1.0
            shapeSegmentLayer.bounds = shapeSegmentLayer.path!.boundingBoxOfPath
            layers.insert(shapeSegmentLayer, at: currentPointIndex)
        }
        return layers
    }
    
    /// createSegmentLayers
    /// - Parameters:
    ///   - lineWidth: lineWidth description
    ///   - gardientColor: gardientColor description
    ///   - fillColor: fillColor description
    ///   - strokeColor: strokeColor description
    /// - Returns: description
    func createSegmentLayers(_ lineWidth: CGFloat = 0.5,
                             _ gardientColor: UIColor = .red,
                             _ fillColor: UIColor = .black,
                             _ strokeColor: UIColor? = .black) -> [GradientShapeLayer] {
        return self.createSegmentLayers(self.polylineSubpaths,
                                        lineWidth,
                                        gardientColor,
                                        fillColor, strokeColor)
    }
}
