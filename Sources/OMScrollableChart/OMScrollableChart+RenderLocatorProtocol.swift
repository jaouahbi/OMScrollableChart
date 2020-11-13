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
    func dataFromPoint( _ renderIndex: Int, point: CGPoint) -> Float?
    func dataStringFromPoint(_ renderIndex: Int, point: CGPoint) -> String?
    func indexForPoint(_ renderIndex: Int, point: CGPoint) -> Int?
    func pointFromIndex(_ renderIndex: Int, index: Int) -> CGPoint?
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
        assert(index < pointsRender[renderIndex].count)
        
        return pointsRender[renderIndex][index]
    }
    /// indexForPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: Int
    /// - Returns: Int?
    public func indexForPoint(_ renderIndex: Int, point: CGPoint) -> Int? {
        assert(renderIndex < renderSourceNumberOfRenders)
        switch self.renderType[renderIndex] {
        case .discrete:
            return discreteData[renderIndex]?.points.map { $0.distance(from: point) }.indexOfMin
        case .mean:
            return meanData[renderIndex]?.points.map { $0.distance(from: point) }.indexOfMin
        case .approximation:
            return approximationData[renderIndex]?.points.map { $0.distance(from: point) }.indexOfMin
        case .linregress:
            return linregressData[renderIndex]?.points.map { $0.distance(from: point) }.indexOfMin
        }
    }
    /// dataStringFromPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: Int
    /// - Returns: String?
    
    public func dataStringFromPoint(_ renderIndex: Int, point: CGPoint) -> String? {
        assert(renderIndex < renderSourceNumberOfRenders)
        switch self.renderType[renderIndex] {
        case .mean:
            if let render = meanData[renderIndex],
               let firstIndex = indexForPoint( renderIndex, point: point)
            {
                let item = Double(render.data[firstIndex])
                if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                    return currentStep
                }
            }
        case .discrete:
            if let render = discreteData[renderIndex],
                let firstIndex = render.points.firstIndex(of: point)
            {
                let item = Double(render.data[firstIndex])
                if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                    return currentStep
                }
            }
        case .approximation:
            if let render = approximationData[renderIndex],
                let firstIndex = render.points.firstIndex(of: point)
            {
                let item = Double(render.data[firstIndex])
                if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                    return currentStep
                }
            }
        case .linregress:
            if let render = linregressData[renderIndex],
                let firstIndex = render.points.firstIndex(of: point)
            {
                let item = Double(render.data[firstIndex])
                if let currentStep = numberFormatter.string(from: NSNumber(value: item)) {
                    return currentStep
                }
            }
        }
        return nil
    }
    
    /// dataFromPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: Index
    /// - Returns: Float?
    
    public func dataFromPoint( _ renderIndex: Int, point: CGPoint) -> Float? {
        assert(renderIndex < renderSourceNumberOfRenders)
        switch self.renderType[renderIndex] {
        case .discrete:
            if let render = self.discreteData[renderIndex] {
                if let firstIndex = render.points.firstIndex(of: point) {
                    return render.data[firstIndex]
                }
            }
        case .mean:
            if let render = self.meanData[renderIndex] {
                if let firstIndex = indexForPoint( renderIndex, point: point) {
                    return render.data[firstIndex]
                }
            }
        case .approximation:
            if let render = self.approximationData[renderIndex] {
                if let firstIndex = render.points.firstIndex(of: point) {
                    return render.data[firstIndex]
                }
            }
        case .linregress:
            if let render = self.linregressData[renderIndex] {
                if let firstIndex = render.points.firstIndex(of: point) {
                    return render.data[firstIndex]
                }
            }
        }
        return nil
        // return dataIndexFromLayers(point, renderIndex: renderIndex)
    }
    
    /// dataIndexFromPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: index
    /// - Returns: Int?
    
    public func dataIndexFromPoint(_ renderIndex: Int, point: CGPoint) -> Int? {
        assert(renderIndex < renderSourceNumberOfRenders)
        switch self.renderType[renderIndex] {
        case .discrete:
            if let render = discreteData[renderIndex] {
                if let firstIndex = render.points.firstIndex(of: point) {
                    return firstIndex
                }
            }
        case .mean:
            if let firstIndex = indexForPoint( renderIndex, point: point) {
                return firstIndex
            }
        case .approximation:
            if let render = self.approximationData[renderIndex] {
                if let firstIndex = render.points.firstIndex(of: point) {
                    return firstIndex
                }
            }
        case .linregress:
            if let render = self.linregressData[renderIndex] {
                if let firstIndex = render.points.firstIndex(of: point) {
                    return firstIndex
                }
            }
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
        switch self.renderType[renderIndex] {
        case .mean(_):
            if let firstIndex = indexForPoint(renderIndex, point: point) {
                return firstIndex
            }
        case .approximation(_), .linregress(_), .discrete:
            if let layersPathContains = renderLayers[renderIndex].filter({
                $0.path!.contains(point)
            }).first {
                return renderLayers[renderIndex].firstIndex(of: layersPathContains)
            }
        }
        return nil
    }
    
}
