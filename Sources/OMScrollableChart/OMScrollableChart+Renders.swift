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

//
//  OMScrollableChart.swift
//
//  Created by Jorge Ouahbi on 16/08/2020.

//

import UIKit

let kDefaultPointSize = CGSize(width: 8, height: 8)
let kDefaultSelectedPointSize = CGSize(width: 13, height: 13)
let kDefaultLineWidth: CGFloat = 4

extension OMScrollableChart {
    // Render the internal layers:
    // 0 - Polyline
    // 1 - Discrete points
    // 2 - Selected point
    private func renderDefaultLayers(_ renderIndex: Int, points: [CGPoint]) -> [OMGradientShapeClipLayer] {
        switch renderIndex {
        case OMScrollableChart.Renders.polyline.rawValue:
            let color = UIColor.greyishBlue
            let layers = self.updatePolylineLayer(lineWidth: kDefaultLineWidth, color: color)
            layers.forEach { $0.name = "polylineDefault" }
            return layers
        case OMScrollableChart.Renders.points.rawValue:
            let layers = self.createPointsLayers(points, size: kDefaultPointSize, color: .greyishBlue)
            layers.forEach { $0.name = "pointDefault" }
            return layers
        case OMScrollableChart.Renders.selectedPoint.rawValue:
            if let point = maxPoint(in: renderIndex) {
                let layer = self.createPointLayer(point, size: kDefaultSelectedPointSize, color: .darkGreyBlueTwo)
                layer.name = "selectedPointDefault"
                return [layer]
            }
        default:
            return []
        }
        return []
    }
    /// Polyline UIBezierPath
    public var polylinePath: UIBezierPath? {
        guard let polylinePoints = polylinePoints,
            let polylinePath = polylineInterpolation.asPath(points: polylinePoints) else {
            print("Unexpected empty polylinePath (UIBezierPath).")
            return nil
        }
        return polylinePath
    }

    ///  Update the polyline UIBezierPath
    /// - Parameters:
    ///   - lineWidth: line width
    ///   - color: color
    /// - Returns: [OMGradientShapeClipLayer]
    public  func updatePolylineLayer(lineWidth: CGFloat, color: UIColor) -> [OMGradientShapeClipLayer] {
        guard let polylinePath = polylinePath else {
            print("Unexpected empty polylinePath (UIBezierPath).")
            return []
        }
        let polylineLayer = OMGradientShapeClipLayer()
        self.lineWidth = lineWidth
        self.lineColor = color
        polylineLayer.path = polylinePath.cgPath
        polylineLayer.fillColor = UIColor.clear.cgColor
        polylineLayer.strokeColor = self.lineColor.withAlphaComponent(0.8).cgColor
        polylineLayer.lineWidth = self.lineWidth
        polylineLayer.shadowColor = UIColor.black.cgColor
        polylineLayer.shadowOffset = CGSize(width: 0, height: self.lineWidth * 2)
        polylineLayer.shadowOpacity = 0.5
        polylineLayer.shadowRadius = 6.0
        // Update the frame
        polylineLayer.frame = contentView.bounds
        return [polylineLayer]
    }
    
    /// makeApproximation
    /// - Parameters:
    ///   - data: [Float]]
    ///   - renderIndex: index
    ///   - dataSource: OMScrollableChartDataSource
    public  func makeApproximation(_ data: [Float], _ renderIndex: Int, _ dataSource: OMScrollableChartDataSource) {
        let discretePoints = makeRawPoints(data, size: contentView.bounds.size)
        if discretePoints.count > 0 {
            let chartData = (discretePoints, data)
            if let approximationPoints = makeApproximationPoints(points: discretePoints,
                                                                 type: self.approximationType,
                                                                 tolerance: approximationTolerance)
            {
                if approximationPoints.count > 0 {
                    self.approximationData.insert(chartData, at: renderIndex)
                    self.pointsRender.insert(approximationPoints, at: renderIndex)
                    var layers = dataSource.dataLayers(chart: self,
                                                       renderIndex: renderIndex,
                                                       section: 0, points: approximationPoints)
                    // accumulate layers
                    if layers.isEmpty {
                        print("Unexpected empty layers, lets use the default renders.")
                        layers = self.renderDefaultLayers(renderIndex, points: approximationPoints)
                    }
                    
                    self.renderLayers.insert(layers, at: renderIndex)
                } else  {
                    print("Unexpected empty approximation points.")
                }
            }
        } else {
            print("Unexpected empty discrete points for approximation.")
        }
    }
    
    /// Make mean points
    /// - Parameters:
    ///   - data: [Float]
    ///   - renderIndex: index
    ///   - dataSource: OMScrollableChartDataSource
    public  func makeMean(_ data: [Float], _ renderIndex: Int, _ dataSource: OMScrollableChartDataSource) {
        if let points = makeMeanPoints(data: data,
                                       size: contentView.bounds.size,
                                       elementsToMean: numberOfElementsToMean)
        {
            let chartData = (points, data)
            self.meanData.insert(chartData, at: renderIndex)
            self.pointsRender.insert(points, at: renderIndex)
            var layers = dataSource.dataLayers(chart: self,
                                               renderIndex: renderIndex,
                                               section: 0,
                                               points: points)
            // accumulate layers
            if layers.isEmpty {
                print("Unexpected empty layers, lets use the default renders.")
                layers = self.renderDefaultLayers(renderIndex, points: points)
            }
            // accumulate layers
            self.renderLayers.insert(layers, at: renderIndex)
        } else {
            print("Unexpected empty mean points.")
        }
    }
    
    /// makeDiscrete points
    /// - Parameters:
    ///   - data: [Float]
    ///   - renderIndex: index
    ///   - dataSource: OMScrollableChartDataSource
    public  func makeDiscrete(_ data: [Float], _ renderIndex: Int, _ dataSource: OMScrollableChartDataSource) {
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
            //  use the private renders
            if layers.isEmpty {
                print("Unexpected empty layers, lets use the default renders.")
                layers = self.renderDefaultLayers(renderIndex,
                                                  points: points)
            }
            // accumulate layers
            self.renderLayers.insert(layers, at: renderIndex)
        } else {
            print("Unexpected empty discrete points (makeRawPoints).")
        }
    }
    
    public  func makeLinregress(_ data: [Float],
                                _ renderIndex: Int,
                                _ dataSource: OMScrollableChartDataSource)
    {
        let points = makeRawPoints(data, size: contentView.bounds.size)
        if points.count > 0 {
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
                print("Unexpected empty layers, lets use the default renders.")
                layers = self.renderDefaultLayers(renderIndex,
                                                  points: linregressData.0)
            }
            
            // accumulate layers
            self.renderLayers.insert(layers, at: renderIndex)
        } else {
            print("Unexpected empty discrete points (makeRawPoints).")
        }
    }
    
    /// Render layers of render ´renderIndex´ as ´OMScrollableChart.RenderType´
    /// - Parameters:
    ///   - renderIndex: render index
    ///   - renderAs: RenderType
    public func renderLayers(_ renderIndex: Int, renderAs: OMScrollableChart.RenderType) {
        guard let dataSource = dataSource else {
            return
        }
        let currentRenderData = renderDataPoints[renderIndex]
        switch renderAs {
        case .approximation: self.makeApproximation(currentRenderData, renderIndex, dataSource)
        case .mean: self.makeMean(currentRenderData, renderIndex, dataSource)
        case .discrete: self.makeDiscrete(currentRenderData, renderIndex, dataSource)
        case .linregress: self.makeLinregress(currentRenderData, renderIndex, dataSource)
        }
        self.renderType.insert(renderAs, at: renderIndex)
    }
    
    /// createPointsLayers
    /// - Parameters:
    ///   - points: [CGPoint]
    ///   - size: CGSize
    ///   - color: UIColor
    /// - Returns:  [OMShapeLayerRadialGradientClipPath]
    public func createPointsLayers(_ points: [CGPoint], size: CGSize, color: UIColor) -> [OMShapeLayerRadialGradientClipPath] {
        return points.map { createPointLayer($0, size: size, color: color) }
    }
    
    /// Create a point layer
    /// - Parameters:
    ///   - point: CGPoint
    ///   - size: CGSize
    ///   - color: UIColor
    /// - Returns: OMShapeLayerRadialGradientClipPath
    public  func createPointLayer(_ point: CGPoint, size: CGSize, color: UIColor) -> OMShapeLayerRadialGradientClipPath {
        let circleLayer = OMShapeLayerRadialGradientClipPath()
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
        circleLayer.shadowOffset = pointsLayersShadowOffset
        circleLayer.shadowOpacity = 0.7
        circleLayer.shadowRadius = 3.0
        circleLayer.isHidden = false
        circleLayer.bounds = circleLayer.path!.boundingBoxOfPath
        
        return circleLayer
    }
    
    /// createInverseRectanglePaths
    /// - Parameters:
    ///   - points: [CGPoint]
    ///   - columnIndex: columnIndex
    ///   - count: count
    /// - Returns: [UIBezierPath]
    public  func createInverseRectanglePaths(_ points: [CGPoint],
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
    /// - Returns: [OMGradientShapeClipLayer]
    public  func createRectangleLayers(_ points: [CGPoint],
                               columnIndex: Int,
                               count: Int,
                               color: UIColor) -> [OMGradientShapeClipLayer]
    {
        var layers = [OMGradientShapeClipLayer]()
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
            let rectangleLayer = OMShapeLayerLinearGradientClipPath()
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
            rectangleLayer.isHidden = false
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
    /// - Returns: [OMGradientShapeClipLayer]
    public  func createSegmentLayers(_ segmentsPaths: [UIBezierPath], lineWidth: CGFloat = 1.0, color: UIColor = .red, strokeColor: UIColor = .black) -> [OMGradientShapeClipLayer] {
        var layers = [OMGradientShapeClipLayer]()
        for currentPointIndex in 0..<segmentsPaths.count - 1 {
            let path = segmentsPaths[currentPointIndex]
            let shapeSegmentLayer = OMShapeLayerLinearGradientClipPath()
            shapeSegmentLayer.gardientColor = color
            shapeSegmentLayer.path = path.cgPath
            shapeSegmentLayer.position = path.bounds.origin
            shapeSegmentLayer.strokeColor = strokeColor.cgColor
            shapeSegmentLayer.fillColor = nil
            shapeSegmentLayer.lineWidth = lineWidth
            shapeSegmentLayer.anchorPoint = .zero
            shapeSegmentLayer.lineCap = .round
            shapeSegmentLayer.lineJoin = .round
            shapeSegmentLayer.isHidden = false
            shapeSegmentLayer.bounds = shapeSegmentLayer.path!.boundingBoxOfPath
            layers.insert(shapeSegmentLayer, at: currentPointIndex)
        }
        return layers
    }
}
