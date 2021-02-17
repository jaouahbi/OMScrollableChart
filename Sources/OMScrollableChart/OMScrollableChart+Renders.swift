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
import LibControl

struct ScrollableRendersConfiguration {
    static let defaultPointSize = CGSize(width: 8, height: 8)
    static let defaultPathPointSize = CGSize(width: 10, height: 10)
    static let defaultSelectedPointSize = CGSize(width: 13, height: 13)
    static let defaultLineWidth: CGFloat = 4
    static let animationPointsClearOpacityKey: String = "animationPointsClearOpacityKey"
}

extension OMScrollableChart {
    /// makeApproximation
    /// - Parameters:
    ///   - data: [Float]]
    ///   - renderIndex: index
    ///   - dataSource: OMScrollableChartDataSource
    public func makeScalePointsSimplifyAndLayers( _ render: BaseRender,
                             _ size: CGSize,
                             _ simplifyType: SimplifyType,
                             _ tol: CGFloat) {
        let points = render.makePoints(size)
        if points.count > 0 {
            if let simplifyPoints = simplifyPoints(points: points,
                                                   type: simplifyType,
                                                   tolerance: tol) {
                // remove the index from data
                let difference = simplifyPoints.difference(from: points)
                var diffedData = render.data.data.map({$0})
                for change in difference {
                    switch change {
                    case let .remove(offset, _, _):
                        diffedData.remove(at: offset)
                    case let .insert(_, _, _): break
                    //diffedData.insert(newElement, at: offset)
                    }
                }
                let data = DataRender(data: diffedData, points: simplifyPoints )
                render.data = data
                if simplifyPoints.count > 0 {
                    var layers = dataSource?.dataLayers(chart: self,
                                                       renderIndex: render.index,
                                                       section: 0,
                                                       data: data) ?? []
                    // accumulate layers
                    if layers.isEmpty {
                        print("Unexpected empty layers, lets use the default renders.")
                        layers = self.renderDefaultLayers(render, data: data)
                    }
                    render.layers.append(contentsOf: layers)
                } else  {
                    print("Unexpected empty simplify points.")
                }
            }
        } else {
            print("Unexpected empty discrete points for simplify.")
        }
    }
    
    
    /// Make mean points
    /// - Parameters:
    ///   - data: [Float]
    ///   - renderIndex: index
    ///   - dataSource: OMScrollableChartDataSource
    public func makeStadisticsScaledPointsAndLayers(
                
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
                              }
        )
        if renderData.points.count > 0 {
            var layers = dataSource?.dataLayers(chart: self,
                                               renderIndex: render.index,
                                               section: 0,
                                               data: renderData) ?? []
            // accumulate layers
            if layers.isEmpty {
                print("Unexpected empty render layers, let's use the default renders.")
                layers = self.renderDefaultLayers(render, data: renderData)
            }
            render.data = renderData
            render.layers.append( contentsOf: layers)
        } else {
            print("Unexpected empty points.")
        }
    }
    

    
    /// makeDiscrete points
    /// - Parameters:
    ///   - data: [Float]
    ///   - renderIndex: index
    ///   - dataSource: OMScrollableChartDataSource
    public func makeDiscreteScalePointsAndLayers(_ render: BaseRender,
                             _ size: CGSize) {
        let points = render.makePoints(size)
        if points.count > 0 {
            print("making render \(render.index) layers.")
            let datRebuilded = DataRender(data: render.data.data, points: points)
            var layers = dataSource?.dataLayers(chart: self,
                                               renderIndex: render.index,
                                               section: 0,
                                               data: datRebuilded) ?? []
            render.data = datRebuilded
            //  use the default renders
            if layers.isEmpty {
                print("Unexpected empty layers render \(render.index), lets use the default renders.")
                layers = self.renderDefaultLayers(render, data: datRebuilded)
            }
            // accumulate layers
            print("Accumulating \(layers.count) layers.")
            render.layers.append(contentsOf: layers)
        } else {
            print("Unexpected empty discrete points (makeRawPoints).")
        }
    }
    
    public func makeLinregressScaledPointsAndLayers( _ render: BaseRender,
                               _ size: CGSize,
                               _ numberOfElements: Int)
    {
        let points = render.makePoints(size)
        if points.count > 0 {
            let chartData = DataRender( data: render.data.data, points: points)
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
                print("Unexpected empty layers render \(render.index), lets use the default renders.")
                layers = self.renderDefaultLayers(render,
                                                  data: linregressData)
            }
            // accumulate layers
            print("Accumulating \(layers.count) layers.")
            render.layers.append(contentsOf: layers)
        } else {
            print("Unexpected empty discrete points (makeRawPoints).")
        }
    }
}
// MARK: - Renders -

extension OMScrollableChart {
    // Render the internal layers:
    // 0 - Polyline
    // 1 - Discrete points
    // 2 - Selected point
    internal func renderDefaultLayers(_ render: BaseRender, data: DataRender) -> [GradientShapeLayer] {
        switch render.index {
        case RenderIdent.polyline.rawValue:
            // let color = UIColor.greyishBlue
            let layers = self.updatePolylineLayer()
            #if DEBUG
            if layers.first?.name == nil {
                layers.forEach { $0.name = "polylineDefault" }
            }
            #endif
            return layers
        case RenderIdent.points.rawValue:
            let layers = self.createPointsLayers(data.points,
                                                 size: ScrollableRendersConfiguration.defaultPointSize,
                                                 color: lineColor)
            
            #if DEBUG
            if layers.first?.name == nil {
                layers.enumerated().forEach { $1.name = "pointDefault \($0)" }
            }
            #endif
            return layers
        case RenderIdent.selectedPoint.rawValue:
            if let point = render.data.maxPoint {
                let layer = self.createPointLayer(point, size: ScrollableRendersConfiguration.defaultSelectedPointSize,
                                                  color: selectedPointColor, shadowOffset: pointsLayersShadowOffset)
                #if DEBUG
                layer.name = "selectedPointDefault"
                #endif
                return [layer]
            }
        default:
            return []
        }
        return []
    }
    
    /// Polyline UIBezierPath
    public var polylineSubpaths: [UIBezierPath] {
        guard let polylinePath = polylinePath else {
            print("Unexpected empty polylinePath (UIBezierPath).")
            return []
        }
        return polylinePath.cgPath.subpaths
    }
    
    /// Polyline UIBezierPath
    /// TODO: cache???
    public var polylinePath: UIBezierPath? {
        let polylinePoints = RenderManager.shared.polyline.data.points
        guard  let polylinePath = polylineInterpolation.asPath(points: polylinePoints) else {
            print("Unexpected empty polylinePath (UIBezierPath).")
            return nil
        }
        return polylinePath
    }
    
    /// updatePolylinePath
    /// - Parameter polylinePath: UIBezierPath
    private func updatePolylinePath(_ polylinePath: UIBezierPath) {
        // update path
        polylineLayer.path = polylinePath.cgPath
        polylineLayerPathDidChange(layer: polylineLayer)
    }
    
    ///  Update the polyline layer with UIBezierPath, strokeColor, lineWidth
    ///  TODO: complete the shadow.
    /// - Returns: [GradientShapeLayer]
    public  func updatePolylineLayer() -> [GradientShapeLayer] {
        guard let polylinePath = polylinePath else {
            print("Unexpected empty polylinePath (UIBezierPath).")
            return []
        }
        
        updatePolylinePath(polylinePath)
        
        polylineLayer.fillColor = UIColor.clear.cgColor
        polylineLayer.strokeColor = (self.strokeLineColor ?? self.lineColor.withAlphaComponent(0.8)).cgColor
        polylineLayer.lineWidth = self.lineWidth
        polylineLayer.shadowColor = UIColor.black.cgColor
        polylineLayer.shadowOffset = CGSize(width: 0, height: self.lineWidth * 2)
        polylineLayer.shadowOpacity = 0.5
        polylineLayer.shadowRadius = 6.0
        // Update the frame
        polylineLayer.frame = contentView.bounds
        return [polylineLayer]
    }
    

    /// Render layers of render ´renderIndex´ as ´OMScrollableChart.RenderType´
    /// - Parameters:
    ///   - renderIndex: render index
    ///   - renderAs: RenderDataType
    private func renderLayers(from renderIndex: Int, size: CGSize, renderAs: RenderDataType) {
        guard renderIndex <= renderSourceNumberOfRenders else {
            print("Unexpected out of renderIndex.")
            return
        }
        // get the data points
        let render = RenderManager.shared.renders[renderIndex]
        switch renderAs {
        case .discrete:
            self.makeDiscreteScalePointsAndLayers(render, size)
        case .simplify(let type, let tol):
            self.makeScalePointsSimplifyAndLayers(render, size, type, tol)
        case .stadistics(let elements):
            self.makeStadisticsScaledPointsAndLayers( render, size, elements)
        case .regress(let elements):
            self.makeLinregressScaledPointsAndLayers(render, size, elements)
        }
        // Update the type if needed.
        if render.data.dataType != renderAs {
            render.data = DataRender(data: render.data.data,
                                     points: render.data.points,
                                     type: renderAs )
        }
    }
    
    /// renderLayers
    /// - Parameters:
    ///   - render: render description
    ///   - size: size description
    public func renderLayers(with render: BaseRender, size: CGSize) {
        // get the data poiunt
        switch render.data.dataType {
        case .discrete:
            self.makeDiscreteScalePointsAndLayers(render, size)
        case .simplify(let type, let tol):
            self.makeScalePointsSimplifyAndLayers(render, size, type, tol)
        case .stadistics(let elements):
            self.makeStadisticsScaledPointsAndLayers( render, size, elements)
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
    public func createPointsLayers(_ points: [CGPoint], size: CGSize, color: UIColor) -> [ShapeRadialGradientLayer] {
        return points.map { createPointLayer($0,
                                             size: size,
                                             color: color,
                                             shadowOffset: pointsLayersShadowOffset) }
    }
    
    /// Create a point layer
    /// - Parameters:
    ///   - point: CGPoint
    ///   - size: CGSize
    ///   - color: UIColor
    /// - Returns: ShapeRadialGradientLayer
    public  func createPointLayer(_ point: CGPoint, size: CGSize, color: UIColor, shadowOffset: CGSize) -> ShapeRadialGradientLayer {
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
        circleLayer.opacity =  0.0
        circleLayer.bounds = circleLayer.path!.boundingBoxOfPath
        
        return circleLayer
    }
    
    /// createInverseRectanglePaths
    /// - Parameters:
    ///   - points: [CGPoint]
    ///   - columnIndex: columnIndex
    ///   - count: count
    /// - Returns: [UIBezierPath]
    public func createInverseRectanglePaths(_ points: [CGPoint],
                                            columnIndex: Int,
                                            count: Int) -> [UIBezierPath]
    {
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
    public func createRectangleLayers(_ points: [CGPoint],
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
    public func createSegmentLayers(_ segmentsPaths: [UIBezierPath],
                                    _ lineWidth: CGFloat = 0.5,
                                    _ gardientColor: UIColor = .red,
                                    _ fillColor: UIColor? = .black,
                                    _ strokeColor: UIColor? = nil) -> [ShapeLinearGradientLayer] {
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
    
    public func createSegmentLayers( _ lineWidth: CGFloat = 0.5,
                                     _ gardientColor: UIColor = .red,
                                     _ fillColor: UIColor = .black,
                                     _ strokeColor: UIColor? = .black) -> [GradientShapeLayer] {
        return createSegmentLayers(polylineSubpaths, lineWidth,  gardientColor, fillColor,strokeColor)
    }
}
