import UIKit

extension CGFloat {
    
    func isInRangeOrEqual(_ from: CGFloat, _ to: CGFloat) -> Bool {
        return (from <= self && self <= to)
    }
    
    func isInRange(_ from: CGFloat, _ to: CGFloat) -> Bool {
        return (from < self && self < to)
    }
    
    var squared: CGFloat {
        return self * self
    }
    
    var cubed: CGFloat {
        return self * self * self
    }
    
    var cubicRoot: CGFloat {
        return CGFloat(pow(Double(self), 1.0 / 3.0))
    }
    
    private static func SolveQuadratic(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat) -> CGFloat {
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
    
    private static func SolveCubic(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) -> CGFloat {
        if (a == 0) {
            return SolveQuadratic(b, c, d)
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
    
    func cubicBezierInterpolate(_ P0: CGPoint, _ P1: CGPoint, _ P2: CGPoint, _ P3: CGPoint) -> CGFloat {
        var t: CGFloat
        if (self == P0.x) {
            // Handle corner cases explicitly to prevent rounding errors
            t = 0
        } else if (self == P3.x) {
            t = 1
        } else {
            // Calculate t
            let a = -P0.x + 3 * P1.x - 3 * P2.x + P3.x;
            let b = 3 * P0.x - 6 * P1.x + 3 * P2.x;
            let c = -3 * P0.x + 3 * P1.x;
            let d = P0.x - self;
            let tTemp = CGFloat.SolveCubic(a, b, c, d);
            if (tTemp == -1) {
                return -1;
            }
            t = tTemp
        }
        
        // Calculate y from t
        return (1 - t).cubed * P0.y + 3 * t * (1 - t).squared * P1.y + 3 * t.squared * (1 - t) * P2.y + t.cubed * P3.y;
    }
    
    func cubicBezier(_ t: CGFloat, _ c1: CGFloat, _ c2: CGFloat, _ end: CGFloat) -> CGFloat {
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


extension Double {
    
    func isInRangeOrEqual(_ from: Double, _ to: Double) -> Bool {
        return (from <= self && self <= to)
    }
    
    func isInRange(_ from: Double, _ to: Double) -> Bool {
        return (from < self && self < to)
    }
    
    var squared: Double {
        return self * self
    }
    
    var cubed: Double {
        return self * self * self
    }
    
    var cubicRoot: Double {
        return pow(Double(self), 1.0 / 3.0)
    }
    
    static func SolveQuadratic(_ a: Double, _ b: Double, _ c: Double) -> Double {
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
    
    static func solveQuadraticEquation(solveA: Double, solveB: Double, solveC: Double) -> [Double] {
        let d = solveB * solveB - 4 * solveA * solveC
        if d >= 0 {
            return [(-solveB+sqrt(d))/(2*solveA), (-solveB-(sqrt(d)))/(2*solveA)]
        } else {
            return []
        }
    }
    
    static func solveCubicEquation( a: Double, b: Double, c: Double, d: Double) -> [Double] {
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
    
    static func SolveCubic(_ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double {
        if (a == 0) {
            return SolveQuadratic(b, c, d)
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
    
    func cubicBezierInterpolate(_ P0: CGPoint, _ P1: CGPoint, _ P2: CGPoint, _ P3: CGPoint) -> Double {
        var t: Double
        if (self == Double(P0.x)) {
            // Handle corner cases explicitly to prevent rounding errors
            t = 0
        } else if (self ==  Double(P3.x)) {
            t = 1
        } else {
            // Calculate t
            let a = -Double(P0.x) + 3 * Double(P1.x) - 3 * Double(P2.x) + Double(P3.x)
            let b = 3 * Double(P0.x) - 6 * Double(P1.x) + 3 * Double(P2.x);
            let c = -3 * Double(P0.x) + 3 * Double(P1.x);
            let d = Double(P0.x) - self
            let tTemp = Double.SolveCubic(a, b, c, d);
            if (tTemp == -1) {
                return -1;
            }
            t = tTemp
        }
        
        // Calculate y from t
        return (1 - t).cubed * Double(P0.y) + 3 * t * (1 - t).squared * Double(P1.y) + 3 * t.squared * (1 - t) * Double(P2.y) + t.cubed * Double(P3.y);
    }
    
    func cubicBezier(_ t: Double, _ c1: Double, _ c2: Double, _ end: Double) -> Double {
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

//
//
//// swiftlint:disable identifier_name shorthand_operator
//// swiftlint:disable file_length
//// swiftlint:disable type_body_length
//func solveQuad(solveA: Double, solveB: Double, solveC: Double) -> [Double] {
//    let d = solveB * solveB - 4 * solveA * solveC
//    if d >= 0 {
//        return [(-solveB+sqrt(d))/(2*solveA), (-solveB-(sqrt(d)))/(2*solveA)]
//    } else {
//        return []
//    }
//}
//
//func solveCubic( a: Double, b: Double, c: Double, d: Double) -> [Double] {
//    // http://www.1728.org/cubic2.htm
//
//    let aP2 = a * a
//    let bP2 = b * b
//    let aP3 = aP2 * a
//    let bP3 = bP2 * b
//
//    let f = ((3 * c / a) - (bP2 / aP2)) / 3
//    let g = ((2 * bP3 / aP3) - (9 * b * c / aP2) + (27 * d / a)) / 27
//    let h = (g * g / 4) + (f * f * f / 27)
//
//    if h > 0 {
//        let r = -(g / 2) + sqrt(h)
//        let s = cbrt(r)
//        let t = -(g / 2) - sqrt(h)
//        let u = cbrt(t)
//        let x1 = (s + u) - b / (3 * a)
//        //let x2 = X2 = -(S + U)/2 - (b/3a) + i*(S-U)*(3)½/2
//        //let x3 = -(S + U)/2 - (b/3a) - i*(S-U)*(3)½/2
//        return [x1]
//    } else if h == 0 {
//        let x1 = -cbrt(d / a)
//        return [x1]
//    } else {
//        let i = sqrt((g * g / 4) - h)
//        let j = cbrt(i)
//        let k = acos(-(g / (2 * i)))
//        let l = -j
//        let m = cos(k / 3)
//        let n = sqrt(3) * sin(k / 3)
//        let p = -(b / (3 * a))
//        let x1 = 2 * j * cos(k / 3) - b / (3 * a)
//        let x2 = l * (m + n) + p
//        let x3 = l * (m - n) + p
//        return [x1, x2, x3]
//    }
//}
//
// swiftlint:enabled identifier_name shorthand_operator
// swiftlint:enabled file_length
// swiftlint:enabled type_body_length
