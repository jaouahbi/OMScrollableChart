// Copyright 2018 Jorge Ouahbi
//
// Licensed under the Apache License, Version 2.0 (the "License")
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
// https://pdfs.semanticscholar.org/e46a/c802d7207e0e51b5333456a3f46519c2f92d.pdf?_ga=2.64722092.2053301206.1583599184-578282909.1583599184
// https://breki.github.io/line-simplify.html

import Foundation
import UIKit

public class OMSimplify {
    // square distance between 2 points
    // distanceToLine
    private class func getSqDist(_ point1: CGPoint, point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x,
            dy = point1.y - point2.y
        return dx * dx + dy * dy
    }
    
    // square distance from a point to a segment
    // distanceToSegment
    private class func getSqSegDist(_ point0: CGPoint, p1: CGPoint, p2: CGPoint) -> CGFloat {
        var originX = p1.x,
            originY = p1.y,
            dx = p2.x - originX,
            dy = p2.y - originY
        if dx != 0 || dy != 0 {
            let resultT = ((point0.x - originX) * dx + (point0.y - originY) * dy) / (dx * dx + dy * dy)
            if resultT > 1 {
                originX = p2.x
                originY = p2.y
            } else if resultT > 0 {
                originX += dx * resultT
                originY += dy * resultT
            }
        }
        dx = point0.x - originX
        dy = point0.y - originY
        return dx * dx + dy * dy
    }
    
    // basic distance-based simplification
    class func simplifyRadialDist(_ points: [CGPoint], sqTolerance: CGFloat) -> [CGPoint] {
        var prevPoint = points[0]
        var newPoints: [CGPoint] = [prevPoint]
        let point: CGPoint = .zero
        points.forEach { point in
            // start index = 1
            if getSqDist(point, point2: prevPoint) > sqTolerance {
                newPoints.append(point)
                prevPoint = point
            }
        }
        if prevPoint != point {
            newPoints.append(point)
        }
        return newPoints
    }
    
    private class func simplifyDPStep(_ points: [CGPoint], first: Int, last: Int, sqTolerance: CGFloat, simplified: inout [CGPoint]) {
        var maxSqDist: CGFloat = 0
        var index = 0
        for currentIndex in stride(from: first + 1, to: last, by: 1) {
            let sqDist = getSqSegDist(points[currentIndex], p1: points[first], p2: points[last])
            if sqDist > maxSqDist {
                index = currentIndex
                maxSqDist = sqDist
            }
        }
        // print(maxSqDist, sqTolerance)
        if maxSqDist > sqTolerance {
            if index - first > 1 { simplifyDPStep(points, first: first, last: index, sqTolerance: sqTolerance, simplified: &simplified) }
            simplified.append(points[index])
            if last - index > 1 { simplifyDPStep(points, first: index, last: last, sqTolerance: sqTolerance, simplified: &simplified) }
        }
    }
    
    // simplification using Ramer-Douglas-Peucker algorithm
    private class func simplifyDouglasPeucker(_ points: [CGPoint], tolerance: CGFloat) -> [CGPoint] {
        let last = points.count - 1
        var simplified = [points[0]]
        simplifyDPStep(points, first: 0, last: last, sqTolerance: tolerance, simplified: &simplified)
        simplified.append(points[last])
        return simplified
    }
    // MARK: - public -
    
    // both algorithms combined for awesome performance
    class func simplifyDouglasPeuckerRadial(_ points: [CGPoint], tolerance: CGFloat?, highestQuality: Bool = true) -> [CGPoint] {
        if points.count <= 2 { return points }
        let sqTolerance: CGFloat = (tolerance != nil) ? tolerance! * tolerance! : 1
        var newPoints = highestQuality ? points : simplifyRadialDist(points, sqTolerance: sqTolerance)
        newPoints = simplifyDouglasPeucker(newPoints, tolerance: sqTolerance)
        return newPoints
    }
    
    // Remove vertices to get a smaller approximate polygon
    class func simplifyDouglasPeuckerDecimate(_ points: [CGPoint], tolerance: CGFloat = 1) -> [CGPoint] {
        // let xxx = simplify2(points)
        if points.count <= 2 { return points }
        return decimateDouglasPeucker(points, tolerance: tolerance)
    }
    
    class func visvalingamSimplify(_ points: [CGPoint], limit: CGFloat = 2) -> [CGPoint] {
        // let xxx = simplify2(points)
        if points.count <= 2 { return points }
        let result = visvalingamSimplifyVV(points: points, limit: limit)
        let resultFltr = result.filter { $0.z == 0 || $0.z > limit }
        return resultFltr.map { CGPoint(x: $0.x, y: $0.y) }
    }
}
