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
    public func selectNearestRenderLayer(_ renderIndex: Int, point: CGPoint ) {
        /// Select the last point if the render is not hidden.
        selectNearestRenderLayer( engine.renders[renderIndex], point: point)
    }
    
    public func selectNearestRenderLayer(_ render: BaseRender, point: CGPoint ) {
        /// Select the last point if the render is not hidden.
        guard let layer = render.locationToLayer(point) else { return }
        self.selectRenderLayerWithAnimation(render, layer, point)
    }
    /// selectRenderLayer
    /// - Parameters:
    ///   - layer: layer
    ///   - renderIndex: Int
    public func selectRenderLayers(render: BaseRender, layer: GradientShapeLayer) -> GradientShapeLayer {
        let unselected = render.allOtherLayers(layer: layer)
        print("all unselected render layers = \(unselected.count)")
        unselected.forEach { (layer: GradientShapeLayer) in
            layer.gardientColor = animations.unselectedColor
            layer.opacity = animations.unselectedOpacy
        }
        layer.gardientColor = animations.selectedColor
        layer.opacity = animations.selectedOpacy
        print("Selected Render Layer = \(layer.name)")
        return layer
    }

    
    /// performFooterRuleAnimation
    /// - Parameter sectionIndex: sectionIndex
    /// - Returns: Bool
    public func performFooterRuleAnimation(onSection sectionIndex: Int) -> Bool {
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
    public func didSelectedRenderLayerSectionNotify(_ render: BaseRender, sectionIndex: Int, layer: CALayer) {
        // lets animate the footer rule
        if animations.isFooterRuleAnimated {
            let isFooterRuleAnimationDone = performFooterRuleAnimation(onSection: sectionIndex)
            if !isFooterRuleAnimationDone {
                print("Unable to animate section \(sectionIndex) render: \(render.index) layer: \(layer.name ?? "unnamed")")
            }
        }
        guard let delegate = renderDelegate else {return }
        delegate.didSelectSection(chart: self,
                                  renderIndex: render.index,
                                         sectionIndex: sectionIndex,
                                         layer: layer)
    }
    /// didSelectedRenderLayerIndex
    /// - Parameters:
    ///   - renderIndex: renderIndex description
    ///   - dataIndex: dataIndex description
    ///   - layer: layer description
    public func didSelectedRenderLayerIndexNotify(_ render: BaseRender, dataIndex: Int, layer: CALayer) {
        renderDelegate?.didSelectDataIndex(chart: self, renderIndex: render.index, dataIndex: dataIndex, layer: layer)
    }
    /// performZoomOnSelection
    /// - Parameters:
    ///   - point: point description
    ///   - scale: scale description
    ///   - animation: animation description
    ///   - duration: duration description
    public func performZoomOnSelection(_ point: CGPoint, _ scale: CGFloat = 1.2, _ animation: Bool, _ duration: TimeInterval = 1.0) {
        if self.zoomScale == 1 {
            self.zoom(toPoint: point, scale: scale, animated: animation, resetZoom: true)
        } else {
            self.setZoomScale(1, animated: true)
        }
    }
    /// selectRenderLayerWithAnimation
    /// - Parameters:
    ///   - layerPoint: GradientShapeLayer
    ///   - selectedPoint: CGPoint
    ///   - animation: Bool
    ///   - renderIndex: Int
    public func selectRenderLayerWithAnimation(_ render: BaseRender,
                                        _ layerPoint: ShapeLayer,
                                        _ selectedPoint: CGPoint,
                                        _ animation: Bool = false,
                                        _ duration: TimeInterval = 0.5) {
        
        print("selectRenderLayerWithAnimation = \(render.index)")
        
        let needAnimation: Bool = animations.showPointsOnSelection ||
                                  animations.animateOnRenderLayerSelection ||
                                   animation
        if needAnimation {
            CATransaction.setAnimationDuration(duration)
            CATransaction.begin()
        }
        
        if animations.showPointsOnSelection, let layer = layerPoint as? GradientShapeLayer {
            let selectedRenderLayer = selectRenderLayers( render: render, layer: layer)
            print("selectedRenderLayer = \(selectedRenderLayer)")
        }
        if animations.animateOnRenderLayerSelection,
           layerPoint.opacity > 0, animation {
            self.animateOnRenderLayerSelection(render, layerPoint,  duration)
        }
        let selectionDataIndexFromPointLayerLocation = render.data.index(withPoint: layerPoint.position)
        // Get the selection data index
        if let dataIndex = selectionDataIndexFromPointLayerLocation {
            
            print("Selected data point index: \(dataIndex) type: \(render.data.dataType)")
            // notify the data index selection.
            self.didSelectedRenderLayerIndexNotify( render,
                                              dataIndex: Int(dataIndex),
                                              layer: layerPoint)
            
            let sectionIndex = sectionIndexFromLayer(render, layer: layerPoint)
            if sectionIndex != Index.bad.rawValue {
                print("Selected SECTION: \(sectionIndex) type: \(render.data.dataType)")
                // notify and animate footer if the animation is actived
                self.didSelectedRenderLayerSectionNotify( render,
                                                          sectionIndex: Int(sectionIndex),
                                                          layer: layerPoint)
            } else {
                print("Unexpected \(dataIndex) type: \(render.data.dataType)")
            }
        }
        // Show tooltip
        if animations.showTooltip {
            self.displayTooltip( render,
                                       layerPoint,
                                       selectionDataIndexFromPointLayerLocation,
                                       selectedPoint,
                                       animation,
                                       duration)
        }
        
        if needAnimation {
            CATransaction.commit()
        }
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        print("scrollViewWillBeginZooming")
        ruleManager.hideRules()
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        print("scrollViewDidEndZooming \(scale)")
        ruleManager.showRules()
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        self.contentView
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
    /// hitTestAsLayer
    /// - Parameter location: location description
    /// - Returns: ShapeLayer
    public func hitTestAsLayer(_ location: CGPoint) -> CALayer? {
        if let layer = contentView.layer.hitTest(location) { // If you hit a layer and if its a Shapelayer
            return layer
        }
        return nil
    }
}

