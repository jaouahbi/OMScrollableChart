//
//  RenderManager.swift
//  OMScrollableChart
//
//  Created by Jorge Ouahbi on 17/02/2021.
//

import UIKit
import LibControl

/*
 
 Host           Renders
 [SC]  --->   |  ---- Polyline
 (Data)  |  ---- Points
 |  ---- Selected point
 
 | ---- Base custom render
 
 
 
 */


// MARK: Default renders idents
public enum RenderIdent: Int {
    case polyline       = 0
    case points         = 1
    case selectedPoint   = 2
    case base     = 3  //  public renders base index
}

public enum SimplifyType {
    case none
    case douglasPeuckerRadial
    case douglasPeuckerDecimate
    case visvalingam
    case ramerDouglasPeuckerPerp
}

public enum RenderDataType: Equatable {
    case discrete
    case stadistics(CGFloat)
    case simplify(SimplifyType, CGFloat)
    case regress(Int)
}

typealias RenderType = RenderDataType

// MARK: Default renders idents
public enum RenderIdentify: Int {
    case polyline        = 0
    case points          = 1
    case selectedPoint   = 2
    case base            = 3  //  public renders base index
}

public struct DataRender  {
    static var empty: DataRender = DataRender(data: [], points: [])
    internal var output: [CGPoint] = []
    internal var input: [Float] = []
    // tipo de render
    private var type: RenderType = .discrete
    init( data: [Float], points: [CGPoint], type: RenderType = RenderType.discrete) {
        self.input = data
        self.output = points
        self.type = type
    }
    init(  points: [CGPoint]) {
        input = []
        type = .discrete
        output = points
    }
    init( data: [Float]) {
        input = data
        type = .discrete
        output = []
    }
    
    var copy: DataRender {
        return DataRender(data: data,
                          points: points,
                          type: type)
    }
    
    public var points: [CGPoint] { return output}
    public var data: [Float] { return input}
    public var dataType: RenderDataType { return type}
    public var minPoint: CGPoint? {
        return output.max(by: {$0.x > $1.x})
    }
    public var maxPoint: CGPoint? {
        return output.max(by: {$0.x <= $1.x})
    }
    /// Get  render point from index.
    /// - Parameters:
    ///   - renderIndex: Render index
    ///   - index: index point in render index ´renderIndex´
    /// - Returns: CGPoint or nil if point not found
    public func point(withIndex index: Int) -> CGPoint? {
        assert(index < points.count)
        return points[index]
    }
    /// indexForPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: Int
    /// - Returns: Int?
    public func index(withPoint point: CGPoint) -> Int? {
        switch type {
        case .discrete:
            return points.map { $0.distance(point) }.mini
        case .stadistics:
            return points.map { $0.distance(point) }.mini
        case .simplify:
            return points.map { $0.distance(point) }.mini
        case .regress:
            return points.map { $0.distance(point) }.mini
        }
    }
    /// data from point
    /// - Parameter point: point description
    /// - Returns: description
    public func data(withPoint point: CGPoint) -> Float? {
        switch dataType {
        case .discrete:
            if let firstIndex = points.firstIndex(of: point) {
                return data[firstIndex]
            }
        case .stadistics:
            if let firstIndex = points.map({ $0.distance(point) }).mini {
                return data[firstIndex]
            }
        case .simplify:
            if let firstIndex = points.firstIndex(of: point) {
                return data[firstIndex]
            }
        case .regress:
            if let firstIndex = points.firstIndex(of: point) {
                return data[firstIndex]
            }
        }
        return nil
        // return dataIndexFromLayers(point, renderIndex: renderIndex)
    }
    
    public func dataIndex(withPoint point: CGPoint) -> Int? {
        switch dataType {
        case .discrete:
            if let firstIndex = points.firstIndex(of: point) {
                return firstIndex
            } else {
                return points.map({ $0.distance(point) }).mini
            }

        case .stadistics:
            if let firstIndex = index(withPoint: point) {
                return firstIndex
            } else {
                return points.map({ $0.distance(point) }).mini
            }
        case .simplify:

            if let firstIndex = points.firstIndex(of: point) {
                return firstIndex
            } else {
                return points.map({ $0.distance(point) }).mini
            }

        case .regress:

            if let firstIndex = points.firstIndex(of: point) {
                return firstIndex
            } else {
                return points.map({ $0.distance(point) }).mini
            }

        }
        return nil // dataIndexFromLayers(point, renderIndex: renderIndex)
    }
}

// MARK: RenderProtocol
public protocol RenderProtocol {
    associatedtype DataRender
    var data: DataRender {get set} // Points and data
    var layers: [GradientShapeLayer] {get set}
    var index: Int {get set}
    func locationToLayer(_ location: CGPoint, mostNearLayer: Bool ) -> GradientShapeLayer?
    func layerPointFromPoint(_ point: CGPoint ) -> CGPoint
    func layerFrameFromPoint(_ point: CGPoint ) -> CGRect
    func makePoints(_ size: CGSize) -> [CGPoint]
}

// MARK: BaseRender
public class BaseRender: RenderProtocol {
    public var index: Int = 0
    public var data: DataRender = .empty
    public var layers: [GradientShapeLayer] = []
    init(index: Int) {
        self.index = index
    }
    init() {
        
    }
    
    public func allOtherLayers(layer: GradientShapeLayer ) -> [GradientShapeLayer] {
        if !layers.contains(layer) { return [] }
        return layers.filter { $0 != layer }
    }
    
    /// locationToLayer
    /// - Parameters:
    ///   - location: CGPoint
    ///   - mostNearLayer: Bool
    /// - Returns: GradientShapeLayer
    public func locationToLayer(_ location: CGPoint, mostNearLayer: Bool = true) -> GradientShapeLayer? {
        let mapped = layers.map {  (layer: CALayer) in
            layer.frame.origin.distance(location)
        }
        if mostNearLayer {
            guard let index = mapped.mini else {
                return nil
            }
            return layers[index]
        } else {
            guard let index = mapped.maxi else {
                return nil
            }
            return layers[index]
        }
    }
    /// layerPointFromPoint
    /// - Parameter point: CGPoint
    /// - Returns: CGPoint
    public func layerPointFromPoint(_ point: CGPoint ) -> CGPoint{
        /// Select the last point if the render is not hidden.
        guard let layer = locationToLayer(point, mostNearLayer: true) else {
            return .zero
        }
        return layer.position
    }
    
    /// layerFrameFromPoint
    /// - Parameter point: point description
    /// - Returns: CGRect
    public func layerFrameFromPoint(_ point: CGPoint ) -> CGRect{
        /// Select the last point if the render is not hidden.
        guard let layer = locationToLayer(point, mostNearLayer: true) else {
            return .zero
        }
        return layer.frame
    }
    
    /// makePoints
    /// - Parameter size: CGSize
    /// - Returns: [CGPoint]
    public func makePoints(_ size: CGSize) -> [CGPoint] {
        assert(size != .zero)
        return DiscreteScaledPointsGenerator().makePoints(data: self.data.data, size: size)
    }
    
   
    
}

public class PolylineRender: BaseRender {
    override init() {
        super.init(index: RenderIdentify.polyline.rawValue)
    }
}

public class PointsRender: BaseRender {
    override init() {
        super.init(index: RenderIdentify.points.rawValue)
    }
}

public class SelectedPointRender: BaseRender {
    override init() {
        super.init(index: RenderIdentify.selectedPoint.rawValue)
    }
}


public class RenderManager {
    static public var shared: RenderManager = RenderManager()
    lazy public var renders: [BaseRender] = {
        return [polyline,
                points,
                selectedPoint]
    }()
    init() {
    }
    public lazy var polyline: PolylineRender = {
        let poly = PolylineRender()
        return poly
    }()
    public lazy var  points: PointsRender = {
        let points = PointsRender()
        return points
        
    }()
    public lazy var selectedPoint: SelectedPointRender = {
        let selectedPoints = SelectedPointRender()
        return selectedPoints
    }()
    
    func removeAllLayers() {
        self.renders.forEach{
            $0.layers.forEach{$0.removeFromSuperlayer()}
            $0.layers.removeAll()
        }
    }
    
    public var layers: [[GradientShapeLayer]] {
        get {
            return RenderManager.shared.renders.reduce([[]]) { $0 + [$1.layers] }
        }
        set(newValue) {
            return RenderManager.shared.renders.enumerated().forEach{
                $1.layers = newValue[$0]
                
            }
        }
    }
    // points
    public var dataPoints: [[CGPoint]] {
        get {
            return RenderManager.shared.renders.map{$0.data.points}
        }
        set(newValue) {
            return RenderManager.shared.renders.enumerated().forEach {
                $1.data = DataRender(data: $1.data.data , points: newValue[$0], type: $1.data.dataType )
            }
        }
    }
    // data
    public var data: [[Float]]  {
        get {
            return RenderManager.shared.renders.map{$0.data.data}
        }
        set(newValue) {
            return RenderManager.shared.renders.enumerated().forEach{
                $1.data = DataRender(data: newValue[$0], points: $1.data.points, type: $1.data.dataType )
            }
        }
    }
    
    var visibleLayers: [CAShapeLayer] { allRendersLayers.filter { $0.opacity == 1.0 } }
    var invisibleLayers: [CAShapeLayer] { allRendersLayers.filter { $0.opacity == 0 }}
    var allPointsRender: [CGPoint] {    RenderManager.shared.dataPoints.flatMap{$0}}
    var allDataPointsRender: [Float]  {   RenderManager.shared.data.flatMap{$0}}
    var allRendersLayers: [CAShapeLayer]  {   RenderManager.shared.layers.flatMap{$0} }
    
    
}

