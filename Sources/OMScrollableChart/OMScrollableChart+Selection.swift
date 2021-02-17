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
import LibControl

extension OMScrollableChart {
    /// selectNearestRenderLayer
    /// - Parameters:
    ///   - renderIndex: render index
    ///   - point: point
    func selectNearestRenderLayer(_ renderIndex: Int, point: CGPoint ) {
        /// Select the last point if the render is not hidden.
        selectNearestRenderLayer( RenderManager.shared.renders[renderIndex], point: point)
    }
    
    func selectNearestRenderLayer(_ render: BaseRender, point: CGPoint ) {
        /// Select the last point if the render is not hidden.
      
        guard let layer = render.locationToLayer(point) else {
            return
        }
        self.selectRenderLayerWithAnimation(render,
                                            layer,
                                            point)
    }
    
    
    /// selectRenderLayer
    /// - Parameters:
    ///   - layer: layer
    ///   - renderIndex: Int
    func selectRenderLayers(render: BaseRender, layer: OMGradientShapeClipLayer) -> OMGradientShapeClipLayer {
        let unselected = render.allOtherLayers(layer: layer)
        print("allUnselectedRenderLayers = \(unselected.count)")
        unselected.forEach { (layer: OMGradientShapeClipLayer) in
            layer.gardientColor = self.unselectedColor
            layer.opacity = self.unselectedOpacy
        }
        layer.gardientColor = self.selectedColor
        layer.opacity = self.selectedOpacy
        print("Selected Render Layers = \(layer.name)")
        return layer
    }

    /// Get the layer in the point using render
    /// - Parameters:v
    ///   - location: CGPoint
    ///   - renderIndex: renderIndex
    ///   - mostNearLayer: Bool
    /// - Returns: OMGradientShapeClipLayer
//    func locationToLayer(_ renderIndex: Int, location: CGPoint, mostNearLayer: Bool = true) -> OMGradientShapeClipLayer? {
//
//        let xlayers = RenderManager.shared.layers[renderIndex]
//        let mapped = xlayers.map {  (layer: CALayer) in
//            layer.frame.origin.distance(location)
//        }
//        if mostNearLayer {
//            guard let index = mapped.mini else {
//                return nil
//            }
//            return xlayers[index]
//        } else {
//            guard let index = mapped.maxi else {
//                return nil
//            }
//            return xlayers[index]
//        }
//    }
    
    /// hitTestAsLayer
    /// - Parameter location: location description
    /// - Returns: CALayer
    func hitTestAsLayer(_ location: CGPoint) -> CALayer? {
        if let layer = contentView.layer.hitTest(location) { // If you hit a layer and if its a Shapelayer
            return layer
        }
        return nil
    }
    
    func performFooterRuleAnimation(_ sectionIndex: Int) -> Bool {
        guard numberOfSections > 0 else {
            return false
        }
        if let footer = ruleManager.footerRule as? OMScrollableChartRuleFooter,
           let sectionsViews = footer.views {
            print("circular section index", sectionIndex % numberOfSections)
            // shake section view at safe index
            sectionsViews[sectionIndex % numberOfSections].shakeGrow(duration: 1.0)
        }
        return true
    }
    
    /// didSelectedRenderLayerIndex
    /// - Parameters:
    ///   - layer: CALayer
    ///   - renderIndex: Int
    ///   - dataIndex: Int
    func didSelectedRenderLayerSection(_ renderIndex: Int, sectionIndex: Int, layer: CALayer) {
        // lets animate the footer rule
        if isFooterRuleAnimated {
            if !performFooterRuleAnimation(sectionIndex) {
                print("Unable to animate section \(sectionIndex) render: \(renderIndex) layer: \(layer.name ?? "unnamed")")
            }
        }
        guard let delegate = renderDelegate else {return }
        delegate.didSelectSection(chart: self,
                                         renderIndex: renderIndex,
                                         sectionIndex: sectionIndex,
                                         layer: layer)
    }
    
    /// didSelectedRenderLayerIndex
    /// - Parameters:
    ///   - renderIndex: renderIndex description
    ///   - dataIndex: dataIndex description
    ///   - layer: layer description
    func didSelectedRenderLayerIndex(_ renderIndex: Int, dataIndex: Int, layer: CALayer) {
        assert(renderIndex < RenderManager.shared.renders.count)
        renderDelegate?.didSelectDataIndex(chart: self,
                                           renderIndex: renderIndex,
                                           dataIndex: dataIndex,
                                           layer: layer)
    }
    fileprivate func calculateManually(_ render: BaseRender, _ dataIndex: Int, _ dataSection: String, _ layerPoint: OMGradientShapeClipLayer) {
        // then calculate manually
        let amount: Double = Double(render.data.data[dataIndex])
        if let dataString = currencyFormatter.string(from: NSNumber(value: amount)) {
            tooltip.string = "\(dataSection) \(dataString)"
        } else if let string = dataStringFromPoint(render.index, point: layerPoint.position) {
            tooltip.string = "\(dataSection) \(string)"
        } else {
            print("FIXME: unexpected render | data \(render.index) | \(dataIndex)")
        }
    }
    
    /// Build the tooltip text to show.
    /// - Parameters:
    ///   - renderIndex: Index
    ///   - dataIndex: data index
    ///   - tooltipPosition: CGPoint
    ///   - layerPoint: layer point
    ///   - selectedPoint: selected point
    ///   - duration: TimeInterval
    private func buildTooltipText(_ render: BaseRender,
                                  _ dataIndex: Int,
                                  _ tooltipPosition: inout CGPoint,
                                  _ layerPoint: OMGradientShapeClipLayer,
                                  _ selectedPoint: CGPoint,
                                  _ duration: TimeInterval)
    {
        // grab the tool tip text
        let tooltipText = dataSource?.dataPointTootipText(chart: self,
                                                          renderIndex: render.index,
                                                          dataIndex: dataIndex,
                                                          section: 0)
        // grab the section string
        let dataSection = dataSource?.dataSectionForIndex(chart: self,
                                                          dataIndex: dataIndex,
                                                          section: 0) ?? ""
        tooltipPosition = CGPoint(x: layerPoint.position.x, y: selectedPoint.y)
        
        if let tooltipText = tooltipText { // the dataSource was priority
            // set the data source text
            tooltip.string = "\(dataSection) \(tooltipText)"
        } else {
            // calculate manually
            calculateManually(render, dataIndex, dataSection, layerPoint)
            
            print("displaying tooltip: \(String(describing: tooltip.string)) at \(tooltipPosition)")
        }
        tooltip.displayTooltip(tooltipPosition,
                               duration: duration)
    }
    
    /// Show tooltip
    /// - Parameters:
    ///   - layerPoint: OMGradientShapeClipLayer
    ///   - renderIndex: Index
    ///   - selectedPoint: CGPoint
    ///   - animation: Bool
    ///   - duration: TimeInterval
    ///   - render: render
    ///   - dataIndex: <#dataIndex description#>
    private func selectionShowTooltip( _ render: BaseRender,
                                       _ layerPoint: OMGradientShapeClipLayer,
                                       _ dataIndex: Int? = nil,
                                       _ selectedPoint: CGPoint,
                                       _ animation: Bool,
                                       _ duration: TimeInterval) {
        var tooltipPosition = CGPoint.zero
        var tooltipPositionFix = CGPoint.zero
        if animation {
            tooltipPositionFix = layerPoint.position
        }
        // Get the selection data index
        if let dataIndex = dataIndex {
            // Create the text and show the
            self.buildTooltipText(render,
                                  dataIndex,
                                  &tooltipPosition,
                                  layerPoint,
                                  selectedPoint,
                                  duration)
        }
        
        if animation {
            let distance = tooltipPositionFix.distance(tooltipPosition)
            let factor = TimeInterval(1.0 / (self.contentView.bounds.size.height / distance))
            let after: TimeInterval = 0.5
            DispatchQueue.main.asyncAfter(deadline: .now() + after) {
                self.tooltip.moveTooltip(tooltipPositionFix,
                                         duration: factor * duration)
            }
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = contentView.frame.size.height / scale
        zoomRect.size.width = contentView.frame.size.width / scale
        let newCenter = contentView.convert(center, from: self)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    func performZoomOnSelection(_ selectedPoint: CGPoint, _ animation: Bool, _ duration: TimeInterval) {
        if zoomScale == 1 {
            CATransaction.begin()
            CATransaction.setAnimationDuration(1.0)
            CATransaction.setCompletionBlock( {
                CATransaction.setAnimationDuration(duration)
                let scale = CATransform3DMakeScale(self.maximumZoomScale, self.maximumZoomScale, 1)
                self.zoom(to: self.zoomRectForScale(scale: self.maximumZoomScale, center: selectedPoint), animated: true)
                //self.footerRule?.views?.forEach{$0.layer.transform = scale}
                
                
                //                    self.oldFooterTransform3D = self.footerRule?.transform ?? .init()
                //                    self.oldRootTransform3D = self.rootRule?.transform3D ?? .init()
                //                    self.footerRule?.transform3D = scale
                //                    self.rootRule?.transform3D  = scale
                
                
                //self.zoom(toPoint: selectedPoint, scale: 2.0, animated: true)
            })
            CATransaction.commit()
        }
    }

    /// selectRenderLayerWithAnimation
    /// - Parameters:
    ///   - layerPoint: OMGradientShapeClipLayer
    ///   - selectedPoint: CGPoint
    ///   - animation: Bool
    ///   - renderIndex: Int
    func selectRenderLayerWithAnimation(_ render: BaseRender,
                                        _ layerPoint: OMGradientShapeClipLayer,
                                        _ selectedPoint: CGPoint,
                                        _ animation: Bool = false,
                                        
                                        _ duration: TimeInterval = 0.5) {
        let needAnimation: Bool = showPointsOnSelection || animateOnRenderLayerSelection || animation
        if needAnimation {
            CATransaction.setAnimationDuration(duration)
            CATransaction.begin()
        }
        if showPointsOnSelection {
            let selectedRenderLayer = selectRenderLayers( render: render, layer: layerPoint)
            print("selectedRenderLayer = \(selectedRenderLayer)")
        }
        if animateOnRenderLayerSelection, layerPoint.opacity > 0, animation {
            self.animateOnRenderLayerSelection(render, layerPoint,  duration)
        }
        let selectionDataIndexFromPointLayerLocation = render.data.index(from: layerPoint.position)
        // Get the selection data index
        if let dataIndex = selectionDataIndexFromPointLayerLocation {
            let sectionIndex = sectionFromPoint(renderIndex: render.index, layer: layerPoint)
            if sectionIndex != Index.bad.rawValue {
                print("Selected data point index: \(dataIndex) section: \(sectionIndex) type: \(render.data.dataType)")
                // notify and animate footer if the animation is actived
                self.didSelectedRenderLayerSection( render.index,
                                                   sectionIndex: Int(sectionIndex),
                                                   layer: layerPoint)
            } else {
                print("Selected data point index: \(dataIndex) type: \(render.data.dataType)")
                // notify the data index selection.
                self.didSelectedRenderLayerIndex( render.index,
                                                  dataIndex: Int(dataIndex),
                                                  layer: layerPoint)
            }
        }
        // Show tooltip
        if showTooltip {
            self.selectionShowTooltip(       render,layerPoint,
                                 
                                       selectionDataIndexFromPointLayerLocation,
                                       selectedPoint,
                                       animation,
                                       duration)
        }
        
        if zoomIsActive {
            self.performZoomOnSelection(selectedPoint,
                                        animation,
                                        duration)
        }
        
        if needAnimation {
            CATransaction.commit()
        }
    }
    /// locationFromTouchInContentView
    /// - Parameter touches: Set<UITouch>
    /// - Returns: CGPoint
    public func locationFromTouchInContentView(_ touches: Set<UITouch>) -> CGPoint {
        if let touch = touches.first {
            return touch.location(in: self.contentView)
        }
        return .zero
    }
}

