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

public class PolylineSimplify {
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

/*
 
 Un desafío interesante en la cartografía es obtener datos de la resolución apropiada.
 Como observó Lewis Fry Richardson, cuanto más precisamente se mide la longitud de una costa, más larga parece;
 las formas geográficas tienen una complejidad infinita.
 Las pantallas digitales, en cambio, están limitadas por los píxeles.
 Elegir una resolución demasiado alta aumenta el tiempo de descarga y retrasa la representación, mientras que una resolución demasiado baja elude los detalles importantes.
 Este desafío se ve exacerbado por los mapas con zoom que desean una geometría de resolución múltiple.
 
 Para simplificar la geometría para que se ajuste a la resolución mostrada, existen varios algoritmos de simplificación de líneas.
 Mientras que Douglas-Peucker es el más conocido, el algoritmo de Visvalingam puede ser más efectivo y tiene una explicación notablemente intuitiva:
 elimina progresivamente los puntos con el cambio menos perceptible. Sorprendentemente, la simplificación a menudo permite la eliminación del 95% o más de los puntos, manteniendo al mismo tiempo suficiente detalle para la visualización. Por ejemplo, el archivo GeoJSON utilizado para dibujar el territorio continental de los Estados Unidos arriba puede ser reducido de 531KB a 27KB con sólo cambios visuales menores.
 
 Para determinar qué punto elimina el menor cambio visible, el algoritmo de Visvalingam calcula triángulos formados por tres puntos sucesivos a lo largo de cada línea; se elimina el punto con el triángulo asociado más pequeño. Después de cada remoción, el área de los triángulos vecinos se vuelve a calcular y se repite el proceso.
 
 Por ejemplo, considera esta línea de seis puntos:
 
 https://bost.ocks.org/mike/simplify/
 
 No hay garantía de que la eliminación de un punto aumente el área de los triángulos adyacentes; por lo tanto, el algoritmo considera el área efectiva como la mayor del triángulo asociado y el triángulo previamente eliminado.
 
 Un desafío relacionado es preservar la topología mientras se simplifica, ¡pero eso es un tema para otro puesto!
 Una de las mejores características del algoritmo de Visvalingam es que el área efectiva puede ser posteriormente almacenada en la geometría. Por ejemplo, un punto puede tener una coordenada z que indique su área efectiva, permitiendo un filtrado eficiente para la simplificación dinámica, incluso cuando el algoritmo se ejecuta en el servidor. En la parte superior de la página se muestra un ejemplo de esta técnica, aunque lo más común es que la simplificación se haga en base al nivel de zoom.
 
 */
class triangle {
    var indices: [Int] = [0, 0, 0]
    var area: CGFloat = 0
    var prev: triangle?
    var next: triangle?
    func compareTri(j: triangle) -> Bool {
        return triangle.compareTri(i: self, j: j)
    }
    class func compareTri(i: triangle, j: triangle) -> Bool {
        // important note here:
        // http://stackoverflow.com/questions/12290479/stdsort-fails-on-stdvector-of-pointers
        if i.area != j.area { return i.area < j.area }
        else { return false }
    }
    // --------------------------------------------------------------
    class func triArea(d0: CGPoint, d1: CGPoint, d2: CGPoint) -> CGFloat {
        let dArea = ((d1.x - d0.x) * (d2.y - d0.y) - (d2.x - d0.x) * (d1.y - d0.y)) / 2.0
        return (dArea > 0.0) ? dArea : -dArea
    }
}

// --------------------------------------------------------------
private func visvalingamSimplifyVV(points: [CGPoint], limit: CGFloat = 1) -> [Point3D] {
    var results = points.map { Point3D(x: $0.x, y: $0.y, z: 0) }
    let total = points.count
    // if we have 100 points, we have 98 triangles to look at
    let nTriangles = total - 2
    var triangles = [triangle](repeating: triangle(), count: nTriangles)
    for index in 1..<total - 1 {
        // for (int i = 1; i < total-1; i++){
        let tempTri = triangle()
        tempTri.indices[0] = index - 1
        tempTri.indices[1] = index
        tempTri.indices[2] = index + 1
        tempTri.area = triangle.triArea(d0: points[tempTri.indices[0]],
                                        d1: points[tempTri.indices[1]],
                                        d2: points[tempTri.indices[2]])
        triangles[index - 1] = tempTri
    }
    // set the next and prev triangles, use NULL on either end. this helps us update traingles that might need to be removed
    // for (int i = 0; i < nTriangles; i++){
    for index in 0..<nTriangles {
        triangles[index].prev = (index == 0 ? nil : triangles[index - 1])
        triangles[index].next = (index == nTriangles - 1 ? nil : triangles[index + 1])
    }
    var trianglesVec = triangles.map { $0 }
    var count: Int = 0
    while !trianglesVec.isEmpty {
        trianglesVec.sort(by: triangle.compareTri)
        if let triangleOnTop = trianglesVec.first {
            results[triangleOnTop.indices[1]].z = CGFloat(total - count)
            // store the "importance" of this point in numerical order of removal
            // (but inverted, so 0 = most improtant, n = least important.  end points are 0.
            count += 1
            if let tri = triangleOnTop.prev {
                tri.next = triangleOnTop.next
                tri.indices[2] = triangleOnTop.indices[2] // check!
                tri.area = triangle.triArea(d0: points[tri.indices[0]],
                                            d1: points[tri.indices[1]],
                                            d2: points[tri.indices[2]])
            }
            if let tri = triangleOnTop.next {
                tri.prev = triangleOnTop.prev
                tri.indices[0] = triangleOnTop.indices.first ?? 0 // check!
                tri.area = triangle.triArea(d0: points[tri.indices[0]],
                                            d1: points[tri.indices[1]],
                                            d2: points[tri.indices[2]])
            }
        }
        trianglesVec.removeFirst()
    }
    
    return results
}
