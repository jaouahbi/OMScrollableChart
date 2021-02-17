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

// https://stackoverflow.com/questions/35915853/how-to-show-tooltip-on-a-point-click-in-swift
// https://itnext.io/swift-uiview-lovely-animation-and-transition-d34bd623391f
// https://stackoverflow.com/questions/29674959/linear-regression-accelerate-framework-in-swift
// https://gist.github.com/marmelroy/ed4bd675bd75c757ab7447d1b3488886

import Accelerate
import LibControl
import OMBubbleTextView
import UIKit
// swiftlint:disable file_length
// swiftlint:disable type_body_length


struct AnimationKeyPaths {
    static var rideProgresAnimationsKey: String = "rideProgress"
    static var opacityAnimationsKey: String = "opacity"
    static var positionAnimationKey: String = "position"
    static var pathAnimationKey: String = "path"
    static var aroundAnimationKey: String = "around"
}

public enum Opacity: CGFloat {
    case show = 1.0
    case hide = 0.0
}



// public typealias ChartData = (points: [CGPoint], data: [Float])

// public enum RenderData {
//    case discrete
//    case averaged(Int)
//    case approximation(CGFloat)
//    case linregress(Int)
//    func makePoints( data: [Float], for size: CGSize, generator: ScaledPointsGenerator) -> [CGPoint] {
//        switch self {
//        case .discrete:
//            return generator.makePoints(data: data, size: size)
//        case .averaged(let elementsToAverage):
//            if elementsToAverage != 0 {
//                var result: Float = 0
//                let positives = data.map{$0>0 ? $0: abs($0)}
//                //            let negatives = data.filter{$0<0}
//                //
//                //            for negative in negatives {
//                //               let i = data.indexes(of: negatives)
//                //            }
//
//                let chunked = positives.chunked(into: elementsToAverage)
//                let averagedData: [Float] = chunked.map {
//                    vDSP_meanv($0, 1, &result, vDSP_Length($0.count));
//                    return result
//                }
//                //let averagedData = groupAverage(positives, numberOfElements: positives.count)
//                return generator.makePoints(data: averagedData, size: size)
//            }
//        case .approximation(let tolerance):
//            let points = generator.makePoints(data: data, size: size)
//            guard tolerance != 0, points.isEmpty == false else {
//                return []
//            }
//            return  OMSimplify.decimate(points, tolerance: CGFloat(tolerance))
//        case .linregress(let elements):
//            let points = generator.makePoints(data: data, size: size)
//            let originalDataIndex: [Float] = points.enumerated().map { Float($0.offset) }
//            //        let max = originalData.points.max(by: { $0.x < $1.x})!
//            //        let distance = mean(originalDataX.enumerated().compactMap{
//            //            if $0.offset > 0 {
//            //                return originalDataX[$0.offset-1].distance(to: $0.element)
//            //            }
//            //            return nil
//            //        })
//
//
//            // let results = originalDataX//.enumerated().map{ return originalDataX.prefix($0.offset+1).reduce(.zero, +)}
//
//            let linFunction: (slope: Float, intercept: Float) = Stadistics.linregress(originalDataIndex, data)
//
//            // var index = 0
//            let result: [Float] = [Float].init(repeating: 0, count: elements)
//
//            let resulLinregress = result.enumerated().map{
//                linFunction.slope * Float($0.offset) + linFunction.intercept }
//            //        for item in result  {
//            //            result[index] = dataForIndex(index:  Float(index))
//            //            index += 1
//            //        }
//            //
//            // add the new points
//            let newData = data + resulLinregress
//            return generator.makePoints(data: newData, size: size)
//        }
//
//        return []
//    }
//
//    var isAveraged: Bool {
//        switch self {
//        case .averaged(_):
//           return true
//        default:
//            return false
//        }
//    }

// }

public protocol ChartProtocol {
    func updateDataSourceData() -> Bool
}

public enum AnimationTiming: Hashable {
    case none
    case repe
    case infinite
    case oneShot
}

public protocol OMScrollableChartDataSource: class {
    func dataPoints(chart: OMScrollableChart, renderIndex: Int, section: Int) -> [Float]
    func numberOfPages(chart: OMScrollableChart) -> Int
    func dataLayers(chart: OMScrollableChart, renderIndex: Int, section: Int, data: DataRender) -> [GradientShapeLayer]
    func footerSectionsText(chart: OMScrollableChart) -> [String]?
    func dataPointTootipText(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, section: Int) -> String?
    func dataOfRender(chart: OMScrollableChart, renderIndex: Int) -> RenderDataType
    func dataSectionForIndex(chart: OMScrollableChart, dataIndex: Int, section: Int) -> String?
    func numberOfSectionsPerPage(chart: OMScrollableChart) -> Int
    func renderOpacity(chart: OMScrollableChart, renderIndex: Int) -> CGFloat
    func renderLayerOpacity(chart: OMScrollableChart, renderIndex: Int, layer: GradientShapeLayer) -> CGFloat?
    func zPositionForLayer(chart: OMScrollableChart, renderIndex: Int, layer: GradientShapeLayer) -> CGFloat?
    func queryAnimation(chart: OMScrollableChart, renderIndex: Int) -> AnimationTiming
    func animateLayers(chart: OMScrollableChart, renderIndex: Int, layerIndex: Int, layer: GradientShapeLayer) -> CAAnimation?
}

public protocol OMScrollableChartRenderableDelegateProtocol: class {
    func animationDidEnded(chart: OMScrollableChart, renderIndex: Int, animation: CAAnimation)
    func didSelectDataIndex(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, layer: CALayer)
    func didSelectSection(chart: OMScrollableChart, renderIndex: Int, sectionIndex: Int, layer: CALayer)
}

public protocol OMScrollableChartRenderableProtocol: class {
    var numberOfRenders: Int { get }
}

extension OMScrollableChartRenderableProtocol {
    // Default renders, polyline and points
    var numberOfRenders: Int {
        return 2
    }
}

public struct LayerStroker {
    public var layer: GradientShapeLayer
    public var points: [CGPoint]
    public init( layer: GradientShapeLayer, points: [CGPoint]) {
        self.layer = layer
        self.points = points
    }
}

@objcMembers
public final class OMScrollableChart: UIScrollView, UIScrollViewDelegate, ChartProtocol, CAAnimationDelegate, UIGestureRecognizerDelegate {
    private var pointsLayer = GradientShapeLayer()
    var dashLineLayers = [GradientShapeLayer]()
    
    var isAnimatePointsClearOpacity: Bool = true
    var isAnimatePointsClearOpacityDone: Bool = false
    
    var cacheTrackingLayout: Int = 0
    var isCacheStable: Bool {
        return cacheTrackingLayout > 1
    }
    
    var isScrollAnimation: Bool = false
    var isScrollAnimnationDone: Bool = false
    let scrollingProgressDuration: TimeInterval = 1.2
    
    public var dotPathLayers = [ShapeRadialGradientLayer]()
    
    
    public var layersToStroke: [LayerStroker] = []
    
    var animatePointLayers: Bool = false
    var animateLineSelection: Bool = false
    
    public var ruleManager: RuleManager = .init()
    public weak var dataSource: OMScrollableChartDataSource?
    public weak var renderSource: OMScrollableChartRenderableProtocol?
    public weak var renderDelegate: OMScrollableChartRenderableDelegateProtocol?
    var polylineGradientFadePercentage: CGFloat = 0.4
    var drawPolylineGradient: Bool = true
    var drawPolylineSegmentFill: Bool = false
    public var isFooterRuleAnimated: Bool = false
    public var lineColor = UIColor.greyishBlue
    public var selectedPointColor: UIColor = .darkGreyBlueTwo
    public var lineWidth: CGFloat = 6
    public var strokeLineColor: UIColor?
    var footerViewHeight: CGFloat = 60
    var topViewHeight: CGFloat = 20
    var ruleLeadingAnchor: NSLayoutConstraint?
    var ruletopAnchor: NSLayoutConstraint?
    var rulebottomAnchor: NSLayoutConstraint?
    var rulewidthAnchor: NSLayoutConstraint?
    var ruleHeightAnchor: NSLayoutConstraint?
    var ruleFont = UIFont.systemFont(ofSize: 10, weight: .medium)
    var rulesPoints = [CGPoint]()
    var animatePolyLine = false
    var animateDashLines: Bool = false
    var animatePointsOnSelectionLayers: Bool = false
    var isAnimateLineSelection: Bool = false
    var pointsLayersShadowOffset = CGSize(width: 0, height: 0.5)
    var selectedColor = UIColor.red
    var selectedOpacy: Float = 1.0
    var unselectedOpacy: Float = 0.1
    var unselectedColor = UIColor.clear
    /// Animate show unselected points
    var showPointsOnSelection: Bool = true
    var animateOnRenderLayerSelection: Bool = true
    var showTooltip: Bool = true
    var rideAnim: CAAnimation?
    var layerToRide: CALayer?
    var ridePath: Path?
    var bezier: OMBezierPath?
    var showPolylineNearPoints: Bool = true
    
    // MARK: - Layout Cache -
    
    // cache hashed frame + points
    var layoutCache = [String: Any]()
    var isLayoutCacheActive: Bool = false
    
    var zoomIsActive: Bool = false
    
    //    var shouldBeginGestureRecognizer: Bool = true
    
    // Content view
    lazy var contentView: UIView = {
        let lazyContentView = UIView(frame: self.bounds)
        lazyContentView.layer.name = "contentViewLayer"
        self.addSubview(lazyContentView)
        return lazyContentView
    }()
    
    // Debug polyline path
    var lineShapeLayerLineWidth: CGFloat = 2.0
    public lazy var lineShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = lineShapeLayerLineWidth
        layer.strokeColor = UIColor.black.cgColor
        layer.fillColor = UIColor.clear.cgColor
        self.contentView.layer.addSublayer(layer)
        return layer
    }()
    
    var startPointShapeLayerineWidth: CGFloat = 4.0
    // Debug polyline path
    public lazy var startPointShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = startPointShapeLayerineWidth
        layer.strokeColor = UIColor.black.cgColor
        layer.fillColor = UIColor.clear.cgColor
        self.contentView.layer.addSublayer(layer)
        return layer
    }()
    
    // MARK: - Tooltip -
    
    var tooltip = OMBubbleTextView()
    // Scaled generator
    var tooltipBorderColor = UIColor.black.cgColor {
        didSet {
            tooltip.layer.borderColor = tooltipBorderColor
        }
    }
    
    var tooltipBorderWidth: CGFloat = 0.0 {
        didSet {
            tooltip.layer.borderWidth = tooltipBorderWidth
        }
    }
    
    var toolTipBackgroundColor = UIColor.clear {
        didSet {
            tooltip.backgroundColor = toolTipBackgroundColor
        }
    }
    
    var tooltipFont = UIFont.systemFont(ofSize: 12, weight: .light) {
        didSet {
            tooltip.font = tooltipFont
        }
    }
    
    var tooltipAlpha: CGFloat = 0 {
        didSet {
            tooltip.alpha = tooltipAlpha
        }
    }
    
    //    var scaledPointsGenerator =
    //        [ScaledPointsGeneratorProtocol](repeating: DiscreteScaledPointsGenerator(), count: 10)
    
    // MARK: - Data Bounds -
    
    // For example: mouths : 6
    public var numberOfSectionsPerPage: Int {
        return dataSource?.numberOfSectionsPerPage(chart: self) ?? 1
    }
    
    public var numberOfSections: Int { // Total
        return numberOfSectionsPerPage * numberOfPages
    }
    
    public var sectionWidth: CGFloat {
        return contentSize.width / CGFloat(numberOfSections)
    }
    
    public var numberOfPages: Int = 1 {
        didSet {
            updateContentSize()
        }
    }
    
    // MARK: - Polyline -
    
    /// Polyline Interpolation
    public var polylineInterpolation: PolyLineInterpolation = .catmullRom(0.5) {
        didSet {
            forceLayoutReload() // force layout
        }
    }
    
    var startColor = UIColor.greyishBlue { didSet { setNeedsDisplay(bounds) } }
    var endColor = UIColor.clear   { didSet { setNeedsDisplay(bounds) } }
    var startAngle: CGFloat = 0    { didSet { setNeedsDisplay(bounds) } }
    var endAngle: CGFloat = 360   { didSet { setNeedsDisplay(bounds) } }
    
    
    lazy var numberFormatter: NumberFormatter = {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .decimal
        currencyFormatter.maximumFractionDigits = 0
        // localize to your grouping and decimal separator
        currencyFormatter.locale = Locale(identifier: "es_ES")
        return currencyFormatter
    }()
    
    override public func draw(_ layer: CALayer, in ctx: CGContext) {
        super.draw(layer, in: ctx)
        updateRendersOpacity()
    }
    
    lazy var currencyFormatter: NumberFormatter = {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.maximumFractionDigits = 0
        // localize to your grouping and decimal separator
        currencyFormatter.locale = Locale(identifier: "es_ES")
        return currencyFormatter
    }()
    
    public var numberOfElementsToMean: CGFloat = 3 {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    // 1.0 -> 20.0
    public var approximationTolerance: CGFloat = 1.0 {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    // MARK: - Rules -
    
    var numberOfRuleMarks: CGFloat = 1 {
        didSet {
            setNeedsLayout()
        }
    }
    
    internal var internalRulesMarks = [Float]()
    var rulesMarks: [Float] {
        return internalRulesMarks.sorted(by: { !($0 > $1) })
    }
    
    var dashPattern: [CGFloat] = [1, 2] {
        didSet {
            dashLineLayers.forEach { ($0).lineDashPattern = dashPattern.map { NSNumber(value: Float($0)) }}
        }
    }
    
    var dashLineWidth: CGFloat = 0.5 {
        didSet {
            dashLineLayers.forEach { $0.lineWidth = dashLineWidth }
        }
    }
    
    var dashLineColor = UIColor.lightGray.withAlphaComponent(0.8).cgColor {
        didSet {
            dashLineLayers.forEach { $0.strokeColor = dashLineColor }
        }
    }
    
    // MARK: - Footer -
    
    var decorationFooterRuleColor = UIColor.black {
        didSet {
            ruleManager.footerRule?.decorationColor = decorationFooterRuleColor
        }
    }
    
    // MARK: - Font color -
    
    var fontFooterRuleColor = UIColor.darkGreyBlueTwo {
        didSet {
            ruleManager.footerRule?.fontColor = fontFooterRuleColor
        }
    }
    
    var fontRootRuleColor = UIColor.black {
        didSet {
            ruleManager.rootRule?.fontColor = fontRootRuleColor
        }
    }
    
    var fontTopRuleColor = UIColor.black {
        didSet {
            ruleManager.topRule?.fontColor = fontTopRuleColor
        }
    }
    
    var footerRuleBackgroundColor = UIColor.black {
        didSet {
            ruleManager.footerRule?.backgroundColor = footerRuleBackgroundColor
        }
    }
    
    public func forceLayoutReload() { updateLayout(ignoreLayoutCache: true) }
    
    //    lazy var recognizer: UIPanGestureRecognizer = {
    //        let rev = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    ////        rev.cancelsTouchesInView = true
    //        rev.delegate = self
    ////       rev.shouldRequireFailure(of: self.panGestureRecognizer)
    //        return rev
    //    }()
    
    var linFunction: (slope: Float, intercept: Float)?
    
    // Polyline render index 0
    public var polylinePoints: [CGPoint]? {
        return RenderManager.shared.polyline.data.points
    }
    
    public var polylineDataPoints: [Float]? {
        return RenderManager.shared.polyline.data.data
    }
    
    // Polyline render index 1
    public var pointsPoints: [CGPoint]? {
        return RenderManager.shared.points.data.points
    }
    
    public var pointsDataPoints: [Float]? {
        return RenderManager.shared.polyline.data.data
    }
    
    // Selected Layers
    public var renderSelectedPointsLayer: CAShapeLayer? {
        return RenderManager.shared.selectedPoint.layers.first
    }
    
    private var contentSizeKOToken: NSKeyValueObservation?
    private var contentOffsetKOToken: NSKeyValueObservation?
    
    // MARK: -  register/unregister notifications and KO
    
    private func registerNotifications() {
        #if swift(>=4.2)
        let notificationName = UIDevice.orientationDidChangeNotification
        #else
        let notificationName = NSNotification.Name.UIDeviceOrientationDidChange
        #endif
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRotation),
                                               name: notificationName,
                                               object: nil)
        
        contentOffsetKOToken = observe(\.contentOffset) { [weak self] object, _ in
            // the `[weak self]` is to avoid strong reference cycle; obviously,
            // if you don't reference `self` in the closure, then `[weak self]` is not needed
            print("contentOffset is now \(object.contentOffset)")
            guard let selfWeak = self else {
                return
            }
            for layer in selfWeak.dashLineLayers {
                CATransaction.withDisabledActions {
                    var layerFrame = layer.frame
                    layerFrame.origin.y = object.contentOffset.y
                    layerFrame.origin.x = object.contentOffset.x
                    layer.frame = layerFrame
                }
            }
        }
        
        contentSizeKOToken = observe(\.contentSize) { [weak self] object, _ in
            // the `[weak self]` is to avoid strong reference cycle; obviously,
            // if you don't reference `self` in the closure, then `[weak self]` is not needed
            print("contentSize is now \(object.contentSize) \(object.bounds)")
            //            guard let selfWeak = self else {
            //                return
            //            }
            //            for layer in selfWeak.dashLineLayers {
            //                CATransaction.withDisabledActions {
            //                    var layerFrame = layer.frame
            //                    layerFrame.origin.y = object.contentOffset.y
            //                    layerFrame.origin.x = object.contentOffset.x
            //                    layer.frame = layerFrame
            //                }
            //            }
        }
    }
    
    // Unregister the ´orientationDidChangeNotification´ notification
    fileprivate func unregisterNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        unregisterNotifications()
        contentOffsetKOToken?.invalidate()
        contentOffsetKOToken = nil
        contentSizeKOToken?.invalidate()
        contentSizeKOToken = nil
    }
    
    // MARK: - handleRotation -
    
    func handleRotation() {
        updateContentSize()
    }
    
    lazy var bezierPathLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        contentView.layer.addSublayer(shape)
        return shape
    }()
    // Setup all the view/subviews
    func setupView() {
        registerNotifications()
        // Setup the UIScrollView
        delegate = self
        if #available(iOS 11, *) {
            self.contentInsetAdjustmentBehavior = .never
        }
        createSuplementaryRules()
        configureTooltip()
        
        addPanGestureRecognizer()
        
        //        if isScreenLine {
        //            self.setupTouchScreenLineLayer()
        //        }
    }
    
    //    //
    //    var isScreenLine: Bool = false
    //    var touchScreenLineLayerColor = UIColor.clear
    //    var touchScreenLineWidth: CGFloat = 0.5
    //    var touchScreenLineLayerPath: UIBezierPath?
    //    var showScreenLineLayer = false
    //    var touchScreenLineLayer: GradientShapeLayer = GradientShapeLayer()
    //
    //    func setupTouchScreenLineLayer() {
    //        touchScreenLineLayer.lineJoin      = CAShapeLayerLineJoin.round
    //        touchScreenLineLayer.shadowColor   = UIColor.gray.cgColor
    //        //lineLayer.shadowOffset  = circleShadowOffset
    //        touchScreenLineLayer.shadowOpacity = 0.7
    //        touchScreenLineLayer.shadowRadius  = 1.0
    //        self.contentView.layer.addSublayer(touchScreenLineLayer)
    //    }
    //
    //    fileprivate func updateLineSelectionLayer(_ location: CGPoint) {
    //        guard showScreenLineLayer else {
    //            return
    //        }
    //        let linePath = UIBezierPath()
    //        linePath.move(to: CGPoint( x: location.x, y: topViewHeight))
    //        linePath.addLine(to: CGPoint( x: location.x, y: self.footerRule!.frame.origin.y ))
    //        touchScreenLineLayer.strokeColor = touchScreenLineLayerColor.cgColor
    //        touchScreenLineLayer.lineWidth = touchScreenLineWidth
    //        touchScreenLineLayer.path = linePath.cgPath
    //    }
    
    // MARK: - Rotation support -
    
    private func updateContentSize() {
        layoutIfNeeded()
        let newValue = CGSize(width: bounds.width * CGFloat(numberOfPages), height: bounds.height)
        if contentSize != newValue {
            contentSize = newValue
            contentView.frame = CGRect(x: 0,
                                       y: 0,
                                       width: contentSize.width,
                                       height: contentSize.height - footerViewHeight)
        }
        updateLayout()
    }
    
    var drawableFrame: CGRect {
        return CGRect(origin: .zero, size: contentView.frame.size)
    }
    
    // MARK: - contentSize -
    
    func queryDataPointsRender(_ dataSource: OMScrollableChartDataSource) -> [[Float]] {
        var dataPointsRenderNewDataPoints = [[Float]]()
        if let render = renderSource, render.numberOfRenders > 0 {
            // get the layers.
            for index in 0..<render.numberOfRenders {
                let dataPoints = dataSource.dataPoints(chart: self,
                                                       renderIndex: index,
                                                       section: 0)
                dataPointsRenderNewDataPoints.insert(dataPoints, at: index)
            }
        } else {
            // Only exist one render.
            let dataPoints = dataSource.dataPoints(chart: self,
                                                   renderIndex: 0,
                                                   section: 0)
            dataPointsRenderNewDataPoints.insert(dataPoints, at: 0)
        }
        return dataPointsRenderNewDataPoints
    }
    
    func updateRenderEngine(_ dataPointsRender: [[Float]]) {
        // Create the renders if need
        for idx in RenderManager.shared.renders.count..<renderSourceNumberOfRenders {
            RenderManager.shared.renders.insert(BaseRender(index: idx), at: idx)
        }
        
        // Update the renders data
        zip(RenderManager.shared.renders, dataPointsRender).forEach {
            $0.data = DataRender(data: $1, points: [])
        }
    }
    
    public func updateDataSourceRuleNotification(_ dataSource: OMScrollableChartDataSource) {
        if let footerRule = ruleManager.footerRule as? OMScrollableChartRuleFooter {
            if let texts = dataSource.footerSectionsText(chart: self) {
                if texts != footerRule.footerSectionsText {
                    footerRule.footerSectionsText = texts
                    // _delegate.footerSectionsTextChanged()
                    print("footerSectionsTextChanged()")
                }
            }
        }
    }
    
    public func updateDataSourceData() -> Bool {
        if let dataSource = dataSource {
            print("get the data points and prepage the render engine")
            updateRenderEngine(queryDataPointsRender(dataSource))
            // notify to the rule
            updateDataSourceRuleNotification(dataSource)
            
            let oldNumberOfPages = numberOfPages
            let newNumberOfPages = dataSource.numberOfPages(chart: self)
            if oldNumberOfPages != newNumberOfPages {
                print("numberOfPagesChanged: \(oldNumberOfPages) -> \(newNumberOfPages)")
                //                _delegate.numberOfPagesChanged()
            }
            numberOfPages = newNumberOfPages
            return true
        }
        return false
    }
    
    /// addDashLineLayer
    /// - Parameters:
    ///   - point: CGPoint
    ///   - endPoint: CGPoint
    ///   - stroke: UIColor
    ///   - lineWidth: CGFloat
    ///   - pattern: [NSNumber]?
    func addDashLineLayerFromRuleMark(point: CGPoint,
                                      endPoint: CGPoint,
                                      stroke: UIColor? = nil,
                                      lineWidth: CGFloat? = nil,
                                      pattern: [NSNumber]? = nil)
    {
        let lineLayer = GradientShapeLayer()
        lineLayer.strokeColor = stroke?.cgColor ?? dashLineColor
        lineLayer.lineWidth = lineWidth ?? dashLineWidth
        lineLayer.lineDashPattern = pattern ?? dashPattern as [NSNumber]
        let path = CGMutablePath()
        path.addLines(between: [point, endPoint])
        lineLayer.path = path
        lineLayer.name = "Dash"
        dashLineLayers.append(lineLayer)
        contentView.layer.addSublayer(lineLayer)
    }
    
    /// projectLineStrokeGradient
    /// - Parameters:
    ///   - internalPoints: [CGPoints]]
    ///   - ctx: CGContext
    ///   - gradient: CGGradient
    private func projectLineStrokeGradient(_ ctx: CGContext,
                                           gradient: CGGradient,
                                           internalPoints: [CGPoint],
                                           lineWidth: CGFloat)
    {
        ctx.saveGState()
        for index in 0..<internalPoints.count - 1 {
            var start: CGPoint = internalPoints[index]
            // The ending point of the axis, in the shading's target coordinate space.
            var end: CGPoint = internalPoints[index + 1]
            // Draw the gradient in the clipped region
            let hw = lineWidth * 0.5
            start = end.projectLine(start, length: hw)
            end = start.projectLine(end, length: -hw)
            ctx.scaleBy(x: drawableFrame.size.width,
                        y: drawableFrame.size.height)
            ctx.drawLinearGradient(gradient,
                                   start: start,
                                   end: end,
                                   options: [])
        }
        ctx.restoreGState()
    }
    
    
    func stroke(in ctx: CGContext,
                path: CGPath?,
                lineWidth: CGFloat,
                startPoint: CGPoint,
                endPoint: CGPoint,
                startRadius: CGFloat,
                endRadius: CGFloat,
                strokeColor: UIColor,
                lowColor: UIColor,
                fadeFactor: CGFloat = 0.8,
                axial: Bool = true) {
        
        
        ctx.saveGState()
        
        
        let locations = [0, fadeFactor, 1 - fadeFactor, 1]
        let gradient = CGGradient(colorsSpace: nil,
                                  colors: [lowColor.withAlphaComponent(0.1).cgColor,
                                           strokeColor.cgColor,
                                           strokeColor.withAlphaComponent(fadeFactor).cgColor,
                                           lowColor.withAlphaComponent(0.8).cgColor] as CFArray,
                                  locations: locations)!
        
        var start = CGPoint(x: startPoint.x * self.bounds.size.width, y: startPoint.y * self.bounds.size.height)
        var end   =  CGPoint(x: endPoint.x * self.bounds.size.width, y: endPoint.y * self.bounds.size.height)
        // The context must be clipped before scale the matrix.
        if let path = path {
            ctx.addPath(path)
            ctx.setLineWidth(lineWidth)
            ctx.replacePathWithStrokedPath()
            ctx.clip()
        }
        
        // if we are using the stroke, we offset the from and to points
        // by half the stroke width away from the center of the stroke.
        // Otherwise we tend to end up with fills that only cover half of the
        // because users set the start and end points based on the center
        // of the stroke.
        let hw = lineWidth * 0.5;
        start  = end.projectLine(start,length: hw)
        
        
        ctx.scaleBy(x: self.bounds.size.width,
                    y: self.bounds.size.height );
        
        start = CGPoint(x: start.x / self.bounds.size.width, y: start.y / self.bounds.size.height)
        end   =  CGPoint(x: end.x / self.bounds.size.width, y: end.y / self.bounds.size.height)
        
        
        let minimumRadius = minRadius(self.bounds.size)
        
        
        if axial {
            ctx.drawLinearGradient(gradient,
                                   start: start ,
                                   end: end,
                                   options: [])
        } else {
            ctx.drawRadialGradient(gradient,
                                   startCenter: start ,
                                   startRadius: startRadius * minimumRadius,
                                   endCenter:end ,
                                   endRadius: endRadius * minimumRadius,
                                   options: [])
        }
        ctx.restoreGState();
        
    }
    
    /// strokeGradient
    /// - Parameters:
    ///   - ctx: ctx description
    ///   - layer: layer description
    ///   - points: points description
    ///   - color: color description
    ///   - lineWidth: lineWidth description
    ///   - fadeFactor: fadeFactor description
    private func strokeGradient(ctx: CGContext?,
                                layer: CAShapeLayer,
                                points: [CGPoint]?,
                                color: UIColor,
                                lowColor: UIColor = UIColor.white,
                                lineWidth: CGFloat = 1.0,
                                fadeFactor: CGFloat = 0.4)
    {
        if let ctx = ctx {
            let locations = [0, fadeFactor, 1 - fadeFactor, 1]
            let gradient = CGGradient(colorsSpace: nil,
                                      colors: [lowColor.withAlphaComponent(0.1).cgColor,
                                               color.cgColor,
                                               color.withAlphaComponent(fadeFactor).cgColor,
                                               lowColor.withAlphaComponent(0.8).cgColor] as CFArray,
                                      locations: locations)!
            // Clip to the path, stroke and enjoy.
            if let path = layer.path {
                color.setStroke()
                let curPath = UIBezierPath(cgPath: path)
                curPath.lineWidth = lineWidth
                //                curPath.stroke()
                ctx.replacePathWithStrokedPath()
                curPath.addClip()
                // if we are using the stroke, we offset the from and to points
                // by half the stroke width away from the center of the stroke.
                // Otherwise we tend to end up with fills that only cover half of the
                // because users set the start and end points based on the center
                // of the stroke.
                if let internalPoints = points {
                    projectLineStrokeGradient(ctx,
                                              gradient: gradient,
                                              internalPoints: internalPoints,
                                              lineWidth: lineWidth)
                }
            }
        }
    }
    
    func makeAveragedPoints(data: [Float], size: CGSize, elementsToAverage: Int) -> [CGPoint]? {
        if elementsToAverage != 0 {
            var result: Float = 0
            let positives = data.map { $0 > 0 ? $0 : abs($0) }
            //            let negatives = data.filter{$0<0}
            //
            //            for negative in negatives {
            //               let i = data.indexes(of: negatives)
            //            }
            
            let chunked = positives.chunked(into: elementsToAverage)
            let averagedData: [Float] = chunked.map {
                vDSP_meanv($0, 1, &result, vDSP_Length($0.count))
                return result
            }
            // let averagedData = groupAverage(positives, numberOfElements: positives.count)
            return DiscreteScaledPointsGenerator().makePoints(data: averagedData, size: size)
        }
        return nil
    }
    
    /// Make raw discrete points
    /// - Parameters:
    ///   - data: Data
    ///   - size: CGSize
    /// - Returns: Array of discrete CGPoint
    func makeRawPoints(_ data: [Float], size: CGSize) -> [CGPoint] {
        assert(size != .zero)
        assert(!data.isEmpty)
        return DiscreteScaledPointsGenerator().makePoints(data: data, size: size)
    }
    
    func makeApproximationPoints(points: [CGPoint], tolerance: CGFloat) -> [CGPoint]? {
        guard tolerance != 0, points.isEmpty == false else {
            return nil
        }
        return OMSimplify.douglasPeuckerDecimateSimplify(points, tolerance: CGFloat(tolerance))
    }
    
    private func removeAllLayers() {
        RenderManager.shared.removeAllLayers()
    }
    
    func performPathAnimation(_ layer: GradientShapeLayer,
                              _ animation: CAAnimation,
                              _ layerOpacity: CGFloat)
    {
        if layer.opacity == 0 {
            let anim = performAnimationWithFadeGroup(layer,
                                                     fromValue: CGFloat(layer.opacity),
                                                     toValue: layerOpacity,
                                                     animations: [animation])
            layer.add(anim, forKey: "renderPathAnimationGroup", withCompletion: nil)
        } else {
            layer.add(animation, forKey: "renderPathAnimation", withCompletion: nil)
        }
    }
    
    private func performPositionAnimation(_ layer: GradientShapeLayer,
                                          _ animation: CAAnimation,
                                          layerOpacity: CGFloat)
    {
        let anima = performAnimationWithFadeGroup(layer,
                                                  toValue: layerOpacity,
                                                  animations: [animation])
        if layer.opacity == 0 {
            layer.add(anima, forKey: "renderPositionAnimationGroup", withCompletion: nil)
        } else {
            layer.add(animation, forKey: "renderPositionAnimation", withCompletion: nil)
        }
    }
    
    private func performOpacityAnimation(_ layer: GradientShapeLayer,
                                         _ animation: CAAnimation)
    {
        layer.add(animation, forKey: "renderOpacityAnimation", withCompletion: nil)
    }
    
    //    var allPointsRender: [CGPoint] { return renderData.flatMap { $0?.points }}
    //    var allDataPointsRender: [Float] { return renderData.flatMap { $0?.data }}
    //       var allRendersLayers: [CAShapeLayer] { return RenderManager.shared.layers.flatMap { $0 } }
    //
    internal var renderSourceNumberOfRenders: Int {
        if let render = renderSource {
            return render.numberOfRenders
        }
        return 0
    }
    
    //    func performPathAnimation(_ layer: GradientShapeLayer,
    //                              _ animation: CAAnimation,
    //                              _ layerOpacity: CGFloat) {
    //        if layer.opacity == 0 {
    //            let anim = animationWithFadeGroup(layer,
    //                                              fromValue: CGFloat(layer.opacity),
    //                                              toValue: layerOpacity,
    //                                              animations: [animation])
    //            layer.add(anim, forKey: "renderPathAnimationGroup", withCompletion: nil)
    //        } else {
    //
    //            layer.add(animation, forKey: "renderPathAnimation", withCompletion: nil)
    //        }
    //    }
    //
    //    private func performPositionAnimation(_ layer: GradientShapeLayer,
    //                                              _ animation: CAAnimation,
    //                                              layerOpacity: CGFloat) {
    //        let anima = animationWithFadeGroup(layer,
    //                                           toValue: layerOpacity,
    //                                           animations: [animation])
    //        if layer.opacity == 0 {
    //            layer.add(anima, forKey: "renderPositionAnimationGroup", withCompletion: nil)
    //        } else {
    //            layer.add(animation, forKey: "renderPositionAnimation", withCompletion: nil)
    //        }
    //    }
    //
    //    private func performOpacityAnimation(_ layer: GradientShapeLayer,
    //                                             _ animation: CAAnimation) {
    //
    //        layer.add(animation, forKey: "renderOpacityAnimation", withCompletion: nil)
    //    }
    
    /// updateRenderLayersOpacity
    /// - Parameters:
    ///   - renderIndex: Index
    ///   - layerOpacity: CGFloat
    private func updateRenderLayersOpacity(for renderIndex: Int,
                                           layerOpacity: CGFloat,
                                           ignorePoints: Bool = true)
    {
        // Don't delay the opacity
        if ignorePoints,
           renderIndex == RenderIdentify.points.rawValue
        {
            print("Render ´points´ not suitable for task.")
            return
        }
        if renderIndex >= RenderManager.shared.renders.count {
            print("Render \(renderIndex) out of bounds.")
            return
        }
        let layers = RenderManager.shared.renders[renderIndex].layers
        guard layers.count > 0 else {
            print("Render \(renderIndex) out of layers.")
            return
        }
        
        guard let opacity = dataSource?.renderOpacity(chart: self, renderIndex: renderIndex) else {
            layers.forEach { $0.opacity = Float(0)}
            return
        }
        layers.forEach { $0.opacity = Float(opacity)}
        
        //        print("Render \(renderIndex) opacity \(layerOpacity)")
        //        layers.enumerated().forEach { _, layer in
        //            let opacity = dataSource?.renderLayerOpacity(chart: self,
        //                                                         renderIndex: renderIndex,
        //                                                         layer: layer)
        //            if let opacity = opacity {
        //                layer.opacity = Float(opacity)
        //            } else {
        //                layer.opacity = Float(layerOpacity)
        //            }
        //        }
    }
    
    private func resetRenderData() {
        // points and layers
        //        pointsRender.removeAll()
        //        RenderManager.shared.layers.removeAll()
        // data
        //        averagedData.removeAll()
        //        linregressData.removeAll()
        //        approximationData.removeAll()
    }
    
    /// queryDataAndRegenerateRendersLayers
    func queryDataAndRegenerateRendersLayers() -> Int {
        var numberOfLayerAdded: Int = 0
        if let render = renderSource, let dataSource = dataSource, render.numberOfRenders > 0 {
            // reset the internal data
            resetRenderData()
            // render layers
            assert(render.numberOfRenders ==  RenderManager.shared.renders.count)
            for render in RenderManager.shared.renders {
                guard render.data.data.isEmpty == false else {
                    print("render \(render.index) has data.")
                    continue
                }
                // Get the render data. ex: discrete / approx / averaged / regression ...
                let dataOfRender = dataSource.dataOfRender(chart: self,
                                                           renderIndex: render.index)
                print("dataOfRender \(dataOfRender) for render \(render.index)")
                
                render.data = DataRender(data: render.data.data,
                                         points: render.data.points,
                                         type: dataOfRender )
                
                renderLayers(with: render, size: drawableFrame.size)
            }
            
            print("adding \(RenderManager.shared.allRendersLayers.count) layers")
            // add layers
            for (renderIndex, render) in RenderManager.shared.renders.enumerated() {
                
                // Insert the render layers
                print("adding \(render.layers.count) layers for render \(renderIndex)")
                render.layers.forEach {
                    self.contentView.layer.insertSublayer($0, at: UInt32(renderIndex))
                    // Query and set the zPosition
                    $0.zPosition = dataSource.zPositionForLayer(chart: self, renderIndex: renderIndex, layer: $0) ?? CGFloat(renderIndex)
                    numberOfLayerAdded += 1
                }
            }
        }
        return numberOfLayerAdded
    }
    
    lazy var polylineLayer: ShapeLinearGradientLayer = {
        let polyline = ShapeLinearGradientLayer()
        return polyline
    }()
    
    func polylineLayerPathDidChange(layer: CAShapeLayer) {
        print("´\(String(describing: layer.name))´ path change in layer")
        polylineLayerBezierPathDidLoad(layer)
    }
    
    let minimunRenderOpacity: CGFloat = 0.5
    private func rendersIsVisible(renderIndex: Int) -> Bool {
        if let dataSource = dataSource {
            return dataSource.renderOpacity(chart: self, renderIndex: renderIndex) >= minimunRenderOpacity
        }
        return false
    }
    
    func rendersIsVisible(render: BaseRender) -> Bool { rendersIsVisible(renderIndex: render.index) }
    
    /// layoutRenders
    
    func layoutRenders() {
        if let render = renderSource,
           let dataSource = dataSource, render.numberOfRenders > 0
        {
            print("Regenerate and layout animation. renders: #\(render.numberOfRenders)")
            let numberOfLayers = queryDataAndRegenerateRendersLayers()
            print("Regenerated \(numberOfLayers) layers for \(render.numberOfRenders) renders.")
            // update with animation
            for render in RenderManager.shared.renders {
                // Get the opacity
                if rendersIsVisible(render: render) {
                    let CNT = render.layers.count
                    let timing = dataSource.queryAnimation(chart: self, renderIndex: render.index)
                    if timing == .repe {
                        print("Animating the render: \(render.index) layers: \(CNT).")
                        performAnimateRenderLayers(render.index,
                                                   layerOpacity: Opacity.show.rawValue)
                    } else {
                        print("The render \(render.index) dont want animate its \(CNT) layers.")
                    }
                }
            }
        }
    }
    
    /// scrollingProgressAnimatingToPage
    /// - Parameters:
    ///   - duration: TimeInterval
    ///   - page: Int
    private func scrollingProgressAnimatingToPage(_ duration: TimeInterval, page: Int, completion: (() -> Void)? = nil) {
        let delay: TimeInterval = 0.5
        let preTimeOffset: TimeInterval = 1.0
        let duration: TimeInterval = duration + delay - preTimeOffset
        layoutIfNeeded()
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: .curveEaseInOut,
                       animations: {
                        self.contentOffset.x = (self.bounds.size.width / CGFloat(self.numberOfPages)) * CGFloat(page)
                       }, completion: { completed in
                        if self.isAnimatePointsClearOpacity,
                           !self.isAnimatePointsClearOpacityDone
                        {
                            self.animatePointsClearOpacity()
                            self.isAnimatePointsClearOpacityDone = true
                        }
                        
                        if completed {
                            completion?()
                        }
                       })
    }
    
    private func performRunRideProgressAnimation(layerToRide: CALayer?,
                                                 renderIndex: Int,
                                                 scrollAnimation: Bool = false, page: Int = 1) {
        if let anim = rideAnim {
            if let layerRide = layerToRide {
                CATransaction.withDisabledActions {
                    layerRide.transform = CATransform3DIdentity
                }
                if scrollAnimation {
                    scrollingProgressAnimatingToPage(anim.duration, page: page) {
                        
                    }
                }
                
                layerRide.add(anim, forKey: AnimationKeyPaths.aroundAnimationKey, withCompletion: { _ in
                    if let presentationLayer = layerRide.presentation() {
                        CATransaction.withDisabledActions {
                            layerRide.position = presentationLayer.position
                            layerRide.transform = presentationLayer.transform
                        }
                    }
                    self.animationDidEnded(renderIndex: Int(renderIndex), animation: anim)
                    layerRide.removeAnimation(forKey: AnimationKeyPaths.aroundAnimationKey)
                })
            }
        }
    }
    
    func animationDidEnded(renderIndex: Int, animation: CAAnimation) {
        let keyPath = animation.value(forKeyPath: "keyPath") as? String
        if let animationKF = animation as? CAKeyframeAnimation, animationKF.path != nil,
           keyPath == AnimationKeyPaths.positionAnimationKey {
            if isAnimatePointsClearOpacity, !isAnimatePointsClearOpacityDone {
                animatePointsClearOpacity()
                isAnimatePointsClearOpacityDone = true
            }
        }
        renderDelegate?.animationDidEnded(chart: self,
                                          renderIndex: renderIndex,
                                          animation: animation)
    }
    
    /// animateRenderLayers
    /// - Parameters:
    ///   - renderIndex: render index
    ///   - layerOpacity: opacity
    func performAnimateRenderLayers(_ renderIndex: Int, layerOpacity: CGFloat) {
        RenderManager.shared.renders[renderIndex].layers.enumerated().forEach { layerIndex, layer in
            if let animation = dataSource?.animateLayers(chart: self,
                                                         renderIndex: renderIndex,
                                                         layerIndex: layerIndex,
                                                         layer: layer)
            {
                if let animation = animation as? CAAnimationGroup {
                    for anim in animation.animations! {
                        let keyPath = anim.value(forKeyPath: "keyPath") as? String
                        if keyPath == AnimationKeyPaths.pathAnimationKey {
                            performPathAnimation(layer, anim, layerOpacity)
                        } else if keyPath == AnimationKeyPaths.positionAnimationKey {
                            performPositionAnimation(layer, anim, layerOpacity: layerOpacity)
                        } else if keyPath == AnimationKeyPaths.opacityAnimationsKey {
                            performOpacityAnimation(layer, anim)
                        } else {
                            if let keyPath = keyPath {
                                print("Unknown key path \(keyPath)")
                            }
                        }
                    }
                } else {
                    let keyPath = animation.value(forKeyPath: "keyPath") as? String
                    if keyPath == AnimationKeyPaths.pathAnimationKey {
                        performPathAnimation(layer, animation, layerOpacity)
                    } else if keyPath == AnimationKeyPaths.positionAnimationKey {
                        performPositionAnimation(layer, animation, layerOpacity: layerOpacity)
                    } else if keyPath == AnimationKeyPaths.opacityAnimationsKey {
                        performOpacityAnimation(layer, animation)
                    } else if keyPath == AnimationKeyPaths.rideProgresAnimationsKey {
                        performRunRideProgressAnimation(layerToRide: layerToRide,
                                                        renderIndex: renderIndex,
                                                        scrollAnimation: isScrollAnimation && !isScrollAnimnationDone,
                                                        page: numberOfPages - 1)
                        isScrollAnimnationDone = true
                    } else {
                        if let keyPath = keyPath {
                            print("Unknown key path \(keyPath)")
                        }
                    }
                }
            }
        }
    }
    
    private func cacheIfNeeded() {
        let flatPointsToRender = RenderManager.shared.dataPoints.flatMap { $0 }
        if flatPointsToRender.isEmpty == false {
            let frameHash = frame.hashValue
            let pointsHash = flatPointsToRender.hashValue
            let dictKey = "\(frameHash ^ pointsHash)"
            if (layoutCache[dictKey] as? [[CGPoint]]) != nil {
                print("[LCACHE] cache hit \(dictKey) [PKJI]")
                cacheTrackingLayout += 1
                setNeedsDisplay()
                return
            }
            print("[LCACHE] cache miss \(dictKey) [PKJI]")
            cacheTrackingLayout = 0
            layoutCache.updateValue(RenderManager.shared.dataPoints,
                                    forKey: dictKey)
        }
    }
    
    
    
    private func regenerateLayerTree() {
        print("Regenerating the layer tree.")
        
        removeAllLayers()
        addLeadingRuleIfNeeded(ruleManager.rootRule, view: self)
        addFooterRuleIfNeeded(ruleManager.footerRule)
        rulebottomAnchor?.isActive = true
        
        if renderSourceNumberOfRenders > 0 {
            // layout renders
            layoutRenders()
            // layout rules
            layoutRules()
        }
        
        if !isScrollAnimnationDone, isScrollAnimation {
            isScrollAnimnationDone = true
            scrollingProgressAnimatingToPage(scrollingProgressDuration,
                                             page: numberOfPages - 1) {
                
            }
        } else {
            // Only animate if the points if the render its visible (hidden).
            if rendersIsVisible(renderIndex: RenderIdentify.points.rawValue) {
                animatePointsClearOpacity()
            }
            
        }
    }
    
    /// Update the chart layout
    /// - Parameter forceLayout: Bool
    func updateLayout(ignoreLayoutCache: Bool = false) {
        print("updateLayout for render points bounded at frame \(frame) cache: \(ignoreLayoutCache ? "IGNORE" : "").")
        // If we need to force layout, we must ignore the layoput cache.
        if ignoreLayoutCache == false {
            if isLayoutCacheActive {
                cacheIfNeeded()
            }
        }
        // Create the points from the discrete data using the renders
        if layoutLayer == true {
            layoutLayer = false
            if CALayer.isAnimatingLayers <= 0 {
                regenerateLayerTree()
                layoutLayer = true
            } else {
                print("Unable to layout: \(CALayer.isAnimatingLayers) animations running")
                layoutLayer = true
            }
        } else {
            print("Already in layout.")
        }
    }
    
    var layoutLayer: Bool = true
    var oldFrame: CGRect = .zero
}

extension OMScrollableChart {
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        setupView()
        clearsContextBeforeDrawing = true
    }
    
    /// layerDidTouch
    /// - Parameters:
    ///   - render: render description
    ///   - selectedLayer: selectedLayer description
    ///   - location: location description
    private func layerDidTouch(_ render: BaseRender, _ selectedLayer: ShapeLayer?, _ location: CGPoint) {
        guard let layer = selectedLayer else { return }
        if animateLineSelection {
            if let path = polylinePath {
                let anim = perfromAnimateLineSelection(with: layer, path)
                print(anim)
            }
        }
        selectRenderLayerWithAnimation(render,
                                       layer,
                                       location)
    }
    
    private func printLayersInSections() {
        // all renders
        print("layer\t\tsection")
        for render in RenderManager.shared.renders.reversed() {
            render.layers.forEach {print("\(String(describing: $0.name))\t\t\(sectionFromPoint(render: render, layer: $0))")}
        }
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let location: CGPoint = locationFromTouchInContentView(touches)
        // updateLineSelectionLayer(location)
        let hitTestLayer = hitTestAsLayer(location)
        if let hitTestShapeLayer = hitTestLayer {
            var isSelected: Bool = false
            
            printLayersInSections()
            
            for render in RenderManager.shared.renders.reversed() {
                
           
                // skip polyline layer for touch
                guard render.index != RenderIdentify.polyline.rawValue else { continue }
                // Get the point more near for this render
                let selectedLayerInCurrentRender = render.locationToLayer(location)
                if dataSource?.renderOpacity(chart: self, renderIndex: render.index ) ?? 0 > 0 {
                    if let selectedLayer = selectedLayerInCurrentRender {
                        if hitTestShapeLayer == selectedLayer ||
                            hitTestShapeLayer == selectedLayer.superlayer {
                            layerDidTouch(render, selectedLayer, location)
                            print("[HHS] hitted && selected: \(String(describing: selectedLayer.name))")
                            isSelected = true
                        } else {
                            layerDidTouch(render, selectedLayer, location)
                            print("[HHS] Selected: \(String(describing: selectedLayer.name))")
                            isSelected = true
                        }
                    } else {
                        if let selectedLayerInCurrentRender = selectedLayerInCurrentRender {
                            layerDidTouch(render, selectedLayerInCurrentRender, location)
                            print("[HHS] selected: \(String(describing: selectedLayerInCurrentRender.name))")
                            isSelected = true
                        }
                    }
                } else {
                    print("[HHS] render index \(render.index) is hidden")
                }
            }
            
            if !isSelected {
                // test the layers
                let pointsRender = RenderManager.shared.points
                if let _ = RenderManager.shared.polyline.locationToLayer(location),
                   let selectedLayer = pointsRender.locationToLayer(location)
                {
                    let selectedLayerPoint = CGPoint(x: selectedLayer.position.x, y: selectedLayer.position.y)
                    print("[HHS] Location \(location) selectedLayerPoint \(selectedLayerPoint)")
                    selectRenderLayerWithAnimation(pointsRender,
                                                   selectedLayer,
                                                   location,
                                                   true)
                }
            }
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let location: CGPoint = locationFromTouchInContentView(touches)
        // updateLineSelectionLayer(location)
        tooltip.moveTooltip(location)
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let location: CGPoint = locationFromTouchInContentView(touches)
        tooltip.hideTooltip(location)
    }
    
    override public var contentOffset: CGPoint {
        get {
            return super.contentOffset
        }
        set(newValue) {
            if contentOffset != newValue {
                super.contentOffset = newValue
            }
        }
    }
    
    override public var frame: CGRect {
        set(newValue) {
            oldFrame = super.frame
            super.frame = newValue
            if oldFrame != super.frame {
                setNeedsLayout()
            }
        }
        get { return super.frame }
    }
    
    private func layoutForFrame() {
        let updated = updateDataSourceData()
        if updated {
            forceLayoutReload()
        } else {
            print("layout is 1")
        }
    }
    /// updateRendersOpacity
    
    private func updateRendersOpacity() {
        // Create the points from the discrete data using the renders
        print("Updating \(RenderManager.shared.allRendersLayers.count) renders layers opacity ")
        if RenderManager.shared.allRendersLayers.isEmpty == false {
            if let render = renderSource, let dataSource = dataSource, render.numberOfRenders > 0 {
                for render in RenderManager.shared.renders {
                    print("Check if layers want opacity.")
                    let layerOpacityResult = render.layers.map {
                        return dataSource.renderLayerOpacity(chart: self,
                                                             renderIndex: render.index,
                                                             layer: $0)
                    }
                    
                    print("Render \(render.index) count: \(render.layers.count) result: \(layerOpacityResult)")
                    if layerOpacityResult.isEmpty {
                        print("Check if render want opacity.")
                        let layerOpacity = dataSource.renderOpacity(chart: self, renderIndex: render.index)
                        // layout renders opacity
                        updateRenderLayersOpacity(for: render.index,
                                                  layerOpacity: layerOpacity)
                    } else {
                        assert(layerOpacityResult.count == render.layers.count)
                        render.layers.enumerated().forEach {
                            if layerOpacityResult[$0] != nil {
                                $1.opacity =  Float(layerOpacityResult[$0] ?? Opacity.hide.rawValue)
                            }
                        }
                    }
                }
            }
            print("Layers visibles \(RenderManager.shared.visibleLayers.count) no visibles \(RenderManager.shared.invisibleLayers.count)")
        } else {
            print("unexpected empty allRendersLayers")
        }
        
    }
    
    private func animatePointsClearOpacity(duration: TimeInterval = 4.0) {
        guard RenderManager.shared.points.layers.isEmpty == false else {
            return
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        for layer in RenderManager.shared.points.layers {
            let anim = performAnimationOpacity(layer,
                                               fromValue: CGFloat(layer.opacity),
                                               toValue: 0.0)
            layer.add(anim,
                      forKey: ScrollableRendersConfiguration.animationPointsClearOpacityKey)
        }
        CATransaction.commit()
    }
    
    override public func layoutSubviews() {
        backgroundColor = .clear
        super.layoutSubviews()
        if oldFrame != frame {
            layoutForFrame()
        } else {
            updateRendersOpacity()
        }
        
        //        layoutBezierPath()
    }
    
    
    
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        if let ctx = UIGraphicsGetCurrentContext() {
            if drawPolylineGradient {
                if layersToStroke.count > 0 {
                    for stroker in layersToStroke {
                        let lineWidth_2 = lineWidth * 2
                        let darkerColor = lineColor.darker
                        strokeGradient(ctx: ctx,
                                       layer: stroker.layer,
                                       points: stroker.points,
                                       color: darkerColor,
                                       lowColor: darkerColor.complementaryColor,
                                       lineWidth: lineWidth_2,
                                       fadeFactor: 0.8)
                    }
                    
                    strokeGradient(ctx: ctx,
                                   layer: polylineLayer,
                                   points: polylinePoints,
                                   color: lineColor,
                                   lineWidth: lineWidth,
                                   fadeFactor: polylineGradientFadePercentage)
                } else {
                    
                    guard let path = polylinePath, let point = polylinePoints?.first, let lastPoint = polylinePoints?.last else { return }
                    let st = CGPoint(x: point.x * bounds.width,
                                     y: point.y * bounds.height)
                    let ls = CGPoint(x: lastPoint.x * bounds.width,
                                     y: lastPoint.y * bounds.height)
                    stroke(in: ctx,
                           path: path.cgPath,
                           lineWidth: lineWidth,
                           startPoint: st,
                           endPoint: ls,
                           startRadius: 0,
                           endRadius: Swift.max(path.bounds.width, path.bounds.height),
                           strokeColor: .white,
                           lowColor: .black,
                           axial: false)
                    
                    stroke(in: ctx,
                           path: path.cgPath,
                           lineWidth: lineWidth,
                           startPoint: st,
                           endPoint: ls,
                           startRadius: 0,
                           endRadius: Swift.max(path.bounds.width,path.bounds.height),
                           strokeColor: .white,
                           lowColor: .black,
                           axial: true)
                    
                }
                //                else {
                //                if drawPolylineSegmentFill {
                //                    ctx.saveGState()
                //                    // Clip to the path
                //                    let paths = polylineSubpaths
                //                    for (index, path) in paths.enumerated() {
                //                        let pathToFill = UIBezierPath(cgPath: path.cgPath)
                //                        pathToFill.lineWidth = 0.5
                //                        lineColor.withAlphaComponent(1.0 - CGFloat(CGFloat(paths.count) / 1.0) * CGFloat(index)).setFill()
                //                        pathToFill.fill()
                //                    }
                //
                //                    ctx.restoreGState()
                //                }
                //            }
            }
            // drawVerticalGridLines()
            // drawHorizalGridLines()
            // Specify a border (stroke) color.
            // UIColor.black.setStroke()
            // pathVertical.stroke()
            // pathHorizontal.stroke()
        }
    }
    
    // MARK: Scroll Delegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isTracking {
            // self.setNeedsDisplay()
        }
        ruleLeadingAnchor?.constant = contentOffset.x
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {}
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        // self.layoutIfNeeded()
    }
}
