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

//  Float+Math.swift
//
//  Created by Jorge Ouahbi on 25/11/15.
//  Copyright © 2015 Jorge Ouahbi. All rights reserved.
//

import UIKit

/**
 *  Float Extension for conversion from/to degrees/radians and clamp
 */

public extension Float {
    
    func degreesToRadians () -> Float {
        return self * 0.01745329252
    }
    func radiansToDegrees () -> Float {
        return self * 57.29577951
    }
    
    mutating func clamp(toLowerValue lowerValue: Float, upperValue: Float){
        self = min(max(self, lowerValue), upperValue)
    }
    
    func isInRangeOrEqual(_ from: Float, _ to: Float) -> Bool {
        return (from <= self && self <= to)
    }
    
    func isInRange(_ from: Float, _ to: Float) -> Bool {
        return (from < self && self < to)
    }
    
    var squared: Float {
        return self * self
    }
    
    var cubed: Float {
        return self * self * self
    }
    
    var cubicRoot: Float {
        return pow(Float(self), 1.0 / 3.0)
    }
    
    static func solveQuadratic(_ a: Float, _ b: Float, _ c: Float) -> Float {
        var result = (-b + sqrt(b.squared - 4 * a * c)) / (2 * a);
        guard !result.isInRangeOrEqual(0, 1) else {
            return result
        }
        
        result = (-b - sqrt(b.squared - 4 * a * c)) / (2 * a);
        guard !result.isInRangeOrEqual(0, 1) else {
            return result
        }
        
        return -1;
    }
    
    static func solveQuadraticEquation(solveA: Float, solveB: Float, solveC: Float) -> [Float] {
        let d = solveB * solveB - 4 * solveA * solveC
        if d >= 0 {
            return [(-solveB+sqrt(d))/(2*solveA), (-solveB-(sqrt(d)))/(2*solveA)]
        } else {
            return []
        }
    }
    
    static func solveCubicEquation( a: Float, b: Float, c: Float, d: Float) -> [Float] {
        // http://www.1728.org/cubic2.htm
        
        let aP2 = a * a
        let bP2 = b * b
        let aP3 = aP2 * a
        let bP3 = bP2 * b
        
        let f = ((3 * c / a) - (bP2 / aP2)) / 3
        let g = ((2 * bP3 / aP3) - (9 * b * c / aP2) + (27 * d / a)) / 27
        let h = (g * g / 4) + (f * f * f / 27)
        
        if h > 0 {
            let r = -(g / 2) + sqrt(h)
            let s = cbrt(r)
            let t = -(g / 2) - sqrt(h)
            let u = cbrt(t)
            let x1 = (s + u) - b / (3 * a)
            //let x2 = X2 = -(S + U)/2 - (b/3a) + i*(S-U)*(3)½/2
            //let x3 = -(S + U)/2 - (b/3a) - i*(S-U)*(3)½/2
            return [x1]
        } else if h == 0 {
            let x1 = -cbrt(d / a)
            return [x1]
        } else {
            let i = sqrt((g * g / 4) - h)
            let j = cbrt(i)
            let k = acos(-(g / (2 * i)))
            let l = -j
            let m = cos(k / 3)
            let n = sqrt(3) * sin(k / 3)
            let p = -(b / (3 * a))
            let x1 = 2 * j * cos(k / 3) - b / (3 * a)
            let x2 = l * (m + n) + p
            let x3 = l * (m - n) + p
            return [x1, x2, x3]
        }
    }
    
    static func solveCubic(_ a: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
        if (a == 0) {
            return solveQuadratic(b, c, d)
        }
        if (d == 0) {
            return 0
        }
        let a = a
        var b = b
        var c = c
        var d = d
        b /= a
        c /= a
        d /= a
        var q = (3.0 * c - b.squared) / 9.0
        let r = (-27.0 * d + b * (9.0 * c - 2.0 * b.squared)) / 54.0
        let disc = q.cubed + r.squared
        let term1 = b / 3.0
        
        if (disc > 0) {
            var s = r + sqrt(disc)
            s = (s < 0) ? -((-s).cubicRoot) : s.cubicRoot
            var t = r - sqrt(disc)
            t = (t < 0) ? -((-t).cubicRoot) : t.cubicRoot
            
            let result = -term1 + s + t;
            if result.isInRangeOrEqual(0, 1) {
                return result
            }
        } else if (disc == 0) {
            let r13 = (r < 0) ? -((-r).cubicRoot) : r.cubicRoot;
            
            var result = -term1 + 2.0 * r13;
            if result.isInRangeOrEqual(0, 1) {
                return result
            }
            
            result = -(r13 + term1);
            if result.isInRangeOrEqual(0, 1) {
                return result
            }
            
        } else {
            q = -q;
            var dum1 = q * q * q;
            dum1 = acos(r / sqrt(dum1));
            let r13 = 2.0 * sqrt(q);
            
            var result = -term1 + r13 * cos(dum1 / 3.0);
            if result.isInRangeOrEqual(0, 1) {
                return result
            }
            result = -term1 + r13 * cos((dum1 + 2.0 * .pi) / 3.0);
            if result.isInRangeOrEqual(0, 1) {
                return result
            }
            result = -term1 + r13 * cos((dum1 + 4.0 * .pi) / 3.0);
            if result.isInRangeOrEqual(0, 1) {
                return result
            }
        }
        
        return -1;
    }
    
    func cubicBezierInterpolate(_ P0: CGPoint, _ P1: CGPoint, _ P2: CGPoint, _ P3: CGPoint) -> Float {
        var t: Float
        if (self == Float(P0.x)) {
            // Handle corner cases explicitly to prevent rounding errors
            t = 0
        } else if (self ==  Float(P3.x)) {
            t = 1
        } else {
            // Calculate t
            let a = -Float(P0.x) + 3 * Float(P1.x) - 3 * Float(P2.x) + Float(P3.x)
            let b = 3 * Float(P0.x) - 6 * Float(P1.x) + 3 * Float(P2.x);
            let c = -3 * Float(P0.x) + 3 * Float(P1.x);
            let d = Float(P0.x) - self
            let tTemp = Float.solveCubic(a, b, c, d);
            if (tTemp == -1) {
                return -1;
            }
            t = tTemp
        }
        
        // Calculate y from t
        return (1 - t).cubed * Float(P0.y) + 3 * t * (1 - t).squared * Float(P1.y) + 3 * t.squared * (1 - t) * Float(P2.y) + t.cubed * Float(P3.y);
    }
    
    func cubicBezier(_ t: Float, _ c1: Float, _ c2: Float, _ end: Float) -> Float {
        let t_ = (1.0 - t)
        let tt_ = t_ * t_
        let ttt_ = t_ * t_ * t_
        let tt = t * t
        let ttt = t * t * t
        
        return self * ttt_
            + 3.0 *  c1 * tt_ * t
            + 3.0 *  c2 * t_ * tt
            + end * ttt;
    }
}

