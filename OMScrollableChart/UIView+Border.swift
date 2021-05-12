//
//  UIView+Border.swift
//  Example
//
//  Created by dsp on 17/10/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit
public extension UIView {
    
    enum Border {
        case left(inset: CGFloat)
        case right(inset: CGFloat)
        case top(inset: CGFloat)
        case bottom(inset: CGFloat)
    }
    
    func setBorder(border: UIView.Border, weight: CGFloat, color: UIColor) -> UIView {
        
        let borderLine = UIView()
        addSubview(borderLine)
        borderLine.backgroundColor = color
        borderLine.translatesAutoresizingMaskIntoConstraints = false
        
        switch border {
            
        case .left(let constant):
            borderLine.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            borderLine.topAnchor.constraint(equalTo: topAnchor, constant: -constant).isActive = true
            borderLine.bottomAnchor.constraint(equalTo: bottomAnchor, constant: constant).isActive = true
            borderLine.widthAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .right(let constant):
            borderLine.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            borderLine.topAnchor.constraint(equalTo: topAnchor, constant: constant ).isActive = true
            borderLine.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -constant ).isActive = true
            borderLine.widthAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .top(let constant):
            borderLine.topAnchor.constraint(equalTo: topAnchor).isActive = true
            borderLine.leftAnchor.constraint(equalTo: leftAnchor, constant: constant ).isActive = true
            borderLine.rightAnchor.constraint(equalTo: rightAnchor, constant: -constant).isActive = true
            borderLine.heightAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .bottom(let constant):
            borderLine.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            borderLine.leftAnchor.constraint(equalTo: leftAnchor, constant: constant).isActive = true
            borderLine.rightAnchor.constraint(equalTo: rightAnchor, constant: -constant).isActive = true
            borderLine.heightAnchor.constraint(equalToConstant: weight).isActive = true
        }
        
        return borderLine
    }
}

