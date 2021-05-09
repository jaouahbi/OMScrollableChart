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
//  OMScrollableChart+Selection.swift
//
//  Created by Jorge Ouahbi on 22/08/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

extension OMScrollableChart {
    /// selectNearestRenderLayer
    /// - Parameters:
    ///   - point: point
    ///   - renderIndex: render index
    func selectNearestRenderLayer( from point: CGPoint, renderIndex: Int) {
        /// Select the last point if the render is not hidden.
        guard let lastPoint = locationToLayer(point,
                                              renderIndex: renderIndex,
                                              mostNearLayer: true) else {
            return
        }
        selectRenderLayerWithAnimation(lastPoint,
                                       selectedPoint: point,
                                       renderIndex: renderIndex)
    }
    /// selectRenderLayer
    /// - Parameters:
    ///   - layer: layer
    ///   - renderIndex: Int
    func selectRenderLayer(_ layer: OMGradientShapeClipLayer, renderIndex: Int) {
        let allUnselectedRenderLayers = self.renderLayers[renderIndex].filter { $0 != layer }
        print("allUnselectedRenderLayers = \(allUnselectedRenderLayers.count)")
        allUnselectedRenderLayers.forEach { (layer: OMGradientShapeClipLayer) in
            layer.gardientColor = self.unselectedColor
            layer.opacity      = self.unselectedOpacy
        }
        layer.gardientColor = self.selectedColor
        layer.opacity   = self.selectedOpacy
    }
    /// locationToLayer
    /// - Parameters:
    ///   - location: CGPoint
    ///   - renderIndex: renderIndex
    ///   - mostNearLayer: Bool
    /// - Returns: OMGradientShapeClipLayer
    func locationToLayer( _ location: CGPoint, renderIndex: Int, mostNearLayer: Bool = true) -> OMGradientShapeClipLayer? {
        let mapped = renderLayers[renderIndex].map {
            return $0.frame.origin.distance(from: location)
        }
        if mostNearLayer {
            guard let index = mapped.indexOfMin else {
                return nil
            }
            return renderLayers[renderIndex][index]
        } else {
            guard let index = mapped.indexOfMax else {
                return nil
            }
            return renderLayers[renderIndex][index]
        }
    }
    /// hitTestAsLayer
    /// - Parameter location: <#location description#>
    /// - Returns: CALayer
    func hitTestAsLayer( _ location: CGPoint) -> CALayer? {
        if let layer = contentView.layer.hitTest(location) { // If you hit a layer and if its a Shapelayer
            return layer
        }
        return nil
    }
    /// didSelectedRenderLayerIndex
    /// - Parameters:
    ///   - layer: <#layer description#>
    ///   - renderIndex: Int
    ///   - dataIndex: Int
    func didSelectedRenderLayerIndex(layer: CALayer, renderIndex: Int, dataIndex: Int) {
        // lets animate the footer rule
        if let footer = footerRule as? OMScrollableChartRuleFooter,
            let views = footer.views {
            if dataIndex < views.count {
                views[dataIndex].shakeGrow(duration: 1.0)
            } else {
                print("Section index is out of bounds", dataIndex, views.count)
            }
        }
        renderDelegate?.didSelectDataIndex(chart: self,
                                        renderIndex: renderIndex,
                                        dataIndex: dataIndex,
                                        layer: layer)
    }
    /// selectRenderLayerWithAnimation
    /// - Parameters:
    ///   - layerPoint: OMGradientShapeClipLayer
    ///   - selectedPoint: CGPoint
    ///   - animation: Bool
    ///   - renderIndex: Int
    func selectRenderLayerWithAnimation(_ layerPoint: OMGradientShapeClipLayer,
                                        selectedPoint: CGPoint,
                                        animation: Bool = false,
                                        renderIndex: Int,
                                        duration: TimeInterval = 0.5) {
        
        CATransaction.lock()
        CATransaction.setAnimationDuration(duration)
        CATransaction.begin()

        
        // selectRenderLayer(layerPoint, renderIndex: renderIndex)
        
        if animatePointLayers {
            self.animateOnRenderLayerSelection(layerPoint,
                                          renderIndex: renderIndex,
                                          duration: duration)
        }
        var tooltipPosition = CGPoint.zero
        var tooltipPositionFix = CGPoint.zero
        if animation {
            tooltipPositionFix = layerPoint.position
        }
        // Get the selection data index
        if let dataIndex = dataIndexFromPoint(layerPoint.position,
                                              renderIndex: renderIndex) {
            
            print("Selected item: \(dataIndex)")
            //self.polylinePath?.cgPath.elementsPoints()
            // notify the selection
            didSelectedRenderLayerIndex(layer: layerPoint,
                                        renderIndex: renderIndex,
                                        dataIndex: dataIndex)
            // grab the tool tip text
            let tooltipText = dataSource?.dataPointTootipText(chart: self,
                                                              renderIndex: renderIndex,
                                                              dataIndex: dataIndex,
                                                              section: 0)
            // grab the section
            let dataSection = dataSource?.dataSectionForIndex(chart: self,
                                                              dataIndex: dataIndex,
                                                              section: 0) ?? ""
            tooltipPosition = CGPoint(x: layerPoint.position.x,
                                      y: selectedPoint.y)
        
            if let tooltipText = tooltipText {                      // the dataSource was priority
                tooltip.string = "\(dataSection) \(tooltipText)"
                tooltip.displayTooltip(tooltipPosition, duration: duration)
            } else {
                                                                    // then calculate manually
                let amount = Double(renderDataPoints[renderIndex][dataIndex])
                if let dataString = currencyFormatter.string(from: NSNumber(value: amount)) {
                    tooltip.string = "\(dataSection) \(dataString)"
                } else if let string = dataStringFromPoint(layerPoint.position, renderIndex: renderIndex) {
                    tooltip.string = "\(dataSection) \(string)"
                } else {
                    print("FIXME: unexpected render | data \(renderIndex) | \(dataIndex)")
                }
                tooltip.displayTooltip(tooltipPosition, duration: duration)
            }
        }
        if animation {
            let distance = tooltipPositionFix.distance(to: tooltipPosition)
            let factor: TimeInterval = TimeInterval(1 / (self.contentView.bounds.height / distance))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.tooltip.moveTooltip(tooltipPositionFix,
                                         duration: factor * duration)
            }
        }
        CATransaction.commit()
        CATransaction.unlock()
    }
    func locationFromTouchInContentView(_ touches: Set<UITouch>) -> CGPoint {
        if let touch = touches.first {
            return touch.location(in: self.contentView)
        }
        return .zero
    }
    /// indexForPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: Int
    /// - Returns: Int?
    func indexForPoint(_ point: CGPoint, renderIndex: Int) -> Int? {
        let newPoint = CGPoint(x: point.x, y: point.y)
        switch self.renderType[renderIndex] {
        case .discrete:
            return discreteData[renderIndex]?.points.map{ $0.distance(to: newPoint)}.indexOfMin
        case .averaged(_):
            return averagedData[renderIndex]?.points.map{ $0.distance(to: newPoint)}.indexOfMin
        case .approximation(_):
            return approximationData[renderIndex]?.points.map{ $0.distance(to: newPoint)}.indexOfMin
        case .linregress(_):
            return linregressData[renderIndex]?.points.map{ $0.distance(to: newPoint)}.indexOfMin
        }
    }
    /// dataStringFromPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: Int
    /// - Returns: String?
    func dataStringFromPoint(_ point: CGPoint, renderIndex: Int) -> String? {
        switch self.renderType[renderIndex] {
        case .averaged(_):
            if let render = averagedData[renderIndex],
                let firstIndex = indexForPoint(point, renderIndex: renderIndex) {
                let item: Double = Double(render.data[firstIndex])
                if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                    return  currentStep
                }
            }
        case .discrete:
            if let render = discreteData[renderIndex],
                let firstIndex = render.points.firstIndex(of: point) {
                let item: Double = Double(render.data[firstIndex])
                if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                    return currentStep
                }
            }
        case .approximation(_):
            if let render = approximationData[renderIndex],
                let firstIndex = render.points.firstIndex(of: point) {
                let item: Double = Double(render.data[firstIndex])
                if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                    return currentStep
                }
            }
        case .linregress(_):
            if let render = linregressData[renderIndex],
                let firstIndex = render.points.firstIndex(of: point) {
                let item: Double = Double(render.data[firstIndex])
                if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                    return currentStep
                }
            }
        }
        return nil
    }
    func dataFromPoint(_ point: CGPoint, renderIndex: Int) -> Float? {
//        if self.renderType[renderIndex].isAveraged {
//            if let render = discreteData[renderIndex],
//                let firstIndex = indexForPoint(point, renderIndex: renderIndex) {
//                return Float(render.data[firstIndex])
//            }
//        } else {
//            if let render = discreteData[renderIndex],
//                let firstIndex = render.points.firstIndex(of: point) {
//                return Float(render.data[firstIndex])
//            }
//        }
//        return nil
        switch self.renderType[renderIndex] {
        case .discrete:
            if let render = discreteData[renderIndex] {
                if let firstIndex = render.points.firstIndex(of: point) {
                    return render.data[firstIndex]
                }
            }
        case .averaged(_):
            if let render = self.averagedData[renderIndex] {
                if let firstIndex = indexForPoint(point, renderIndex: renderIndex) {
                    return render.data[firstIndex]
                }
            }
        case .approximation(_):
            if let render = self.approximationData[renderIndex] {
                if let firstIndex = render.points.firstIndex(of: point) {
                    return render.data[firstIndex]
                }
            }
        case .linregress(_):
            if let render = self.linregressData[renderIndex] {
                if let firstIndex = render.points.firstIndex(of: point) {
                    return render.data[firstIndex]
                }
            }
        }
        return nil
       // return dataIndexFromLayers(point, renderIndex: renderIndex)
    }
    func dataIndexFromPoint(_ point: CGPoint, renderIndex: Int) -> Int? {
        switch self.renderType[renderIndex] {
        case .discrete:
            if let render = discreteData[renderIndex] {
                if let firstIndex = render.points.firstIndex(of: point) {
                    return firstIndex
                }
            }
        case .averaged(_):
            if let firstIndex = indexForPoint(point, renderIndex: renderIndex) {
                return firstIndex
            }
            
        case .approximation(_):
            if let render = self.approximationData[renderIndex] {
                if let firstIndex = render.points.firstIndex(of: point) {
                    return firstIndex
                }
            }
        case .linregress(_):
            if let render = self.linregressData[renderIndex] {
                if let firstIndex = render.points.firstIndex(of: point) {
                    return firstIndex
                }
            }
        }
        return nil //dataIndexFromLayers(point, renderIndex: renderIndex)
    }
    func dataIndexFromLayers(_ point: CGPoint, renderIndex: Int) -> Int? {
        if self.renderType[renderIndex].isAveraged {
            if let firstIndex = indexForPoint(point, renderIndex: renderIndex) {
                return firstIndex
            }
        } else {
            if let layersPathContains = renderLayers[renderIndex].filter({
                return $0.path!.contains(point)
            }).first {
                return renderLayers[renderIndex].firstIndex(of: layersPathContains)
            }
        }
        return nil
    }
    
}
