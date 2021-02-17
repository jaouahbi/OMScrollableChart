//
//  File.swift
//  OMScrollableChart
//
//  Created by Jorge Ouahbi on 14/11/2020.
//

import UIKit
import LibControl

public extension OMScrollableChart {
    

    
    func simplifyPoints( points: [CGPoint],
                                  type: SimplifyType,
                                  tolerance: CGFloat) -> [CGPoint]? {
        guard tolerance != 0, points.isEmpty == false else {
            return nil
        }
        switch type {
        case .none:
            return nil
        case .douglasPeuckerRadial:
            return  OMSimplify.douglasPeuckerRadialSimplify(points, tolerance: CGFloat(tolerance), highestQuality: true)
        case .douglasPeuckerDecimate:
            return OMSimplify.douglasPeuckerDecimateSimplify(points, tolerance: tolerance )
        case .visvalingam:
            return OMSimplify.visvalingamSimplify(points, limit: tolerance * tolerance)
        case .ramerDouglasPeuckerPerp:
            return OMSimplify.ramerDouglasPeuckerSimplify(points, epsilon: Double(tolerance * tolerance))
        }
    }
    
}
