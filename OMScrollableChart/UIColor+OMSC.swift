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
//  UIColor+OMSC.swift
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
    @nonobjc class var darkGreyBlueTwo: UIColor {
        return UIColor(red: 50.0 / 255.0, green: 81.0 / 255.0, blue: 108.0 / 255.0, alpha: 1.0)
    }
}

extension UIColor {
    
    func isLight() -> Bool {
        return !(brightness < 0.5)
    }
    var brightness: CGFloat {
        guard let components = cgColor.components,
            components.count >= 3 else { return 0 }
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
        return brightness
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
