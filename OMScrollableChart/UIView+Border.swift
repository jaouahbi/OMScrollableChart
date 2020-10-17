//
//  UIView+Border.swift
//  Example
//
//  Created by dsp on 17/10/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

// Swift 3.0
extension UIView {
    
    enum Border {
        case left(constant: CGFloat)
        case right(constant: CGFloat)
        case top(constant: CGFloat)
        case bottom(constant: CGFloat)
    }
    
    func setBorder(border: UIView.Border, weight: CGFloat, color: UIColor) -> UIView {
        
        let lineView = UIView()
        addSubview(lineView)
        lineView.backgroundColor = color
        lineView.translatesAutoresizingMaskIntoConstraints = false
        
        switch border {
            
        case .left(let constant):
            lineView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            lineView.topAnchor.constraint(equalTo: topAnchor, constant: -constant).isActive = true
            lineView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: constant).isActive = true
            lineView.widthAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .right(let constant):
            lineView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            lineView.topAnchor.constraint(equalTo: topAnchor, constant: constant ).isActive = true
            lineView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -constant ).isActive = true
            lineView.widthAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .top(let constant):
            lineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            lineView.leftAnchor.constraint(equalTo: leftAnchor, constant: constant ).isActive = true
            lineView.rightAnchor.constraint(equalTo: rightAnchor, constant: -constant).isActive = true
            lineView.heightAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .bottom(let constant):
            lineView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            lineView.leftAnchor.constraint(equalTo: leftAnchor, constant: constant).isActive = true
            lineView.rightAnchor.constraint(equalTo: rightAnchor, constant: -constant).isActive = true
            lineView.heightAnchor.constraint(equalToConstant: weight).isActive = true
        }
        
        return lineView
    }
}
