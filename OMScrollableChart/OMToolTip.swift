//
//  OMToolTip.swift
//  Example
//
//  Created by dsp on 29/06/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

class OMTooltip: UILabel {
    
    var tooltipMoveAnimationDuration: TimeInterval = 0.2
    var tooltipShowAnimationDuration: TimeInterval = 0.5
    var tooltipHideAnimationDuration: TimeInterval = 4.0
    
    override func sizeThatFits( _ size: CGSize) -> CGSize {
        let result = super.sizeThatFits(size)
        return CGSize(width: result.width + 30,
                      height: result.height + 5)
    }
    
    func setText(_ name: String?) {
        text = name
        sizeToFit()
    }
    /// Show tooltip at position
    /// - Parameter position: CGPoint
    func show(_ position: CGPoint) {
        UIView.animate(withDuration: tooltipShowAnimationDuration,
                       delay: 0.1,
                       options: [.curveEaseOut],
                       animations: {
            self.alpha  = 1.0
            self.move(position)
        }, completion: { finished in
            
        })
    }
    
    func move(_ position: CGPoint) {
        UIView.animate(withDuration: self.tooltipMoveAnimationDuration) {
            self.frame  = CGRect(x: position.x,
                                 y: position.y,
                                 width: self.frame.width,
                                 height: self.frame.height)
        }
    }
    
    func hide(_ position: CGPoint) {
        UIView.animate(withDuration: tooltipHideAnimationDuration) {
            self.alpha = 0
        }
    }
}
