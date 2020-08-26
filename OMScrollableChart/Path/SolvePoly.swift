import Foundation

func SolveQuad(a a: Double, b: Double, c: Double) -> [Double] {
    let d = b * b - 4 * a * c
    if d >= 0
    {
        return [(-b+sqrt(d))/(2*a), (-b-(sqrt(d)))/(2*a)]
    } else {
        return []
    }
}

func SolveCubic( a: Double, b: Double, c: Double, d: Double) -> [Double] {
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
