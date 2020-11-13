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

public protocol RenderProtocol {
    associatedtype RenderData
    var data: RenderData? {get set} // Points and data touple
    var type: OMScrollableChart.RenderType {get set}
    var layers: [CALayer] {get set}
}


public class Render: RenderProtocol {
    public typealias RenderData = (points: [CGPoint], data: [Float])
    public var data: RenderData? // Points and data touple
    public var type: OMScrollableChart.RenderType = .discrete
    public var layers: [CALayer] = []
    init() {
        
        
    }
}
