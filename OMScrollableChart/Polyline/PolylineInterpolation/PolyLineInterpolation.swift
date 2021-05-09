//
//  PolyLineInterpolation.swift
//
//  Created by Jorge Ouahbi on 01/09/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit

public enum PolyLineInterpolation {
       case none
       case smoothed
       case cubicCurve
       case catmullRom(_ alpha: CGFloat)
       case hermite(_ alpha: CGFloat)
       // MARK: - UIBezierPaths -
       func asPath( points: [CGPoint]?) -> UIBezierPath? {
           guard let polylinePoints = points else {
               return nil
           }
           switch self {
           case .none:
               return UIBezierPath(points: polylinePoints, maxYPosition: 0)
           case .smoothed:
               return UIBezierPath(smoothedPoints: polylinePoints, maxYPosition: 0)
           case .cubicCurve:
               return  UIBezierPath(cubicCurvePoints: polylinePoints, maxYPosition: 0)
           case .catmullRom(let alpha):
               return UIBezierPath(catmullRomPoints: polylinePoints, alpha: alpha)
           case .hermite(let alpha):
               return UIBezierPath(hermitePoints: polylinePoints, maxYPosition: 0, alpha: alpha)
           }
       }
   }
   
