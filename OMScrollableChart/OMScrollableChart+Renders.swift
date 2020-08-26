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
//  OMScrollableChart+Shapes.swift
//  CanalesDigitalesGCiOS
//
//  Created by Jorge Ouahbi on 16/08/2020.
//  Copyright © 2020 Banco Caminos. All rights reserved.
//

import UIKit

extension OMScrollableChart {
    
    // Render the internal layers:
    // 0 - Polyline
    // 1 - Discrete points
    private func renderDefaultLayers(_ renderIndex: Int, points: [CGPoint]) -> [OMGradientShapeClipLayer] {
        switch renderIndex {
        case OMScrollableChart.Renders.polyline.rawValue:
            let lineWidth: CGFloat = 4
            let color  = UIColor.greyishBlue
            let layers = updatePolylineLayer(lineWidth: lineWidth, color: color)
            layers.forEach({$0.name = "polyline"})
            return layers
        case OMScrollableChart.Renders.points.rawValue:
            let pointSize = CGSize(width: 8, height: 8)
            let layers = createPointsLayers(points,
                                            size: pointSize,
                                            color: .greyishBlue)
            layers.forEach({$0.name = "point"})
            return layers
        default:
            return []
        }
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
        polylineLayer.strokeColor   = self.lineColor.withAlphaComponent(0.8).cgColor
        polylineLayer.lineWidth     = self.lineWidth
        polylineLayer.shadowColor   = UIColor.black.cgColor
        polylineLayer.shadowOffset  = CGSize(width: 0, height:  self.lineWidth * 2)
        polylineLayer.shadowOpacity = 0.5
        polylineLayer.shadowRadius  = 6.0
        // Update the frame
        polylineLayer.frame         = contentView.bounds
        
        return [polylineLayer]
    }
    fileprivate func makeApproximation(_ data: [Float], _ renderIndex: Int, _ dataSource: OMScrollableChartDataSource) {
        if let discreteData = makeRawPoints(data: data, size: contentSize, renderIndex: renderIndex) {
            if let approximationData = makeApproximationPoints( data: discreteData, size: contentSize) {
                self.approximationData.insert(approximationData, at: renderIndex)
                self.pointsRender.insert(approximationData.0, at: renderIndex)
                var layers = dataSource.dataLayers(chart: self, renderIndex: renderIndex, section: 0, points: approximationData.0)
                // accumulate layers
                if layers.isEmpty {
                    layers = renderDefaultLayers(renderIndex,
                                                 points: approximationData.0)
                }
                
                self.renderLayers.insert(layers, at: renderIndex)
            }
        }
    }
    
    fileprivate func makeAverage(_ data: [Float], _ renderIndex: Int, _ dataSource: OMScrollableChartDataSource) {
        if let averagedData = makeAveragedPoints(data: data, size: contentSize, renderIndex: renderIndex) {
            self.averagedData.insert(averagedData, at: renderIndex)
            self.pointsRender.insert(averagedData.0, at: renderIndex)
            var layers = dataSource.dataLayers(chart: self,
                                               renderIndex: renderIndex,
                                               section: 0, points: averagedData.0)
            // accumulate layers
            if layers.isEmpty {
                layers = renderDefaultLayers(renderIndex,
                                             points: averagedData.0)
            }
            // accumulate layers
            self.renderLayers.insert(layers, at: renderIndex)
        }
    }
    
    fileprivate func makeDiscrete(_ data: [Float], _ renderIndex: Int, _ dataSource: OMScrollableChartDataSource) {
        //                      let linregressData = makeLinregressPoints(data: discreteData,
        //                                                                size: contentSize,
        //                                                                numberOfElements: 1)
        if let discreteData = makeRawPoints(data: data, size: contentSize, renderIndex: renderIndex) {
            self.discreteData.insert(discreteData, at: renderIndex)
            self.pointsRender.insert(discreteData.0, at: renderIndex)
            
            var layers = dataSource.dataLayers(chart: self,
                                               renderIndex: renderIndex,
                                               section: 0,
                                               points: discreteData.0)
            //  use the private
            if layers.isEmpty {
                layers = renderDefaultLayers(renderIndex,
                                             points: discreteData.0)
            }
            // accumulate layers
            self.renderLayers.insert(layers, at: renderIndex)
        }
    }
    
    fileprivate func makeLinregress(_ data: [Float], _ renderIndex: Int, _ dataSource: OMScrollableChartDataSource) {
        if let discreteData = makeRawPoints(data: data, size: contentSize, renderIndex: renderIndex) {
            let linregressData = makeLinregressPoints(data: discreteData, size: contentSize,numberOfElements: discreteData.0.count + 1, renderIndex: renderIndex)
            self.linregressData.insert(linregressData, at: renderIndex)
            self.pointsRender.insert(linregressData.0, at: renderIndex)
            var layers = dataSource.dataLayers(chart: self, renderIndex: renderIndex,section: 0, points: linregressData.0)
            // accumulate layers
            if layers.isEmpty {
                layers = renderDefaultLayers(renderIndex,
                                             points: linregressData.0)
            }
            
            // accumulate layers
            self.renderLayers.insert(layers, at: renderIndex)
        }
    }
    
    func renderLayers(_ renderIndex: Int,
                      renderAs: OMScrollableChart.RenderData) {
        guard let dataSource = dataSource else {
            return
        }
        let data = dataPointsRender[renderIndex]
        switch renderAs {
        case .approximation:
            makeApproximation(data, renderIndex, dataSource)
        case .averaged:
            makeAverage(data, renderIndex, dataSource)
        case .discrete:
            makeDiscrete(data, renderIndex, dataSource)
        case .linregress:
            makeLinregress(data, renderIndex, dataSource)
        }
        
        self.renderType.insert(renderAs, at: renderIndex)
        
    }
    
    func createPointsLayers( _ points: [CGPoint],
                             size: CGSize,
                             color: UIColor) -> [OMShapeLayerRadialGradientClipPath] {
        var layers =  [OMShapeLayerRadialGradientClipPath]()
        for point in points {
            let circleLayer = createPointLayer(point, size: size, color: color)
            layers.append(circleLayer)
        }
        return layers
    }
    
    func createPointLayer( _ point: CGPoint,
                           size: CGSize,
                           color: UIColor) -> OMShapeLayerRadialGradientClipPath {
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
    
}
