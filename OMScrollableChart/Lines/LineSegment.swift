//
//  LineSegment.swift
//  Example
//
//  Created by Jorge Ouahbi on 09/11/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

public struct LineSegment {
    var p1: CGPoint
    var p2: CGPoint
    
    init(_ p1: CGPoint, _ p2: CGPoint) {
        self.p1 = p1
        self.p2 = p2
    }
    
    func midpoint() -> CGPoint {
        let x = (p1.x + p2.x) / 2
        let y = (p1.y + p2.y) / 2
        return CGPoint(x: x, y: y)
    }
    
    func angle() -> CGFloat {
        return atan2(p2.y - p1.y, p2.x - p1.x)
    }
    
    func length() -> CGFloat {
        return hypot(p1.x - p2.x, p1.y - p2.y)
    }
    
    func interpolatePointAtT(t: CGFloat) -> CGPoint {
        let u = 1 - t
        let x = p1.x * u + p2.x * t
        let y = p1.y * u + p2.y * t
        return CGPoint(x: x, y: y)
    }
  
    func point() -> CGPoint {
        return CGPoint(x: min(p1.x, p2.x),
                      y: min(p1.y, p2.y))
    }
    
    func bounds() -> CGRect {
        return CGRect(x: min(p1.x, p2.x),
                      y: min(p1.y, p2.y),
                  width: abs(p1.x - p2.x),
                 height: abs(p1.y - p2.y))
    }
    
    func pointsOnLineAtDistance(distance: CGFloat) -> [CGPoint] {
        let dX = p2.x - p1.x
        let dY = p2.y - p1.y
        let numPoints = Int(floor(self.length() / distance))
        let stepX = dX / CGFloat(numPoints)
        let stepY = dY / CGFloat(numPoints)
        var pX = p1.x + stepX
        var pY = p1.y + stepY
        
        var result: [CGPoint] = []
        
        for ix in 0..<numPoints {
        //for(var ix = 0; ix < numPoints; ix++) {
            result.append(CGPoint(x: pX, y: pY))
            pX += stepX
            pY += stepY
        }
        
        return result
    }
    
    mutating func translateInPlace(dX: CGFloat, dY: CGFloat) {
        p1.x += dX
        p1.y += dY
        p2.x += dX
        p2.y += dY
    }
    
    func translate(dX: CGFloat, dY: CGFloat) -> LineSegment {
        var newSegment = self
        newSegment.translateInPlace(dX: dX, dY: dY)
        return newSegment
    }
    
    mutating func rotateInPlace(radians: CGFloat, aboutPoint pivot: CGPoint) {
        let s = sin(radians)
        let c = cos(radians)
        
        p1.x -= pivot.x
        p1.y -= pivot.y
        var xnew = p1.x * c - p1.y * s
        var ynew = p1.x * s + p1.y * c
        p1.x = xnew + pivot.x
        p1.y = ynew + pivot.y
        
        p2.x -= pivot.x
        p2.y -= pivot.y
        xnew = p2.x * c - p2.y * s
        ynew = p2.x * s + p2.y * c
        p2.x = xnew + pivot.x
        p2.y = ynew + pivot.y
    }
    
    func rotate(radians: CGFloat, aboutPoint pivot: CGPoint) -> LineSegment {
        var newSegment = self
        newSegment.rotateInPlace(radians: radians, aboutPoint: pivot)
        return newSegment
    }
    
    func intersectionPointWithLineSegment(segment: LineSegment) -> CGPoint? {
        let ua_t = (segment.p2.x - segment.p1.x) * (p1.y - segment.p1.y) - (segment.p2.y - segment.p1.y) * (p1.x - segment.p1.x)
        let ub_t = (p2.x - p1.x) * (p1.y - segment.p1.y) - (p2.y - p1.y) * (p1.x - segment.p1.x)
        let u_b = (segment.p2.y - segment.p1.y) * (p2.x - p1.x) - (segment.p2.x - segment.p1.x) * (p2.y - p1.y)
        if u_b != 0 {
            let ua = ua_t / u_b
            let ub = ub_t / u_b
            if 0 <= ua && ua <= 1 && 0 <= ub && ub <= 1 {
                return CGPoint(x: p1.x + ua * (p2.x - p1.x),
                               y: p1.y + ua * (p2.y - p1.y))
            }
        }
        
        return nil
    }
}

extension LineSegment: Equatable {}

public func ==(lhs: LineSegment, rhs: LineSegment) -> Bool {
    return (lhs.p1.x == rhs.p1.x && lhs.p1.y == rhs.p1.y ) &&
          (lhs.p2.x == rhs.p2.x && lhs.p2.y == rhs.p2.y)
}
