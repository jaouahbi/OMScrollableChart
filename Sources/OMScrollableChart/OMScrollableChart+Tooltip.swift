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
//  OMScrollableChart
//
//  Created by Jorge Ouahbi on 16/08/2020.

import UIKit
import LibControl

extension OMScrollableChart {
  
    var estimatedTooltipFrame: CGRect {
        let ratio: CGFloat = (1.0 / 8.0) * 0.5
        let superHeight = self.superview?.frame.height ?? 1
        let estimatedTooltipHeight = superHeight * ratio
        return CGRect(x: 0,
                      y: 0,
                      width: 128,
                      height: estimatedTooltipHeight > 0 ? estimatedTooltipHeight : 37.0)
    }
    /// Setup it
    func configureTooltip() {
        tooltip.frame = estimatedTooltipFrame
        tooltip.alpha = tooltipAlpha
        tooltip.font = tooltipFont
        tooltip.textAlignment = .center
        tooltip.layer.cornerRadius = 6
        tooltip.layer.masksToBounds = true
        tooltip.backgroundColor = toolTipBackgroundColor
        tooltip.layer.borderColor = tooltipBorderColor
        tooltip.layer.borderWidth = tooltipBorderWidth
        // Shadow
        tooltip.layer.shadowColor   = UIColor.black.cgColor
        tooltip.layer.shadowOffset  = pointsLayersShadowOffset
        tooltip.layer.shadowOpacity = 0.7
        tooltip.layer.shadowRadius  = 3.0
        
        tooltip.isFlipped           = true
        contentView.addSubview(tooltip)
    }
    
    /// Build the tooltip text to show.
    /// - Parameters:
    ///   - renderIndex: Index
    ///   - dataIndex: data index
    ///   - tooltipPosition: CGPoint
    ///   - layerPoint: layer point
    ///   - selectedPoint: selected point
    ///   - duration: TimeInterval
    public func buildTooltipText( _ render: BaseRender,
                                  _ dataIndex: Int,
                                  _ tooltipPosition: inout CGPoint,
                                  _ layerPoint: ShapeLayer,
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
        // postion
        tooltipPosition = CGPoint(x: layerPoint.position.x, y: selectedPoint.y)
        
        if let tooltipText = tooltipText { // the dataSource was priority
            // set the data source text
            tooltip.string = "\(dataSection) \(tooltipText)"
        } else {
            // calculate manually
            calculateTooltipTextManually(render, dataIndex, dataSection, layerPoint)
            
//            print("displaying tooltip: \(String(describing: tooltip.string)) at \(tooltipPosition)")
        }
        tooltip.displayTooltip(tooltipPosition,
                               duration: duration)
    }
    
    /// calculateTooltipTextManually
    /// - Parameters:
    ///   - render: render description
    ///   - dataIndex: dataIndex description
    ///   - dataSection: dataSection description
    ///   - layerPoint: layerPoint description
    func calculateTooltipTextManually(_ render: BaseRender,
                                              _ dataIndex: Int,
                                              _ dataSection: String,
                                              _ layerPoint: ShapeLayer) {
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
    
   
    
    
    /// Show tooltip
    /// - Parameters:
    ///   - render: render
    ///   - layerPoint: GradientShapeLayer
    ///   - dataIndex: dataIndex
    ///   - selectedPoint: CGPoint
    ///   - animation: Bool
    ///   - duration: TimeInterval

    public func displayTooltip( on render: BaseRender,
                                       _ layerPoint: ShapeLayer,
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
}
