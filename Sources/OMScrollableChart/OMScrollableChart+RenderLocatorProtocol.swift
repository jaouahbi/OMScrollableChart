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

public protocol RenderLocatorProtocol {
    func dataIndexFromPointInLayer(_ renderIndex: Int, point: CGPoint) -> Int?
    func dataIndexFromPoint(_ renderIndex: Int, point: CGPoint) -> Int?
    func dataFromPoint(_ renderIndex: Int, point: CGPoint) -> Float?
    func dataStringFromPoint(_ renderIndex: Int, point: CGPoint) -> String?
    func indexForPoint(_ renderIndex: Int, point: CGPoint) -> Int?
    func pointFromIndex(_ renderIndex: Int, index: Int) -> CGPoint?
    func sectionIndexFromLayer(_ renderIndex: Int, layer: CALayer) -> Int
}


public enum Index: Int {
    case bad = -1
}


// MARK: - RenderLocatorProtocol -

extension OMScrollableChart: RenderLocatorProtocol {

    /// Get  render point from index.
    /// - Parameters:
    ///   - renderIndex: Render index
    ///   - index: index point in render index ´renderIndex´
    /// - Returns: CGPoint or nil if point not found
    public func pointFromIndex(_ renderIndex: Int, index: Int) -> CGPoint? {

        let result = engine.renders[renderIndex].data.point(withIndex: index)
        assert((result != nil))
        return result
    }

    /// indexForPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: Int
    /// - Returns: Int?
    public func indexForPoint(_ renderIndex: Int, point: CGPoint) -> Int? {

        let result = engine.renders[renderIndex].data.index(withPoint: point)
        assert((result != nil))
        return result
    }

    /// dataStringFromPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: Int
    /// - Returns: String?
    
    public func dataStringFromPoint(_ renderIndex: Int, point: CGPoint) -> String? {

        let renderData = engine.renders[renderIndex].data
        switch renderData.dataType {
        case .stadistics:
            if let firstIndex = renderData.index(withPoint: point) {
                let item = renderData.data[firstIndex]
                    if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                        return currentStep
                    }
                
            }
        case .discrete:
            if let firstIndex = renderData.points.firstIndex(of: point) {
                let item = renderData.data[firstIndex]
                    if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                        return currentStep
                    }
                
            }
        case .simplify:
            if let firstIndex = renderData.points.firstIndex(of: point) {
                 let item = renderData.data[firstIndex]
                    if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                        return currentStep
                    }
                
            }
        case .regress:
            if let firstIndex = renderData.points.firstIndex(of: point) {
                 let item = renderData.data[firstIndex]
                    if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                        return currentStep
                    }
                
            }
        }
        assert(false)
        return nil
    }
    
    public func dataFromPoint(_ renderIndex: Int, point: CGPoint) -> Float? {
        let render = engine.renders[renderIndex]
        let result =  render.data.data( withPoint: point)
        assert((result != nil))
        return result
    }

    func renderResolution( renderIndex: Int) -> Double {
        let render = engine.renders[renderIndex].data
        return Double(render.data.count) / Double(numberOfSections)
    }
    /// sectionIndexFromLayer
    /// - Parameters:
    ///   - renderIndex: render description
    ///   - layer: layer description
    /// - Returns: description
    
    public func sectionIndexFromLayer(_ renderIndex: Int, layer: CALayer) -> Int {
        let render = engine.renders[renderIndex]
        let result =  sectionIndexFromLayer(render, layer: layer)
        assert((result != 0))
        return result
        
    }
    /// sectionIndexFromLayer
    /// - Parameters:
    ///   - render: render description
    ///   - layer: layer description
    /// - Returns: description
    public func sectionIndexFromLayer(_ render: BaseRender, layer: CALayer) -> Int {
        let result = render.sectionIndex(withPoint: layer.position,
                                   numberOfSections: numberOfSections)
        assert((result != 0))
        return result
    }
  
    /// dataIndexFromPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: index
    /// - Returns: Int?
    
    public func dataIndexFromPoint(_ renderIndex: Int, point: CGPoint) -> Int? {

        let render = engine.renders[renderIndex]
        let result = render.data.dataIndex(withPoint: point)
        assert((result != nil))
        return result
    }
    
    /// dataIndexFromLayers
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: Index
    /// - Returns: Int?
    public func dataIndexFromPointInLayer(_ renderIndex: Int, point: CGPoint) -> Int? {

        let render = engine.renders[renderIndex]
        let data = render.data
        switch data.dataType {
        case .stadistics:
            if let firstIndex = indexForPoint(renderIndex, point: point) {
                return firstIndex
            }
        case .simplify(_,_), .regress(_), .discrete:
            if let layersPathContains = render.layers.filter({
                $0.path!.contains(point)
            }).first {
                return render.layers.firstIndex(of: layersPathContains)
            }
        }
        assert(false)
        return nil
    }
}
