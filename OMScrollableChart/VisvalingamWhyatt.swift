//
//  VisvalingamWhyatt.swift
//  Example
//
//  Created by dsp on 15/03/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

// swiftlint:disable identifier_name
class Triangle {
    init() {
        
    }
    var indices = [Int].init(repeating: 0, count: 3)
    var area: Float = 0
    var prev:Int = -1
    var next:Int = -1

}
func isCollinear(a:CGPoint, b:CGPoint, c:CGPoint) -> Bool {
    return (a.y - b.y) * (a.x - c.x) == (a.y - c.y) * (a.x - b.x);
}
func getArea(a:CGPoint, b:CGPoint, c:CGPoint) -> Float
{
    guard !isCollinear(a: a,b: b,c: c) else {
        return 0
    }
//    let ab = a.distance( from:b);
//    let bc = c.distance( from:b);
//    let ca = a.distance( from:c);
//    let s = (ab + bc + ca) / 2;
//    let cc = s * (s - ab) * (s - bc) * (s - ca)
//    let p = Float(sqrt(cc))
    let area = (a.x-c.x)*(b.y-a.y) - (a.x-b.x)*(c.y-a.y)
    print(area)
    return Float(abs(area) * 0.5)
}

public class VisvalingamWhyatt {

    init() {
        
    }

//
//    func compareTri (  i:Triangle,  j:Triangle) -> Bool {
//
//        // important note here:
//        // http://stackoverflow.com/questions/12290479/stdsort-fails-on-stdvector-of-pointers
//
//        if (i.area != j.area) {
//            return i.area < j.area;
//        }
//
//        return false;
//
//    }

    //--------------------------------------------------------------
    func  triArea(  d0:CGPoint, d1:CGPoint, d2:CGPoint) -> Float
    {
        let dArea = ((d1.x - d0.x)*(d2.y - d0.y) - (d2.x - d0.x)*(d1.y - d0.y))/2.0
        return (dArea > 0.0) ? Float(dArea) : Float(-dArea);
    }

    //--------------------------------------------------------------
    func simplify( _ points: [CGPoint]) ->  [CGPoint] {

     let total = points.count;
        var results = [Point3D].init(repeating: Point3D(x: 0, y:0, z:0), count: total)


   


        // if we have 100 points, we have 98 triangles to look at
        let nTriangles = total - 2;

        let  triangles = [Triangle].init(repeating: Triangle(), count: nTriangles)
        
        for i in stride(from: 1, to: total-1, by: 1) {

    //    for (int i = 1; i < total-1; i++){
            
            triangles[i-1].indices[0] = i-1;
            triangles[i-1].indices[1] = i;
            triangles[i-1].indices[2] = i+1;
            triangles[i-1].area = getArea( a: points[triangles[i-1].indices[0]],
                                           b: points[triangles[i-1].indices[1]],
                                           c: points[triangles[i-1].indices[2]]);
        }

    triangles.enumerated().forEach({
            triangles[$0.offset].prev = ($0.offset == 0 ? -1 : $0.offset-1);
            triangles[$0.offset].next = ($0.offset == triangles.count-1 ? -1 : $0.offset+1);
        })
        // set the next and prev triangles, use NULL on either end. this helps us update traingles that might need to be removed
//        for (int i = 0; i < nTriangles; i++){
//            triangles[i]->prev = (i == 0 ? NULL : triangles[i-1]);
//            triangles[i]->next = (i == nTriangles-1 ? NULL : triangles[i+1]);
//        }

        var trianglesVec = triangles.map({$0})

//        for (int i = 0; i < nTriangles; i++){
//            trianglesVec.append(triangles[i]);
//        }



        var count = 0;
        while ( !trianglesVec.isEmpty ){

            
            trianglesVec = trianglesVec.sorted{
                if ($0.area != $1.area) {
                    return $0.area < $1.area
                }
                
                return true
            }

            let tri = trianglesVec[0];

            // store the "importance" of this point in numerical order of
                //removal (but inverted, so 0 = most improtant, n = least important.  end points are 0.
            
            results[tri.indices[1]].z = CGFloat(total - count);
    
            count += 2


            if (tri.prev != -1) {
                let currentPrev = triangles[tri.prev]
                currentPrev.next = tri.next
                currentPrev.indices[2] = tri.indices[2]  // check!

                currentPrev.area = getArea(      a: points[currentPrev.indices[0]],
                                                 b: points[currentPrev.indices[1]],
                                                 c: points[currentPrev.indices[2]]);

            }

            if (tri.next != -1) {
                  let currentNext = triangles[tri.next]
                currentNext.prev = tri.prev;
                currentNext.indices[0] = tri.indices[0];  // check!


                currentNext.area = getArea(      a: points[currentNext.indices[0]],
                                                 b: points[currentNext.indices[1]],
                                                 c: points[currentNext.indices[2]]);


            }

            trianglesVec.removeFirst()



        }

//        // free the memory we just allocated above.
//        for (int i = 0; i < nTriangles; i++){
//            delete triangles[i];
//        }


        let r =  results.map{$0.z}
        r.forEach{print($0)}
        return results.map{CGPoint(x:$0.x,y:$0.y)}
    }

}
// swiftlint:enable identifier_name
