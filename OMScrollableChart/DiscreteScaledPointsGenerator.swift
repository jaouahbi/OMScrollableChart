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

//
//  OMScrollableChart
//
//  Created by Jorge Ouahbi on 16/08/2020.


import UIKit
import Accelerate

//protocol ScaledPointsGeneratorProtocol {
//    var maximumValue: Float {get}
//    var minimumValue: Float {get}
//    var insets: UIEdgeInsets {get set}
//    var minimum: Float?  {get set}
//    var maximum: Float?  {get set}
//    var range: Float  {get}
//    var hScale: CGFloat  {get}
//
//    var points: [CGPoint]  {get }
//    func makePoints() -> [CGPoint]
//    func updateRangeLimits()
//}
//
//extension ScaledPointsGeneratorProtocol {
//    var hScale: CGFloat  {return 1.0}
//    var minimum: Float?  {return nil }
//    var maximum: Float?  {return nil }
//    var range: Float {
//        return maximumValue - minimumValue
//    }
//    var points: [CGPoint] {
//        return makePoints()
//    }
//}

protocol ScaledPointsGeneratorProtocol {
    var maximumValue: Float {get}
    var minimumValue: Float {get}
    var insets: UIEdgeInsets {get set}
    var minimum: Float?  {get set}
    var maximum: Float?  {get set}
    var range: Float  {get}
    var hScale: CGFloat  {get}
    var isLimitsDirty: Bool {get set}
    
    func makePoints(data: [Float], size: CGSize) -> [CGPoint]
    func updateRangeLimits(_ data: [Float])
}

// Default values.
extension ScaledPointsGeneratorProtocol {
    var hScale: CGFloat  {return 1.0}
    var minimum: Float?  {return nil }
    var maximum: Float?  {return nil }
    var range: Float {
        return maximumValue - minimumValue
    }
}
// MARK: - DiscreteScaledPointsGenerator -
class DiscreteScaledPointsGenerator: ScaledPointsGeneratorProtocol {
    var insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    var isLimitsDirty: Bool = true
    private(set) var maximumValue: Float = 0
    private(set) var minimumValue: Float = 0
    var minimum: Float? = nil {
        didSet {
            isLimitsDirty = true
        }
    }
    var maximum: Float? = nil {
        didSet {
            isLimitsDirty = true
        }
    }
    internal func updateRangeLimits(_ data: [Float]) {
        guard isLimitsDirty else {
            return
        }
        // Normalize values in array (i.e. scale to 0-1)...
        var min: Float = 0
        if let minimum = minimum {
            min = minimum
        } else {
            vDSP_minv(data, 1, &min, vDSP_Length(data.count))
        }
        minimumValue = min
        var max: Float = 0
        if let maximum = maximum {
            max = maximum
        } else {
            vDSP_maxv(data, 1, &max, vDSP_Length(data.count))
        }
        maximumValue = max
        isLimitsDirty = false
    }
    func makePoints(data: [Float], size: CGSize) -> [CGPoint] {
        if isLimitsDirty {
            updateRangeLimits(data)
        }
        // claculate the size
        let insetHeight   = (insets.bottom + insets.top)
        let insetWidth    = (insets.left + insets.right)
        let insetY        =  insets.top
        let insetX        =  insets.left
        // the size
        let newSize  = CGSize(width: size.width - insetWidth,
                             height: size.height - insetHeight)
        var scale = 1 / self.range
        var minusMin = -minimumValue
        var scaled = [Float](repeating: 0, count: data.count)
        //        for (n = 0; n < N; ++n)
        //           scaled[n] = (A[n] + B[n]) * C;
        vDSP_vasm(data, 1, &minusMin, 0, &scale, &scaled, 1, vDSP_Length(data.count))
        let xScale = newSize.width / CGFloat(data.count)
        return scaled.enumerated().map {
            return CGPoint(x: xScale * hScale * CGFloat($0.offset) + insetX,
                           y: (newSize.height * CGFloat(1.0 - ($0.element.isFinite ? $0.element : 0))) + insetY)
        }
    }
}


// MARK:  ScaledPointsGenerator -

class ScaledPointsGenerator: DiscreteScaledPointsGenerator {
    var data: [Float]! {
        didSet {
            isLimitsDirty = true
        }
    }
    var size: CGSize! {
        didSet {
            isLimitsDirty = true
        }
    }
    public init(_ data: [Float], size: CGSize, insets: UIEdgeInsets = .zero) {
        super.init()
        self.data = data
        self.size = size
        self.insets = insets
        updateRangeLimits()
    }
    internal func updateRangeLimits() {
        // Normalize values in array (i.e. scale to 0-1)...
        super.updateRangeLimits(data)
    }
    internal func makePoints() -> [CGPoint] {
        // claculate the size
        return self.makePoints(data: data, size: size)
    }
}


// MARK: - DiscreteLogaritmicScaledPointsGenerator -
class DiscreteLogaritmicScaledPointsGenerator: DiscreteScaledPointsGenerator {
//    internal func updateRangeLimits(_ data: [Float]) {
//        guard isLimitsDirty else {
//            return
//        }
//        // Normalize values in array (i.e. scale to 0-1)...
//        var min: Float = 0
//        if let minimum = minimum {
//            min = minimum
//        } else {
//            vDSP_minv(data, 1, &min, vDSP_Length(data.count))
//        }
//        minimumValue = min
//        var max: Float = 0
//        if let maximum = maximum {
//            max = maximum
//        } else {
//            vDSP_maxv(data, 1, &max, vDSP_Length(data.count))
//        }
//        maximumValue = max
//        isLimitsDirty = false
//    }
    override func makePoints(data: [Float], size: CGSize) -> [CGPoint] {
        if isLimitsDirty {
            updateRangeLimits(data)
        }
        // claculate the size
        let insetHeight   = (insets.bottom + insets.top)
        let insetWidth    = (insets.left + insets.right)
        let insetY        =  insets.top
        let insetX        =  insets.left
        // the size
        let newSize  = CGSize(width: size.width - insetWidth,
                             height: size.height - insetHeight)
        var scale = 1 / self.range
        var minusMin = -minimumValue
        var scaled = [Float](repeating: 0, count: data.count)
        //        for (n = 0; n < N; ++n)
        //           scaled[n] = (A[n] + B[n]) * C;
        vDSP_vasm(data, 1, &minusMin, 0, &scale, &scaled, 1, vDSP_Length(data.count))
        let xScale = newSize.width / CGFloat(data.count)
        return scaled.enumerated().map {
            return CGPoint(x: xScale * hScale * CGFloat($0.offset) + insetX,
                           y: (newSize.height * CGFloat(1.0 - ($0.element.isFinite ? $0.element : 0))) + insetY)
        }
    }
}

func log_position(value: Double) -> Double {
    // position will be between 0 and 100
    var minp = 0.0;
    var maxp = 100.0;
    
    // The result should be between 100 an 10000000
    var minv = log(100.0)
    var maxv = log(10000000.9)
    // calculate adjustment factor
    var scale = (maxv-minv) / (maxp-minp);
    
    return (log(value)-minv) / scale + minp;
}
func log_value(position: Double ) -> Double {
  // position will be between 0 and 100
    var minp = 0.0;
    var maxp = 100.0;

  // The result should be between 100 an 10000000
    var minv = log(100.0)
    var maxv = log(10000000.9)

  // calculate adjustment factor
  var scale = (maxv-minv) / (maxp-minp);

  return exp(minv + scale * (position-minp));
}
