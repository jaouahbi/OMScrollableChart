// Copyright 2018 Jorge Ouahbi
//
// Licensed under the Apache License, Version 2.0 (the "License");
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
