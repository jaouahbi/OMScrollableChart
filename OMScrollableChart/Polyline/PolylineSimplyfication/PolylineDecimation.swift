// Copyright 2002 softSurfer, 2012 Dan Sunday
// This code may be freely used and modified for any purpose
// providing that this copyright notice is included with it.
// SoftSurfer makes no warranty for this code, and cannot be held
// liable for any real or imagined damage resulting from its use.
// Users of this code must verify correctness for their application.
//
//
// Assume that classes are already given for the objects:
//    Point2D and Vector with
//        coordinates {float x, y, z;}     // as many as are needed
//        operators for:
//            == to test equality
//            != to test inequality
//            (Vector)0 = (0,0,0)         (null vector)
//            Point2D  = Point2D ± Vector
//            Vector = Point2D - Point2D
//            Vector = Vector ± Vector
//            Vector = Scalar * Vector    (scalar product)
//            Vector = Vector * Vector    (cross product)
//    Segment with defining endpoints {Point2D P0, P1;}
//===================================================================

import UIKit

extension CGPoint {
    var point3D: Point3D {
        return Point3D(x: x, y: y, z: 0)
    }
}

//// dot product (3D) which allows vector operations in arguments
// func dot( _ u:Point3D, _ v:Point3D) ->CGFloat {
//    return  u.x*v.x + u.y*v.y;
// }
// func norm2(v:Point3D) ->CGFloat {return dot(v,v) }        // norm2 = squared length of vector
// func norm(v:Point3D) ->CGFloat  {return sqrt(norm2(v: v))  } // norm = length of vector
// func d2(u:Point3D,v:Point3D)  ->CGFloat  {return   norm2(v: u.sub(a: v)) }      // distance squared = norm2 of difference
// func d(u:Point3D,v:Point3D)  ->CGFloat  {return   norm(v: u.sub(a: v))  }      // distance = norm of difference
//

// poly_decimate(): - remove vertices to get a smaller approximate polygon
//    Input:  tol = approximation tolerance
//            V[] = polyline array of vertex points
//            n   = the number of points in V[]
//    Output: sV[]= reduced polyline vertexes (max is n)
//    Return: m   = the number of points in sV[]

//
// class Segment_ {
//    var P0: Point3D
//    var P1: Point3D
//
//    var direction: Point3D {
//        return Point3D(x: P1.x - P0.x, y: P1.y - P0.y, z: P1.z - P0.z);    // segment direction vector
//    }
//
//    init(point1: Point3D, point2: Point3D) {
//        self.P0 = point1
//        self.P1 = point2
//    }
//
//    // pointDistance(): get the distance of a point to a segment
//    //     Input:  a Point2D P and a Segment S (in any dimension)
//    //     Return: the shortest distance from P to S
//    func pointDistance( _ point: Point3D) -> CGFloat {
//        let v = self.P1 - self.P0;
//        let w = point - self.P0;
//        let c1 = dot(w.point3D,v.point3D);
//        if ( c1 <= 0 ) {
//            return d2(point.point3D, self.P0.point3D);
//        }
//
//        let  c2 = dot(v.point3D,v.point3D);
//        if ( c2 <= c1 ) {
//            return d2(point.point3D, self.P1.point3D);
//        }
//
//        let b = c1 / c2;
//        //let Pb = S.P0 + b * v;
//
//        let Pb = self.P0.addScalar(scalar: CGFloat(b)) * v
//
//        return d2(point.point3D, Pb.point3D);
//    }
// }

// ==

// douglasPeckerDecimate():
//  This is the Douglas-Peucker recursive reduction routine
//  It marks vertexes that are part of the reduced polyline
//  for approximating the polyline subchain v[j] to v[k].
//    Input:  tolerance  = approximation tolerance
//            v[]  = polyline array of vertex points
//            j,k  = indices for the subchain v[j] to v[k]
//    Output: marks[] = array of markers matching vertex array v[]
private func douglasPeckerDecimate(_ points: [Point3D],
                           currentSubchainIndex: Int,
                           tolerance: CGFloat = 1.0,
                           currentKeyIndex: Int,
                           marks: inout [Int])
{
    if currentKeyIndex <= currentSubchainIndex+1 { // there is nothing to decimate
        return
    }
    // check for adequate approximation by segment S from v[j] to v[k]
    var maxi = currentSubchainIndex // index of vertex farthest from S
    var maxDistanceSqFarthestPoint: CGFloat = 0 // distance squared of farthest vertex
    let tol2 = tolerance * tolerance // tolerance squared   // tolerance squared
    let segment = Segment3D(P0: points[currentSubchainIndex], P1: points[currentKeyIndex]) // segment from v[j] to v[k]
    var segmentDirection = Point3D(x: 0, y: 0, z: 0) // segment direction vector
    
    // segment direction vector
    
    segmentDirection.x = segment.P1.x - segment.P0.x
    segmentDirection.y = segment.P1.y - segment.P0.y
    segmentDirection.z = 0
    
    let segmentLenSq: CGFloat = segmentDirection.norm() // segment length squared
    
    // test each vertex v[i] for max distance from S
    // compute using the Algorithm dist_Point_to_Segment()
    // Note: this works in any dimension (2D, 3D, ...)
    var distanceSquaredToSegmentPoint0 = Point3D(x: 0, y: 0, z: 0)
    var baseOfPerpendicular: Point3D // base of perpendicular from v[i] to S
    var divSegmentLenSq: CGFloat, cw: CGFloat, dv2: CGFloat // dv2 = distance v[i] to S squared
    
    let from: Int = currentSubchainIndex+1
    
    for currentIndex in stride(from: from, to: currentKeyIndex, by: 1) {
        // compute distance squared
        distanceSquaredToSegmentPoint0.x = points[currentIndex].x - segment.P0.x
        distanceSquaredToSegmentPoint0.y = points[currentIndex].y - segment.P0.y
        distanceSquaredToSegmentPoint0.z = 0
        
        cw = distanceSquaredToSegmentPoint0.dot(point: segmentDirection)
    
        if cw <= 0 {
            dv2 = points[currentIndex].d2(point: segment.P0)
        } else if segmentLenSq <= cw {
            dv2 = points[currentIndex].d2(point: segment.P1)
        } else {
            divSegmentLenSq = cw / segmentLenSq
            let segmentSum = segment.P0.add(scalar: divSegmentLenSq)
            baseOfPerpendicular = segmentSum.mul(point: segmentDirection)
            dv2 = points[currentIndex].d2(point: baseOfPerpendicular)
        }
        // test with current max distance  squared
        if dv2 <= maxDistanceSqFarthestPoint {
            continue
        }
        // v[i] is a new max vertex
        // print(currentIndex, dv2 )
        maxi = currentIndex
        maxDistanceSqFarthestPoint = dv2
    }
    
    if CGFloat(maxDistanceSqFarthestPoint) > tol2 // error is worse than the tolerance
    {
        // split the polyline at the farthest  vertex from S

        marks[maxi] = 1 // mark v[maxi] for the reduced polyline
        // recursively decimate the two subpolylines at v[maxi]
        douglasPeckerDecimate(points,
                              currentSubchainIndex: currentSubchainIndex,
                              tolerance: tolerance,
                              currentKeyIndex: maxi,
                              marks: &marks) // polyline v[j] to v[maxi]
        douglasPeckerDecimate(points,
                              currentSubchainIndex: maxi,
                              tolerance: tolerance,
                              currentKeyIndex: currentKeyIndex,
                              marks: &marks) // polyline v[maxi] to v[k]
        
    } else {
        print("toleranceSq: \(tol2), error: \(maxDistanceSqFarthestPoint)")
    }
    
    // else the approximation is OK, so ignore intermediate vertexes
    // return mk;
}

//===================================================================

func decimateDouglasPeucker(_ srcPoints: [CGPoint], tolerance: CGFloat = 1.0) -> [CGPoint] {
    let numberOfPoints = srcPoints.count
    var keyIndex: Int = 1
    var lastReducedIndex: Int = 0 // misc counters
    let tol2: CGFloat = tolerance * tolerance // tolerance squared
    var reduced = [Point3D](repeating: Point3D(x: 0, y: 0, z: 0), count: numberOfPoints)

    let points = srcPoints.map { Point3D(x: $0.x, y: $0.y, z: 0) }
    var marks = [Int](repeating: 0, count: numberOfPoints)
    
    points.forEach {
        reduced.append($0)
    }
    
    //    Point2D* vt = new Point2D[n];       // vertex buffer
    //    int*   mk = new int[n] = {0};   // marker  buffer
    
    // STAGE 1.  Vertex Reduction within tolerance of  prior vertex clusterg
    reduced[0] = points[0]
    for currentIndex in stride(from: 1, to: numberOfPoints, by: 1) {
        /// print(pv,currentIndex)
        let point = points[currentIndex]
        
        let distanceSq = point.d2(point: points[lastReducedIndex])
        // print("i: \(currentIndex) pv: \(pv) distanceSq: \(distanceSq)");
        if distanceSq < tol2 {
            // print("tolerance: \(toleranceSq) > \(distanceSq)")
            continue
        }
     
        reduced[keyIndex] = point
        keyIndex += 1
        // print("keyIndex: \(keyIndex) \(currentIndex)")
        lastReducedIndex = currentIndex
    }
    
    if lastReducedIndex < numberOfPoints - 1 {
        reduced[keyIndex] = points[numberOfPoints - 1]
        keyIndex += 1
        // finish at the end
    }
    
    let newReduced = Array(reduced.prefix(keyIndex))
    marks = newReduced.map { _ in 0 }

    // STAGE 2.  Douglas-Peucker polyline reduction
    marks[0] = 0 //  mark the first and last vertexes
    marks[keyIndex - 1] = 1

    douglasPeckerDecimate(newReduced, currentSubchainIndex: 0, tolerance: tolerance, currentKeyIndex: keyIndex - 1, marks: &marks)
    
    assert(marks.count == newReduced.count)
    // create a new array with series, only take the kept ones
    var newPoints = newReduced.enumerated().compactMap { (index: Int, point: Point3D) -> CGPoint? in
        marks[index] == 1 ? CGPoint(x: point.x, y: point.y) : nil
    }
    // add te first point
    newPoints.insert(CGPoint(x: reduced[0].x, y: reduced[0].y), at: 0)

    return newPoints // m vertices in reduced polyline
}
