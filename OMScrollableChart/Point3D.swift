//
//  Point3D.swift
//  Example
//
//  Created by Jorge Ouahbi on 29/10/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

struct Point3D: Comparable {
    static func < (lhs: Point3D, rhs: Point3D) -> Bool {
        return lhs.z < rhs.z
    }
    
    var x: CGFloat, y: CGFloat, z: CGFloat
    static var zero = Point3D(x: 0, y: 0, z: 0)
}

struct Segment3D {
    var P0: Point3D
    var P1: Point3D
}

extension Point3D {
    func dot(point: Point3D) -> CGFloat {
        return (self.x * point.x + self.y * point.y + self.z * point.z)
    }
    func norm() -> CGFloat {
        return self.dot(point: self)
    }
    func normSquared() -> CGFloat {
        return sqrt(self.norm())
    }
    func d2(point: Point3D) -> CGFloat {
        let sub = Point3D(x: self.x - point.x, y: self.y - point.y, z: self.z - point.z)
        return sub.normSquared()
    }
    func sub(point: Point3D) -> Point3D {
        let sub = Point3D(x: self.x - point.x, y: self.y - point.y, z: self.z - point.z)
        return sub
    }
    func d(point: Point3D) -> CGFloat {
        return self.sub(point: point).norm()
    }
    func add(scalar: CGFloat) -> Point3D {
        var result: Point3D = .zero
        result.x = self.x + scalar
        result.y = self.y + scalar
        result.z = self.z + scalar
        return result
    }
    func mul(point: Point3D) -> Point3D {
        var result: Point3D = .zero
        result.x = self.x * point.x
        result.y = self.y * point.y
        result.z = self.z * point.z
        return result
    }
}
