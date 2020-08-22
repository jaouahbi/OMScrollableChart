//
//  UIColor+OMSC.swift
//  Example
//
//  Created by Jorge Ouahbi on 22/08/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

extension UIColor {
    @nonobjc class var paleGrey: UIColor {
        return UIColor(red: 247.0 / 255.0, green: 247.0 / 255.0, blue: 250.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var greyishBlue: UIColor {
        return UIColor(red: 89.0 / 255.0, green: 135.0 / 255.0, blue: 164.0 / 255.0, alpha: 1.0)
        
    }
}

extension UIColor {
    
    func isLight() -> Bool {
        guard let components = cgColor.components,
            components.count >= 3 else { return false }
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
        return !(brightness < 0.5)
    }
    
    public var complementaryColor: UIColor {
        if #available(iOS 13, tvOS 13, *) {
            return UIColor { traitCollection in
                return self.isLight() ? self.darker : self.lighter
            }
        } else {
            return isLight() ? darker : lighter
        }
    }
    
    public var lighter: UIColor {
        return adjust(by: 1.35)
    }
    
    public var darker: UIColor {
        return adjust(by: 0.94)
    }
    
    func adjust(by percent: CGFloat) -> UIColor {
        var hxxxx: CGFloat = 0, sxxxx: CGFloat = 0, bxxxx: CGFloat = 0, axxxx: CGFloat = 0
        getHue(&hxxxx, saturation: &sxxxx, brightness: &bxxxx, alpha: &axxxx)
        return UIColor(hue: hxxxx, saturation: sxxxx, brightness: bxxxx * percent, alpha: axxxx)
    }
    
    func makeGradient() -> [UIColor] {
        return [self, self.complementaryColor, self]
    }
}
