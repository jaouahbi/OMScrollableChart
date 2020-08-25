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
    func selectNearestRenderLayer( from point: CGPoint, renderIndex: Int) {
        /// Select the last point if the render is not hidden.
        guard let lastPoint = locationToNearestLayer(point,
                                                     renderIndex: renderIndex) else {
                                                        return
        }
        selectRenderLayerWithAnimation(lastPoint,
                                       selectedPoint: point,
                                       renderIndex: renderIndex)
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
    func didSelectedRenderLayerIndex(_ dataIndex: Int) {
        if let footer = footerRule as? OMScrollableChartRuleFooter,
            let views = footer.views {
            if dataIndex < views.count {
                views[dataIndex].shakeGrow(duration: 1.0)
            } else {
                print("section out of bounds")
            }
        }
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
                                        renderIndex: Int) {
        // selectRenderLayer(layerPoint, renderIndex: renderIndex)
        
        if animatePointLayers {
            animateOnRenderLayerSelection(layerPoint,
                                          renderIndex: renderIndex)
        }
        var tooltipPosition    = CGPoint.zero
        var tooltipPositionFix = CGPoint.zero
        if animation {
            tooltipPositionFix = layerPoint.position
        }
        // Get the selection data index
        if let dataIndex = dataIndexFromPoint(layerPoint.position,
                                              renderIndex: renderIndex) {
            // notify the selection
            didSelectedRenderLayerIndex(dataIndex)
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
                tooltip.displayTooltip(tooltipPosition)
            } else {
                                                                    // then calculate manually
                let amount = Double(dataPointsRender[renderIndex][dataIndex])
                if let dataString = currencyFormatter.string(from: NSNumber(value: amount)) {
                    tooltip.string = "\(dataSection) \(dataString)"
                } else if let string = dataStringFromPoint(layerPoint.position, renderIndex: renderIndex) {
                    tooltip.string = "\(dataSection) \(string)"
                } else {
                    print("unexpected")
                }
                tooltip.displayTooltip(tooltipPosition)
            }
        }
        if animation {
            let distance = tooltipPositionFix.distance(to: tooltipPosition)
            let factor: TimeInterval = TimeInterval(1 / (self.contentView.bounds.height / distance))
            
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
                if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                    return  currentStep
                }
            }
        } else {
            if let render = discreteData[renderIndex],
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
        return nil
    }
    func dataIndexFromPoint(_ point: CGPoint, renderIndex: Int) -> Int? {
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
        
        let result = dataIndexFromLayers(point, renderIndex: renderIndex)
        return result
    }
    func dataIndexFromLayers(_ point: CGPoint, renderIndex: Int) -> Int? {
        if self.renderType[renderIndex] == .averaged {
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
