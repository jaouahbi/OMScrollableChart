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

/*
 
    Host           Renders                          version: 1
        q[SC]  --->   |  ---- Polyline
              (Data)  |  ---- Points
                      |  ---- Selected point
 
                      | ---- Base custom render
                                                    version: 2
        q[SC]  --->   |  ---- Bar1
              (Data)  |  ---- Bar2
                      |  ---- Segments

 */


// MARK: Library renders
public enum RenderIdent: Int {
    case polyline       = 0
    case points         = 1
    case selectedPoint  = 2
    case bar1           = 3
    case bar2           = 4
    case segments       = 5
    case base           = 6  //  public renders base index
}

public enum SimplifyType {
    case none
    case douglasPeuckerRadial
    case douglasPeuckerDecimate
    case visvalingam
    case ramerDouglasPeuckerPerp
}

public enum RenderType: Equatable {
    case discrete
    case stadistics(CGFloat)
    case simplify(SimplifyType, CGFloat)
    case regress(Int)
}


public struct RenderData  {
    static var empty: RenderData = RenderData(data: [], points: [])
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
    
    var copy: RenderData {
        return RenderData(data: data,
                          points: points,
                          type: type)
    }
    
    public var points: [CGPoint] { return output}
    public var data: [Float] { return input}
    public var dataType: RenderType { return type}
    public var minPoint: CGPoint? { output.max(by: {$0.x > $1.x}) }
    public var maxPoint: CGPoint? { output.max(by: {$0.x <= $1.x}) }
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
    associatedtype RenderData
    var chars: RenderProperties {get}
    var data: RenderData {get set} // Points and data
    var layers: [GradientShapeLayer] {get set}
    var index: Int {get set}
    func locationToLayer(_ location: CGPoint, mostNearLayer: Bool ) -> GradientShapeLayer?
    func layerPointFromPoint(_ point: CGPoint ) -> CGPoint
    func layerFrameFromPoint(_ point: CGPoint ) -> CGRect
    func makePoints(_ size: CGSize) -> [CGPoint]
    var isEmpty: Bool { get}
    
    var selectedColor: UIColor {get}
    var selectedOpacy: Float {get}
    var unselectedOpacy: Float {get}
    var unselectedColor: UIColor {get}
}


public struct LayerProperties {
    var color: UIColor = UIColor.clear
    var opacity: Float = 1.0
}

extension RenderProtocol {
    public var selectedColor: UIColor {return .red}
    public var selectedOpacy: Float {return 1.0}
    public var unselectedOpacy: Float {return 0.1}
    public var unselectedColor: UIColor  {return .clear}
}


// like the polyline render, selectable but useless
// generate layers from data.

// indicate



public struct RenderProperties: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    static let touchable = RenderProperties(rawValue: 1 << 0)   // can be touched
    static let renderable = RenderProperties(rawValue: 1 << 1)  // can generate layers
    static let indication = RenderProperties(rawValue: 1 << 2)
    static let event_notifier = RenderProperties(rawValue: 1 << 3) // wants chart events
    static let always_visible = RenderProperties(rawValue: 1 << 4) // ignore opacy changes
    static let tooltip = RenderProperties(rawValue: 1 << 5) // can generate tooltips
    static let rule_events = RenderProperties(rawValue: 1 << 6) // wants rule events
    static let foundation  = RenderProperties(rawValue: 1 << 7) // core render
    static let render: RenderProperties = [touchable, renderable]
    static let root: RenderProperties   = [touchable, renderable, indication, foundation, event_notifier, rule_events, tooltip]
}


extension CGRect {
    init(pointsArray: [CGPoint]) {

        var greatestXValue = pointsArray[0].x;
        var greatestYValue = pointsArray[0].y;
        var smallestXValue = pointsArray[0].x;
        var smallestYValue = pointsArray[0].y;

        for i  in 1..<pointsArray.count {
                let point = pointsArray[i];
                greatestXValue = max(greatestXValue, point.x);
                greatestYValue = max(greatestYValue, point.y);
                smallestXValue = min(smallestXValue, point.x);
                smallestYValue = min(smallestYValue, point.y);
            }

        var rect: CGRect = .zero
        rect.origin = CGPoint(x: smallestXValue, y: smallestYValue);
            rect.size.width = greatestXValue - smallestXValue;
            rect.size.height = greatestYValue - smallestYValue;

        self = rect
        }
    }

// MARK: BaseRender
open class BaseRender: RenderProtocol, CustomDebugStringConvertible, CustomStringConvertible {
    public var description: String { debugDescription }
    public var debugDescription: String {
        return "\(index) bounds: \(CGRect(pointsArray: data.points).integral) layers: \(layers.count)"
    }
    
    public var index: Int = 0
    public var chars: RenderProperties { [.renderable ]}
    public var data: RenderData = .empty
    public var layers: [GradientShapeLayer] = []
    public init(index: Int) {
        self.index = index
    }
    public init() { }
    public var isEmpty: Bool { data.data.isEmpty && data.points.isEmpty}
    /// allOtherLayers
    /// - Parameter layer: GradientShapeLayer
    /// - Returns: [GradientShapeLayer]
    private func allOtherLayers(layer: GradientShapeLayer ) -> [GradientShapeLayer] {
        if !layers.contains(layer) {
            return []
        }
        return layers.filter { $0 != layer }
    }
    public func selectLayer(layer: GradientShapeLayer,
                            selected: LayerProperties,
                            unselected: LayerProperties) -> GradientShapeLayer {
        
        let unselectedLayers = allOtherLayers(layer: layer)
//        print("all unselected render layers = \(unselected.count)")
        unselectedLayers.forEach { (layer: GradientShapeLayer) in
            layer.gardientColor = unselected.color
            layer.opacity = unselected.opacity
        }
        layer.gardientColor = selected.color
        layer.opacity = selected.opacity
//        print("Selected Render Layer = \(layer.name)")
        return layer
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
    
    public func sectionIndex( withPoint point: CGPoint, numberOfSections: Int) -> Int {
        let dataIndexLayer = data.dataIndex( withPoint: point )
        // Get the selection data index
        if let dataIndex = dataIndexLayer {
            let pointPerSectionRelation = Double(data.data.count) / Double(numberOfSections)
            let sectionIndex = Int(floor(Double(dataIndex) / Double(pointPerSectionRelation) ) ) % numberOfSections
            //            print(
            //                """
            //                        Render index: \(Int(render.index))
            //                        Data index: \(Int(dataIndex))
            //
            //                        \((ruleManager.footerRule?.views?[Int(sectionIndex)] as? UILabel)?.text ?? "")
            //
            //                        Point to section relation \(pointPerSectionRelation)
            //                        Section index: \(Int(sectionIndex))
            //                """)
            
            return Int(sectionIndex)
        }
        return Index.bad.rawValue
    }
}

public class PolylineRender: BaseRender {
    public override var chars: RenderProperties { [.touchable, .renderable, .foundation] }
    override init() {
        super.init(index: RenderIdent.polyline.rawValue)
    }
}

public class PointsRender: BaseRender {
    public override var chars: RenderProperties { return RenderProperties.root }
    override init() {
        super.init(index: RenderIdent.points.rawValue)
    }
}

public class SelectedPointRender: BaseRender {
    public override var chars: RenderProperties { return [.indication, .touchable, .event_notifier, .foundation]}
    override init() {
        super.init(index: RenderIdent.selectedPoint.rawValue)
    }
}

public class SegmentsRender: BaseRender {
    public override var chars: RenderProperties { return [.indication, .touchable, .event_notifier, .renderable]}
    override init() {
        super.init(index: RenderIdent.segments.rawValue)
    }
}

public class Bar1Render: BaseRender {
    public override var chars: RenderProperties  { return [.indication, .touchable, .renderable]}
    override init() {
        super.init(index: RenderIdent.bar1.rawValue)
    }
}

public class Bar2Render: BaseRender {
    public override var chars: RenderProperties  { return [.indication, .touchable, .renderable]}
    override init() {
        super.init(index: RenderIdent.bar2.rawValue)
    }
}

public protocol RenderEngineClientProtocol: class {
    var engine: RenderManagerProtocol {get}
}

// MARK: - RenderManagerProtocol -
public protocol RenderManagerProtocol {
    init()
    var version: Int {get}
    func configureRenders() -> [BaseRender]
    func update(_ numberOfdRenders: Int)
    func removeAllLayers()
    var visibleLayers: [CAShapeLayer] { get }
    var invisibleLayers: [CAShapeLayer] { get }
    var allPointsRender: [CGPoint] { get }
    var allDataPointsRender: [Float] { get }
    var allRendersLayers: [CAShapeLayer] { get }
    
    var points: [[CGPoint]] { get set }
    var layers: [[GradientShapeLayer]]  { get set }
    var data: [[Float]]   { get set }
    
    static var shared: RenderManager {get}
    var renders: [BaseRender] {get set}
}

extension RenderManagerProtocol {
    public var version: Int { 1 }
}

// MARK: - RenderManager -
open class RenderManager: RenderManagerProtocol {
    static public var shared: RenderManager = RenderManager()
    open var renders: [BaseRender] = []
    required public init() {
        self.renders = configureRenders()
    }
    open func update(_ numberOfdRenders: Int) {
        for idx in renders.count..<numberOfdRenders {
            renders.insert(BaseRender(index: idx), at: idx)
        }
    }
    open func render(from layer: GradientShapeLayer) -> BaseRender? {
        for render in renders {
            if render.layers.contains(layer) {
                return render
            }
        }
        return nil
    }
    
    /// configureRenders
    /// - Returns:  [BaseRender]
    open func configureRenders() -> [BaseRender] { [RenderManager.polyline,
                                                    RenderManager.points,
                                                    RenderManager.selectedPoint,
                                                    RenderManager.bar1,
                                                    RenderManager.bar2,
                                                    RenderManager.segments] }
    open func removeAllLayers() {
        self.renders.forEach{
            $0.layers.forEach{$0.removeFromSuperlayer()}
            $0.layers.removeAll()
        }
    }
    open var layers: [[GradientShapeLayer]] {
        get { RenderManager.shared.renders.reduce([[]]) { $0 + [$1.layers] } }
        set(newValue) {
            return RenderManager.shared.renders.enumerated().forEach{
                $1.layers = newValue[$0]
            }
        }
    }
    // points
    open var points: [[CGPoint]] {
        get { RenderManager.shared.renders.map{$0.data.points} }
        set(newValue) {
            return RenderManager.shared.renders.enumerated().forEach {
                $1.data = RenderData(data: $1.data.data , points: newValue[$0], type: $1.data.dataType )
            }
        }
    }
    // data
    open var data: [[Float]]  {
        get { RenderManager.shared.renders.map{$0.data.data} }
        set(newValue) {
            return RenderManager.shared.renders.enumerated().forEach{
                $1.data = RenderData(data: newValue[$0], points: $1.data.points, type: $1.data.dataType )
            }
        }
    }
    
    //
    // Getters helpers
    //
    
    
    public var visibleLayers: [CAShapeLayer] { allRendersLayers.filter { $0.opacity == 1.0 } }
    public var invisibleLayers: [CAShapeLayer] { allRendersLayers.filter { $0.opacity == 0 }}
    public var allPointsRender: [CGPoint] {    RenderManager.shared.points.flatMap{$0}}
    public var allDataPointsRender: [Float]  {   RenderManager.shared.data.flatMap{$0}}
    public var allRendersLayers: [CAShapeLayer]  {   RenderManager.shared.layers.flatMap{$0} }
}



extension RenderManager {
    
    //
    // Renders
    //
    
    public static var polyline: PolylineRender  = PolylineRender()
    public static var points: PointsRender = PointsRender()
    public static var selectedPoint: SelectedPointRender = SelectedPointRender()
    public static var bar1: Bar1Render = Bar1Render()
    public static var bar2: Bar2Render = Bar2Render()
    public static var segments: SegmentsRender = SegmentsRender()
}
