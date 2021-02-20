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

public struct ScrollableChartColorConfiguration {
    public static let strokeColor: UIColor = UIColor.paleGreyThree.withAlphaComponent(0.69)
    public static let fillColor: UIColor = lineColor.lighter.withAlphaComponent(0.88)
    public static let gradientColor: UIColor = lineColor.darken().withAlphaComponent(0.55)
    public static let bezierColor: UIColor = UIColor.navyTwo.lighter
    public static let glowColor: UIColor = lineColor.analagous1.withAlphaComponent(0.63)
    public static var lineColor = UIColor.greyishBlue
    public static var selectedPointColor = lineColor.analagous0.withAlphaComponent(0.43)
    public static let strokeLineColor: UIColor = .black
    public static let pointColor: UIColor = lineColor.darken()
}

extension OMScrollableChart {

    /// performFooterRuleAnimation
    /// - Parameter sectionIndex: sectionIndex
    /// - Returns: Bool
    public func performFooterRuleAnimation(onSection sectionIndex: Int) -> Bool {
        guard numberOfSections > 0 else { return false }
        if let footer = ruleManager.footerRule as? OMScrollableChartRuleFooter,
           let sectionsViews = footer.views {
//            print("circular section index", sectionIndex % numberOfSections)
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
    public func didChangedRenderLayerSectionNotify(_ render: BaseRender, sectionIndex: Int, layer: CALayer) {
        // lets animate the footer rule
        if animations.isFooterRuleAnimatedOnSectionChange {
            let isFooterRuleAnimationDone = performFooterRuleAnimation(onSection: sectionIndex)
            if !isFooterRuleAnimationDone {
                print(
                    """
                        Unable to animate section \(sectionIndex)
                        render: \(render.index)
                        layer: \(layer.name ?? "unknown layer name")
                    """)
            }
        }
        renderDelegate?.didChangeSection(chart: self,
                                  renderIndex: render.index,
                                  sectionIndex: sectionIndex,
                                  layer: layer)
    }
    /// engine_ZoomOnSelection
    /// - Parameters:
    ///   - point: point description
    ///   - scale: scale description
    ///   - animation: animation description
    ///   - duration: duration description
    public func engine_ZoomOnSelection(_ point: CGPoint,
                                       _ scale: CGFloat = 1.2,
                                       _ animation: Bool,
                                       _ duration: TimeInterval = 1.0) {
        if self.zoomScale == 1 {
            self.zoom(toPoint: point,
                      scale: scale,
                      animated: animation,
                      resetZoom: true)
        } else {
            self.setZoomScale(1, animated: true)
        }
    }
    
    private func didChangedRenderLayerDataIndexNotify(_ render: BaseRender,
                                                      _ dataIndex: Int,
                                                      _ layerToSelect: ShapeLayer) {
        // print("Selected data point index: \(dataIndex) type: \(render.data.dataType)")
        
        // notify the data index selection.
        renderDelegate?.didSelectDataIndex(chart: self,
                                           renderIndex: render.index,
                                           dataIndex: dataIndex,
                                           layer: layerToSelect)
    }
    
    /// selectRenderLayerWithAnimation
    /// - Parameters:
    ///   - layerPoint: GradientShapeLayer
    ///   - selectedPoint: CGPoint
    ///   - animation: Bool
    ///   - renderIndex: Int
    public func selectRenderLayerWithAnimation(_ render: BaseRender,
                                        _ layerToSelect: ShapeLayer,
                                        _ selectedPoint: CGPoint,
                                        _ animation: Bool = false,
                                        _ duration: TimeInterval = 0.5) {
        
//        print("selectRenderLayerWithAnimation = \(render)")
        
        let needAnimation: Bool = (animations.showSelectedLayerOnSelection ||
                                   animations.animateOnRenderLayerSelection ||
                                   animation) && duration > 0
        if needAnimation {
            CATransaction.setAnimationDuration(duration)
            CATransaction.begin()
        }
        
        if animations.showSelectedLayerOnSelection {
            if let layer = layerToSelect as? GradientShapeLayer {
                
                // change the selected layer to selected layer properties and
                // unselected layer to unselected layer properties of the render
                
                let renderLayer = render.selectLayer(layer: layer,
                                                     selected: LayerProperties(color: render.selectedColor, opacity: render.selectedOpacy),
                                                     unselected: LayerProperties(color: render.unselectedColor, opacity: render.selectedOpacy))
                print("selected layer = \(renderLayer.name ?? "")")
            }
        }
        
        if animations.animateOnRenderLayerSelection {
            if animation {
                if layerToSelect.opacity > 0 {
                    self.animateOnRenderLayerSelection(render,
                                                       layerToSelect,
                                                       duration)
                }
            }
        }

        let selectionDataIndex = render.data.index(withPoint: layerToSelect.position)
        // check if render wants notifications
        if render.chars.contains(.event_notifier) {
            // notify
            self.notifyLayerSelection(on: render,
                                      layerToSelect: layerToSelect,
                                      selectionDataIndex: selectionDataIndex)
        }
        
        // Show tooltip
        if animations.showTooltip {
            self.displayTooltip( render,
                                       layerToSelect,
                                       selectionDataIndex,
                                       selectedPoint,
                                       animation,
                                       duration)
        }
        if needAnimation {
            CATransaction.commit()
        }
    }
    
    /// notifyLayerSelection
    /// - Parameters:
    ///   - render: render
    ///   - layerToSelect: layer
    ///   - selectionDataIndex: data index
    func notifyLayerSelection(on render: BaseRender,
                          layerToSelect: ShapeLayer,
                          selectionDataIndex: Int?) {
        // Get the selection data index
        if let dataIndex = selectionDataIndex {
            // notify about selection of point linked to a index of data
            self.didChangedRenderLayerDataIndexNotify(render,
                                                      dataIndex,
                                                      layerToSelect)
        }
        let sectionIndex = sectionIndexFromLayer(render, layer: layerToSelect)
        // changed
        if sectionIndex != Index.bad.rawValue && sectionIndex != self.sectionIndex  {
            // print("Selected SECTION: \(sectionIndex) type: \(render.data.dataType)")
            // notify and animate footer if the animation is actived
            self.didChangedRenderLayerSectionNotify( render,
                                                      sectionIndex: Int(sectionIndex),
                                                      layer: layerToSelect)
            // update the last section index
            self.sectionIndex = sectionIndex
        } else {
            //print("Unexpected \(dataIndex) type: \(render.data.dataType)")
        }
    }
    // MARK: - Zoom -
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
        // If you hit a layer (and if its a Shapelayer)
        if let layer = contentView.layer.hitTest(location) {
            return layer
        }
        return nil
    }
}

