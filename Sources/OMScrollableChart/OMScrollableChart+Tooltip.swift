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
    func setupTooltip() {
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
}
