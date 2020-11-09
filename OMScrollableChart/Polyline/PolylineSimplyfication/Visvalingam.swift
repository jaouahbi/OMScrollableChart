//
//  visvalingam.swift
//
//  Created by Jorge Ouahbi on 09/11/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

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
public class triangle {
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
public func visvalingamSimplifyVV(points: [CGPoint], limit: CGFloat = 1) -> [Point3D] {
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
