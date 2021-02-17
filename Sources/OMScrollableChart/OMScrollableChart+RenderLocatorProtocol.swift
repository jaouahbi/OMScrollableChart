//
//  OMScrollableChart+RenderLocatorProtocol.swift
//  OMScrollableChart
//
//  Created by Jorge Ouahbi on 13/11/2020.
//

import UIKit

public protocol RenderLocatorProtocol {
    func dataIndexFromPointInLayer(_ renderIndex: Int, point: CGPoint) -> Int?
    func dataIndexFromPoint(_ renderIndex: Int, point: CGPoint) -> Int?
    func dataFromPoint(_ renderIndex: Int, point: CGPoint) -> Float?
    func dataStringFromPoint(_ renderIndex: Int, point: CGPoint) -> String?
    func indexForPoint(_ renderIndex: Int, point: CGPoint) -> Int?
    func pointFromIndex(_ renderIndex: Int, index: Int) -> CGPoint?
    func sectionFromPoint(_ renderIndex: Int, layer: CALayer) -> Int
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
        assert(renderIndex < renderSourceNumberOfRenders)
        return RenderManager.shared.renders[renderIndex].data.point(withIndex: index)
    }

    /// indexForPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: Int
    /// - Returns: Int?
    public func indexForPoint(_ renderIndex: Int, point: CGPoint) -> Int? {
        assert(renderIndex < renderSourceNumberOfRenders)
        return RenderManager.shared.renders[renderIndex].data.index(withPoint: point)
    }

    /// dataStringFromPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: Int
    /// - Returns: String?
    
    public func dataStringFromPoint(_ renderIndex: Int, point: CGPoint) -> String? {
        assert(renderIndex < renderSourceNumberOfRenders)
        let renderData = RenderManager.shared.renders[renderIndex].data
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
        return nil
    }
    
    public func dataFromPoint(_ renderIndex: Int, point: CGPoint) -> Float? {
        let render = RenderManager.shared.renders[renderIndex]
        return render.data.data( withPoint: point)
    }

    func renderResolution( with type: RenderType, renderIndex: Int) -> Double {
        let render = RenderManager.shared.renders[renderIndex].data
        return Double(render.data.count) / Double(numberOfSections)
    }
    /// sectionFromPoint
    /// - Parameters:
    ///   - renderIndex: render description
    ///   - layer: layer description
    /// - Returns: description
    
    public func sectionFromPoint(_ renderIndex: Int, layer: CALayer) -> Int {
        let render = RenderManager.shared.renders[renderIndex]
        return sectionFromPoint(render: render, layer: layer)
    }
    /// sectionFromPoint
    /// - Parameters:
    ///   - render: render description
    ///   - layer: layer description
    /// - Returns: description
    
    func sectionFromPoint(render: BaseRender, layer: CALayer) -> Int {
        let dataIndexLayer = render.data.dataIndex( withPoint: layer.position )
        // Get the selection data index
        if let dataIndex = dataIndexLayer {
            let data = render.data
            print("Selected data point index: \(dataIndex) type: \(data.dataType)")
            let pointPerSectionRelation = floor(renderResolution(with: data.dataType, renderIndex: render.index))
            let sectionIndex = Int(floor(Double(dataIndex) / Double(pointPerSectionRelation))) % numberOfSections
            print(
                """
                        Render index: \(Int(render.index))
                        Data index: \(Int(dataIndex))

                        \((ruleManager.footerRule?.views?[sectionIndex] as? UILabel)?.text ?? "")

                        Point to section relation \(pointPerSectionRelation)
                        Section index: \(Int(sectionIndex))
                """)
            
            return sectionIndex
        }
        return Index.bad.rawValue
    }

    /// dataIndexFromPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: index
    /// - Returns: Int?
    
    public func dataIndexFromPoint(_ renderIndex: Int, point: CGPoint) -> Int? {
        assert(renderIndex < renderSourceNumberOfRenders)
        let render = RenderManager.shared.renders[renderIndex]
        return render.data.dataIndex(withPoint: point)
    }
    
    /// dataIndexFromLayers
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: Index
    /// - Returns: Int?
    public func dataIndexFromPointInLayer(_ renderIndex: Int, point: CGPoint) -> Int? {
        assert(renderIndex < renderSourceNumberOfRenders)
        let render = RenderManager.shared.renders[renderIndex]
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
        return nil
    }
}
