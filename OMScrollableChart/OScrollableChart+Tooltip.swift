//
//  OScrollableChart+Tooltip.swift
//  CanalesDigitalesGCiOS
//
//  Created by Jorge Ouahbi on 22/08/2020.
//  Copyright © 2020 Banco Caminos. All rights reserved.
//

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
