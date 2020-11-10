//
//    Copyright 2015 - Jorge Ouahbi
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//
//

//
//  UIColor+Extensions.swift
//
//  Created by Jorge Ouahbi on 27/4/16.
//  Copyright © 2016 Jorge Ouahbi. All rights reserved.
//
// v 1.0 Merged files
// v 1.1 Some clean and better component access


import UIKit

///  Attributes

let kLuminanceDarkCutoff:CGFloat = 0.6;

extension UIColor
{
    ///  chroma RGB
    var croma : CGFloat {
        
        let comp  = components
        let min1  = min(comp[1], comp[2])
        let max1  = max(comp[1], comp[2])
        
        return max(comp[0], max1) - min(comp[0], min1);
        
    }
    // luma RGB
    // WebKit
    // luma = (r * 0.2125 + g * 0.7154 + b * 0.0721) * ((double)a / 255.0);
    
    var luma : CGFloat {
        let comp      = components
        let lumaRed   = 0.2126 * Float(comp[0])
        let lumaGreen = 0.7152 * Float(comp[1])
        let lumaBlue  = 0.0722 * Float(comp[2])
        let luma      = Float(lumaRed + lumaGreen + lumaBlue)
        
        return CGFloat(luma * Float(components[3]))
    }
    
    var luminance : CGFloat {
        let comp      = components
        let fmin = min(min(comp[0],comp[1]),comp[2])
        let fmax = max(max(comp[0],comp[1]),comp[2])
        return (fmax + fmin) / 2.0;
    }
    
    
    var isLightLumi : Bool {
        return self.luma >= kLuminanceDarkCutoff
    }
    
    var isDarkLumi : Bool {
        return self.luma < kLuminanceDarkCutoff;
    }
}


extension UIColor {
    
    public convenience init(hex: String) {
        var characterSet = NSCharacterSet.whitespacesAndNewlines
        characterSet = characterSet.union(NSCharacterSet(charactersIn: "#") as CharacterSet)
        let cString = hex.trimmingCharacters(in: characterSet).uppercased()
        if (cString.count != 6) {
            self.init(white: 1.0, alpha: 1.0)
        } else {
            var rgbValue: UInt32 = 0
            Scanner(string: cString).scanHexInt32(&rgbValue)
            
            self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                      green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                      blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                      alpha: CGFloat(1.0))
        }
    }
    
    // MARK: RGBA components
    
    /// Returns an array of `CGFloat`s containing four elements with `self`'s:
    /// - red (index `0`)
    /// - green (index `1`)
    /// - blue (index `2`)
    /// - alpha (index `3`)
    /// or
    /// - white (index `0`)
    /// - alpha (index `1`)
    var components : [CGFloat] {
        // Constructs the array in which to store the RGBA-components.
        if let components = self.cgColor.components {
            if numberOfComponents == 4 {
                return [components[0],components[1],components[2],components[3]]
            } else {
                return [components[0], components[1]]
            }
        }
        
        return []
    }
    
    /// red component
    var r : CGFloat {
        return components[0];
    }
    /// green component
    var g: CGFloat {
        return  components[1];
    }
    /// blue component
    var b: CGFloat {
        return  components[2];
    }
    
    /// number of color components
    var numberOfComponents : size_t {
        return self.cgColor.numberOfComponents
    }
    /// color space
    var colorSpace : CGColorSpace? {
        return self.cgColor.colorSpace
    }
    
    // MARK: HSBA components
    
    /// Returns an array of `CGFloat`s containing four elements with `self`'s:
    /// - hue (index `0`)
    /// - saturation (index `1`)
    /// - brightness (index `2`)
    /// - alpha (index `3`)
    var hsbaComponents: [CGFloat] {
        // Constructs the array in which to store the HSBA-components.
        
        var components0:CGFloat = 0
        var components1:CGFloat = 0
        var components2:CGFloat = 0
        var components3:CGFloat = 0
        
        getHue(       &components0,
                      saturation: &components1,
                      brightness: &components2,
                      alpha:      &components3)
        
        return [components0,components1,components2,components3];
    }
    /// alpha component
    var alpha : CGFloat {
        return self.cgColor.alpha
    }
    /// hue component
    var hue: CGFloat {
        return  hsbaComponents[0];
    }
    /// saturation component
    var saturation: CGFloat {
        return  hsbaComponents[1];
    }
    
    /// Returns a lighter color by the provided percentage
    ///
    /// - param: lighting percent percentage
    /// - returns: lighter UIColor
    
    func lighterColor(percent : Double) -> UIColor {
        return colorWithBrightnessFactor(factor: CGFloat(1 + percent));
    }
    
    /// Returns a darker color by the provided percentage
    ///
    /// - param: darking percent percentage
    /// - returns: darker UIColor
    
    func darkerColor(percent : Double) -> UIColor {
        return colorWithBrightnessFactor(factor: CGFloat(1 - percent));
    }
    
    /// Return a modified color using the brightness factor provided
    ///
    /// - param: factor brightness factor
    /// - returns: modified color
    func colorWithBrightnessFactor(factor: CGFloat) -> UIColor {
        return UIColor(hue: hsbaComponents[0],
                       saturation: hsbaComponents[1],
                       brightness: hsbaComponents[2] * factor,
                       alpha: hsbaComponents[3])
        
    }
    
    /// Color difference
    ///
    /// - Parameter fromColor: color
    /// - Returns: Color difference
    func difference(fromColor: UIColor) -> Int {
        // get the current color's red, green, blue and alpha values
        let red:CGFloat = self.components[0]
        let green:CGFloat = self.components[1]
        let blue:CGFloat = self.components[2]
        //var alpha:CGFloat = self.components[3]
        
        // get the fromColor's red, green, blue and alpha values
        let fromRed:CGFloat = fromColor.components[0]
        let fromGreen:CGFloat = fromColor.components[1]
        let fromBlue:CGFloat = fromColor.components[2]
        //var fromAlpha:CGFloat = fromColor.components[3]
        
        let redValue = (max(red, fromRed) - min(red, fromRed)) * 255
        let greenValue = (max(green, fromGreen) - min(green, fromGreen)) * 255
        let blueValue = (max(blue, fromBlue) - min(blue, fromBlue)) * 255
        
        return Int(redValue + greenValue + blueValue)
    }
    
    /// Brightness difference
    ///
    /// - Parameter fromColor: color
    /// - Returns: Brightness difference
    func brightnessDifference(fromColor: UIColor) -> Int {
        // get the current color's red, green, blue and alpha values
        let red:CGFloat = self.components[0]
        let green:CGFloat = self.components[1]
        let blue:CGFloat = self.components[2]
        //var alpha:CGFloat = self.components[3]
        let brightness = Int((((red * 299) + (green * 587) + (blue * 114)) * 255) / 1000)
        
        // get the fromColor's red, green, blue and alpha values
        let fromRed:CGFloat = fromColor.components[0]
        let fromGreen:CGFloat = fromColor.components[1]
        let fromBlue:CGFloat = fromColor.components[2]
        //var fromAlpha:CGFloat = fromColor.components[3]
        
        let fromBrightness = Int((((fromRed * 299) + (fromGreen * 587) + (fromBlue * 114)) * 255) / 1000)
        
        return max(brightness, fromBrightness) - min(brightness, fromBrightness)
    }
    
    /// Color delta
    ///
    /// - Parameter color: color
    /// - Returns: Color delta
    func colorDelta (color: UIColor) -> Double {
        var total = CGFloat(0)
        total += pow(self.components[0] - color.components[0], 2)
        total += pow(self.components[1] - color.components[1], 2)
        total += pow(self.components[2] - color.components[2], 2)
        total += pow(self.components[3] - color.components[3], 2)
        return sqrt(Double(total) * 255.0)
    }
    
    /// Short UIColor description
    var shortDescription:String {
        let components  = self.components
        if (numberOfComponents == 2) {
            let c = String(format: "%.1f %.1f", components[0], components[1])
            if let colorSpace = self.colorSpace {
                return "\(colorSpace.model.name):\(c)";
            }
            return "\(c)";
        } else {
            assert(numberOfComponents == 4)
            let c = String(format: "%.1f %.1f %.1f %.1f", components[0],components[1],components[2],components[3])
            if let colorSpace = self.colorSpace {
                return "\(colorSpace.model.name):\(c)";
            }
            return "\(c)";
        }
    }
}

/// Random RGBA

extension UIColor {
    
    class public func random() -> UIColor? {
        let r = CGFloat(drand48())
        let g = CGFloat(drand48())
        let b = CGFloat(drand48())
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension UIColor {
    convenience init(_ hex: UInt) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    convenience init(hex: UInt) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    convenience init(_ hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
    
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
        var hue: CGFloat = 0,
        saturation: CGFloat = 0,
        brightness: CGFloat = 0,
        alpha: CGFloat = 0
        getHue(&hue,
               saturation: &saturation,
               brightness: &brightness,
               alpha: &alpha)
        return UIColor(hue: hue, saturation: saturation, brightness: brightness * percent, alpha: alpha)
    }
    
    func makeGradient() -> [UIColor] {
        return [self, self.complementaryColor, self]
    }
}

// https://stackoverflow.com/questions/37055755/computing-complementary-triadic-tetradic-and-analagous-colors
extension UIColor {
    var splitComplement: [UIColor] {
        return [splitComplement0, splitComplement1]
    }
    var triadic: [UIColor] {
        return [triadic0, triadic1]
    }
    var tetradic: [UIColor] {
        return [tetradic0, tetradic1, tetradic2]
    }
    var analagous: [UIColor] {
        return [analagous0, analagous1]
    }
    var complement: UIColor {
        return self.withHueOffset(0.5)
    }
    var splitComplement0: UIColor {
        return self.withHueOffset(150 / 360)
    }
    var splitComplement1: UIColor {
        return self.withHueOffset(210 / 360)
    }
    var triadic0: UIColor {
        return self.withHueOffset(120 / 360)
    }
    var triadic1: UIColor {
        return self.withHueOffset(240 / 360)
    }
    var tetradic0: UIColor {
        return self.withHueOffset(0.25)
    }
    var tetradic1: UIColor {
        return self.complement
    }
    var tetradic2: UIColor {
        return self.withHueOffset(0.75)
    }
    var analagous0: UIColor {
        return self.withHueOffset(-1 / 12)
    }
    var analagous1: UIColor {
        return self.withHueOffset(1 / 12)
    }
    func withHueOffset(_ offset: CGFloat) -> UIColor {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: fmod(h + offset, 1), saturation: s, brightness: b, alpha: a)
    }
}

extension UIColor {
    // get a complementary color to this color:
    static func complementaryForColor(_ color: UIColor) -> UIColor {
        let ciColor = CIColor(color: color)
        // get the current values and make the difference from white:
        let compRed: CGFloat = 1.0 - ciColor.red
        let compGreen: CGFloat = 1.0 - ciColor.green
        let compBlue: CGFloat = 1.0 - ciColor.blue
        return UIColor(red: compRed,
                       green: compGreen,
                       blue: compBlue,
                       alpha: 1.0)
    }
}
public extension UIColor {
    static var greenSea     = UIColor(0x16a085)
    static var turquoise    = UIColor(0x1abc9c)
    static var emerald      = UIColor(0x2ecc71)
    static var peterRiver   = UIColor(0x3498db)
    static var amethyst     = UIColor(0x9b59b6)
    static var wetAsphalt   = UIColor(0x34495e)
    static var nephritis    = UIColor(0x27ae60)
    static var belizeHole   = UIColor(0x2980b9)
    static var wisteria     = UIColor(0x8e44ad)
    static var midnightBlue = UIColor(0x2c3e50)
    static var sunFlower    = UIColor(0xf1c40f)
    static var carrot       = UIColor(0xe67e22)
    static var alizarin     = UIColor(0xe74c3c)
    static var clouds       = UIColor(0xecf0f1)
    static var darkClouds   = UIColor(0x1c2325)
    static var concrete     = UIColor(0x95a5a6)
    static var flatOrange   = UIColor(0xf39c12)
    static var pumpkin      = UIColor(0xd35400)
    static var pomegranate  = UIColor(0xc0392b)
    static var silver       = UIColor(0xbdc3c7)
    static var asbestos     = UIColor(0x7f8c8d)
    static var greyishBlue  = UIColor(0x5987a4)
    
    static var navyThree    = UIColor(0x001825)
    static var navyTwo    = UIColor(0x002941)
    static var navy    = UIColor(0x012336)
    
    static var paleGrey     = UIColor(0xf7f7fa)
    static var paleGreyTwo  = UIColor(0xededf2)
    static var paleGreyThree  = UIColor(0xeeeef3)

        @nonobjc class var tan: UIColor {
            UIColor(red: 217.0 / 255.0, green: 171.0 / 255.0, blue: 110.0 / 255.0, alpha: 1.0)
        }
        @nonobjc class var darkGreyBlueTwo: UIColor {
            return UIColor(red: 50.0 / 255.0, green: 81.0 / 255.0, blue: 108.0 / 255.0, alpha: 1.0)
        }
}
