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
        let render = RenderManager.shared.renders[renderIndex].data
        switch render.dataType {
        case .discrete:
            return render.index(from: point)
        case .stadistics:
            return render.index(from: point)
        case .simplify:
            return render.index(from: point)
        case .regress:
            return render.index(from: point)
        }
    }

    /// dataStringFromPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: Int
    /// - Returns: String?
    
    public func dataStringFromPoint(_ renderIndex: Int, point: CGPoint) -> String? {
        assert(renderIndex < renderSourceNumberOfRenders)
        let render = RenderManager.shared.renders[renderIndex].data
        switch render.dataType {
        case .stadistics:
            if let firstIndex = render.index(from: point) {
                let item = render.data[firstIndex]
                    if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                        return currentStep
                    }
                
            }
        case .discrete:
            if let firstIndex = render.points.firstIndex(of: point) {
                let item = render.data[firstIndex]
                    if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                        return currentStep
                    }
                
            }
        case .simplify:
            if let firstIndex = render.points.firstIndex(of: point) {
                 let item = render.data[firstIndex]
                    if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                        return currentStep
                    }
                
            }
        case .regress:
            if let firstIndex = render.points.firstIndex(of: point) {
                 let item = render.data[firstIndex]
                    if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                        return currentStep
                    }
                
            }
        }
        return nil
    }
    /// Make raw discrete points
    /// - Parameters:
    ///   - data: Data
    ///   - size: CGSize
    /// - Returns: Array of discrete CGPoint
//    func makeRawPoints(_ data: [Float], size: CGSize) -> [CGPoint] {
//        assert(size != .zero)
//        assert(!data.isEmpty)
//        return DiscreteScaledPointsGenerator(data: data).makePoints(data: data, size: size)
//    }
//
//    internal var renderSourceNumberOfRenders: Int {
//        if let render = renderSource {
//            return render.numberOfRenders
//        }
//        return 0
//    }
    
    public func dataFromPoint(_ renderIndex: Int, point: CGPoint) -> Float? {
        let data = RenderManager.shared.renders[renderIndex].data
        return dataFromPoint(data, point: point)
    }
    
    /// dataFromPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: Index
    /// - Returns: Float?
    
    public func dataFromPoint(_ renderData: DataRender, point: CGPoint) -> Float? {
        switch renderData.dataType {
        case .discrete:
            if let firstIndex = renderData.points.firstIndex(of: point) {
                return renderData.data[firstIndex]
            }
        case .stadistics:
            if let firstIndex = renderData.points.map({ $0.distance(point) }).mini {
                return renderData.data[firstIndex]
            }
        case .simplify:
            if let firstIndex = renderData.points.firstIndex(of: point) {
                return renderData.data[firstIndex]
            }
        case .regress:
            if let firstIndex = renderData.points.firstIndex(of: point) {
                return renderData.data[firstIndex]
            }
        }
        return nil
        // return dataIndexFromLayers(point, renderIndex: renderIndex)
    }
    

    func renderResolution( with type: RenderType, renderIndex: Int) -> Double {
        let render = RenderManager.shared.renders[renderIndex].data
        return Double(render.data.count) / Double(numberOfSections)
    }
    func sectionFromPoint(renderIndex: Int, layer: CALayer) -> Int {
        let data = RenderManager.shared.renders[renderIndex].data
        let dataIndexLayer = dataIndexFromPoint(renderIndex, point: layer.position)
        // Get the selection data index
        if let dataIndex = dataIndexLayer {
            print("Selected data point index: \(dataIndex) type: \(data.dataType)")
            let pointPerSectionRelation = floor(renderResolution(with: data.dataType, renderIndex: renderIndex))
            let sectionIndex = Int(floor(Double(dataIndex) / Double(pointPerSectionRelation))) % numberOfSections
            print(
                """
                Render index: \(Int(renderIndex))
                Data index: \(Int(dataIndex))

                Point to section relation \(pointPerSectionRelation)
                Section index: \(Int(sectionIndex))
                """)
            
            return sectionIndex
        }
        
        return Index.bad.rawValue
    }
    
    //   \((ruleManager.footerRule?.views?[sectionIndex] as? UILabel)?.text ?? "")

    /// dataIndexFromPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: index
    /// - Returns: Int?
    
    public func dataIndexFromPoint(_ renderIndex: Int, point: CGPoint) -> Int? {
        assert(renderIndex < renderSourceNumberOfRenders)
        let render = RenderManager.shared.renders[renderIndex].data
        switch render.dataType {
        case .discrete:
            // if let render = RenderManager.shared.renders[renderIndex] {
            if let firstIndex = render.points.firstIndex(of: point) {
                return firstIndex
            }
        // }
        case .stadistics:
            if let firstIndex = render.index(from :point) {
                return firstIndex
            }
        case .simplify:
            // if let render = RenderManager.shared.renders[renderIndex] {
            if let firstIndex = render.points.firstIndex(of: point) {
                return firstIndex
            }
        // }
        case .regress:
            // if let render = RenderManager.shared.renders[renderIndex] {
            if let firstIndex = render.points.firstIndex(of: point) {
                return firstIndex
            }
            // }
        }
        return nil // dataIndexFromLayers(point, renderIndex: renderIndex)
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
