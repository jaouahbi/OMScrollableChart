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

public enum Opacity: CGFloat {
    case show = 1.0
    case hide = 0.0
}

enum OMSCConfig {
    static let animationPointsClearOpacityKey: String = "animationPointsClearOpacityKey"
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
    func numberOfPages(chart: OMScrollableChart) -> CGFloat
    func dataLayers(chart: OMScrollableChart, renderIndex: Int, section: Int, data: DataRender) -> [OMGradientShapeClipLayer]
    func footerSectionsText(chart: OMScrollableChart) -> [String]?
    func dataPointTootipText(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, section: Int) -> String?
    func dataOfRender(chart: OMScrollableChart, renderIndex: Int) -> RenderDataType
    func dataSectionForIndex(chart: OMScrollableChart, dataIndex: Int, section: Int) -> String?
    func numberOfSectionsPerPage(chart: OMScrollableChart) -> Int
    func renderLayerOpacity(chart: OMScrollableChart, renderIndex: Int) -> CGFloat
    func queryAnimation(chart: OMScrollableChart, renderIndex: Int) -> AnimationTiming
    func animateLayers(chart: OMScrollableChart, renderIndex: Int, layerIndex: Int, layer: OMGradientShapeClipLayer) -> CAAnimation?
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

@objcMembers
public final class OMScrollableChart: UIScrollView, UIScrollViewDelegate, ChartProtocol, CAAnimationDelegate, UIGestureRecognizerDelegate {
    private var pointsLayer = OMGradientShapeClipLayer()
    var dashLineLayers = [OMGradientShapeClipLayer]()
//    var rootRule: ChartRuleProtocol?
//    var footerRule: ChartRuleProtocol?
//    var topRule: ChartRuleProtocol?
//    var rules = [ChartRuleProtocol]() // todo
    
    var isAnimatePointsClearOpacity: Bool = true
    var isAnimatePointsClearOpacityDone: Bool = false
    
    
    var cacheTrackingLayout: Int = 0
    var isCacheStable: Bool {
        return cacheTrackingLayout > 1
    }

    var isScrollAnimation: Bool = true
    var isScrollAnimnationDone: Bool = false
    let scrollingProgressDuration: TimeInterval = 1.2
    
    public var pathDots = [CAShapeLayer]()
    public var layersToStroke: [(OMGradientShapeClipLayer, [CGPoint])] = []

    var showPolylineNearPoints: Bool = true
    
    var estimatedFooterViewHeight: CGFloat = 60
    var animatePointLayers: Bool = false
    var animateLineSelection: Bool = false
    
    //    var rootRule: ChartRuleProtocol?
    //    var footerRule: ChartRuleProtocol?
    //    var topRule: ChartRuleProtocol?
    //    var rules = [ChartRuleProtocol]() // todo
    public var ruleManager: RuleManager = .init()
    public weak var dataSource: OMScrollableChartDataSource?
    public weak var renderSource: OMScrollableChartRenderableProtocol?
    public weak var renderDelegate: OMScrollableChartRenderableDelegateProtocol?
    var polylineGradientFadePercentage: CGFloat = 0.4
    var drawPolylineGradient: Bool = true
    public var isFooterRuleAnimated: Bool = true
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
    var isAllowedPathDebug: Bool = false

    // MARK: - Layout Cache -

    // cache hashed frame + points
    var layoutCache = [String: Any]()
    var isLayoutCacheActive: Bool = true

    var zoomIsActive: Bool = false

    var allowedPan: Bool = true
//    func minPoint(renderIndex: Int) -> CGPoint? { RenderManager.shared.renders[renderIndex].data.minPoint }
//    func maxPoint(renderIndex: Int) -> CGPoint? { RenderManager.shared.renders[renderIndex].data.maxPoint }
    // Content view
    lazy var contentView: UIView = {
        let lazyContentView = UIView(frame: self.bounds)
        self.addSubview(lazyContentView)
        return lazyContentView
    }()

    // Debug polyline path
    public lazy var lineShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 1.0
        layer.strokeColor = UIColor.red.cgColor
        layer.fillColor = UIColor.clear.cgColor
        self.contentView.layer.addSublayer(layer)
        return layer
    }()

    // Debug polyline path
    public lazy var startPointShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 3.0
        layer.strokeColor = UIColor.red.cgColor
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
        return numberOfSectionsPerPage * Int(numberOfPages)
    }

    public var sectionWidth: CGFloat {
        return contentSize.width / CGFloat(numberOfSections)
    }

    public var numberOfPages: CGFloat = 1 {
        didSet {
            updateContentSize()
        }
    }

    // MARK: - Polyline -

    /// Polyline Interpolation
    public var polylineInterpolation: PolyLineInterpolation = .catmullRom(0.5) {
        didSet {
            updateLayout(ignoreLayoutCache: true) // force layout
        }
    }
    
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
    
    lazy var recognizer: UIPanGestureRecognizer = {
        let rev = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        rev.delegate = self
        return rev
    }()
    
    public var drawableFrame: CGRect {
        return CGRect(origin: .zero, size: contentView.frame.size)
    }

    var linFunction: (slope: Float, intercept: Float)?
    
    // MARK: Default renders

    public enum Renders: Int {
        case polyline = 0
        case points = 1
        case selectedPoint = 2
        case base = 3 //  public renders base index
    }

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
        
        if isAllowedPathDebug {
            contentView.layer.addSublayer(startPointShapeLayer)
            addGestureRecognizer(recognizer)
        }
        
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
    //    var touchScreenLineLayer: OMGradientShapeClipLayer = OMGradientShapeClipLayer()
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
        //        self.layoutIfNeeded()
        let newValue = CGSize(width: bounds.width * numberOfPages, height: bounds.height)
        if contentSize != newValue {
            print("new content size  \(newValue) old: \(contentSize) bounds: \(bounds)")
            contentSize = newValue

        } else {
            print("unchanged content size \(contentSize) bounds: \(bounds)")
        }
        updateLayout()
    }

    // MARK: - contentSize -

    public override var contentSize: CGSize {
        set(newValue) {
            super.contentSize = newValue
            contentView.frame = CGRect(x: 0,
                                       y: 0,
                                       width: newValue.width,
                                       height: newValue.height - estimatedFooterViewHeight)
        }
        get { super.contentSize }
    }
    
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
            // get the data points
            
            updateRenderEngine(queryDataPointsRender(dataSource))
            
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
        let lineLayer = OMGradientShapeClipLayer()
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
            ctx.scaleBy(x: bounds.size.width,
                        y: bounds.size.height)
            ctx.drawLinearGradient(gradient,
                                   start: start,
                                   end: end,
                                   options: [])
        }
        ctx.restoreGState()
    }

    private func strokeGradient(ctx: CGContext?,
                                layer: CAShapeLayer,
                                points: [CGPoint]?,
                                color: UIColor,
                                lineWidth: CGFloat,
                                fadeFactor: CGFloat = 0.4)
    {
        if let ctx = ctx {
            let locations = [0, fadeFactor, 1 - fadeFactor, 1]
            let gradient = CGGradient(colorsSpace: nil,
                                      colors: [UIColor.white.withAlphaComponent(0.1).cgColor,
                                               color.cgColor,
                                               color.withAlphaComponent(fadeFactor).cgColor,
                                               UIColor.white.withAlphaComponent(0.8).cgColor] as CFArray,
                                      locations: locations)!
            // Clip to the path, stroke and enjoy.
            if let path = layer.path {
                color.setStroke()
                let curPath = UIBezierPath(cgPath: path)
                curPath.lineWidth = lineWidth
                curPath.stroke()
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
    
    func performPathAnimation(_ layer: OMGradientShapeClipLayer,
                              _ animation: CAAnimation,
                              _ layerOpacity: CGFloat)
    {
        if layer.opacity == 0 {
            let anim = animationWithFadeGroup(layer,
                                              fromValue: CGFloat(layer.opacity),
                                              toValue: layerOpacity,
                                              animations: [animation])
            layer.add(anim, forKey: "renderPathAnimationGroup", withCompletion: nil)
        } else {
            layer.add(animation, forKey: "renderPathAnimation", withCompletion: nil)
        }
    }
    
    private func performPositionAnimation(_ layer: OMGradientShapeClipLayer,
                                          _ animation: CAAnimation,
                                          layerOpacity: CGFloat)
    {
        let anima = animationWithFadeGroup(layer,
                                           toValue: layerOpacity,
                                           animations: [animation])
        if layer.opacity == 0 {
            layer.add(anima, forKey: "renderPositionAnimationGroup", withCompletion: nil)
        } else {
            layer.add(animation, forKey: "renderPositionAnimation", withCompletion: nil)
        }
    }
    
    private func performOpacityAnimation(_ layer: OMGradientShapeClipLayer,
                                         _ animation: CAAnimation)
    {
        layer.add(animation, forKey: "renderOpacityAnimation", withCompletion: nil)
    }
    
    /// updateRenderLayersOpacity
    /// - Parameters:
    ///   - renderIndex: index
    ///   - layerOpacity: CGFloat
    func updateRenderOpacity(for renderIndex: Int, opacity: CGFloat) {
        // Don't delay the opacity
        if RenderManager.shared.layers.isEmpty || renderIndex == RenderIdent.points.rawValue {
            return
        }
        RenderManager.shared.layers[renderIndex].enumerated().forEach { _, layer in
            layer.opacity = Float(opacity)
        }
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
    
    //    func performPathAnimation(_ layer: OMGradientShapeClipLayer,
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
    //    private func performPositionAnimation(_ layer: OMGradientShapeClipLayer,
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
    //    private func performOpacityAnimation(_ layer: OMGradientShapeClipLayer,
    //                                             _ animation: CAAnimation) {
    //
    //        layer.add(animation, forKey: "renderOpacityAnimation", withCompletion: nil)
    //    }
    
    private func updateRenderLayersOpacity(for renderIndex: Int, layerOpacity: CGFloat) {
        // Don't delay the opacity
        if renderIndex == Renders.points.rawValue {
            print("Render ´points´ not suitable for task.")
            return
        }
        if renderIndex >= RenderManager.shared.renders.count {
            print("render \(renderIndex) out of bounds.")
            return
        }
        let layers = RenderManager.shared.renders[renderIndex].layers
        guard layers.count > 0 else {
            print("render \(renderIndex) out of layers.")
            return
        }
        layers.enumerated().forEach { _, layer in
//            print("Render \(renderIndex) layer #\(index) {\(layer.name)} opacity \(layerOpacity)")
            layer.opacity = Float(layerOpacity)
        }
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
    /// - Parameters:
    ///   - numberOfRenders: Int
    ///   - dataSource: OMScrollableChartDataSource
    func queryDataAndRegenerateRendersLayers(_ numberOfRenders: Int, _ dataSource: OMScrollableChartDataSource) -> Int {
        var numberOfLayerAdded: Int = 1
        // reset the internal data
        resetRenderData()
        // render layers
        for renderIndex in 0..<numberOfRenders {
            guard RenderManager.shared.renders[renderIndex].data.data.isEmpty == false else {
                print("render \(renderIndex) has data.")
                continue
            }
            // Get the render data. ex: discrete / approx / averaged / regression ...
            let dataOfRender = dataSource.dataOfRender(chart: self,
                                                       renderIndex: renderIndex)
            print("dataOfRender \(dataOfRender) for render \(renderIndex)")
            renderLayers(from: renderIndex,
                         size: drawableFrame.size,
                         renderAs: dataOfRender)
        }
        
        print("adding \(RenderManager.shared.allRendersLayers.count) layers")
        // add layers
        for (renderIndex, render) in RenderManager.shared.renders.enumerated() {
            // Insert the render layers
            print("adding \(render.layers.count) layers for render \(renderIndex)")
            render.layers.forEach {
                self.contentView.layer.insertSublayer($0, at: UInt32(renderIndex))
            }
        }
        
        return numberOfLayerAdded
    }
    
    lazy var polylineLayer: OMGradientShapeClipLayer = {
        let polyline = OMGradientShapeClipLayer()
        return polyline
    }()
    
    func polylineLayerPathDidChange(layer: CAShapeLayer) {
        print("path change in ´\(layer.name)´ layer")
        polylineLayerBezierPathDidLoad(layer)
    }
    
    func rendersIsVisible(renderIndex: Int) -> Bool {
        if let dataSource = dataSource {
            return dataSource.renderLayerOpacity(chart: self,
                                                 renderIndex: renderIndex) == 1.0
        }
        return false
    }
    
    /// layoutRenders
    /// - Parameters:
    ///   - numberOfRenders: numberOfRenders
    ///   - dataSource: OMScrollableChartDataSource
    func layoutRenders(_ numberOfRenders: Int, _ dataSource: OMScrollableChartDataSource) {
        print("layoutRenders, regenerate and update animation")
        
        queryDataAndRegenerateRendersLayers(numberOfRenders, dataSource)
        // update with animation
        for renderIndex in 0..<numberOfRenders {
            // Get the opacity
            
            let layerOpacity = dataSource.renderLayerOpacity(chart: self,
                                                             renderIndex: renderIndex)
            updateRenderLayersOpacity(for: renderIndex, layerOpacity: layerOpacity)
            let CNT = RenderManager.shared.renders[renderIndex].layers.count
            let timing = dataSource.queryAnimation(chart: self, renderIndex: renderIndex)
            if timing == .repe {
                print("Animating the render: \(renderIndex) layers: \(CNT).")
                animateRenderLayers(renderIndex,
                                    layerOpacity: layerOpacity)
            } else {
                print("The render \(renderIndex) dont want animate its \(CNT) layers.")
            }
        }
    }
    
    private func scrollingProgressAnimatingToPage(_ duration: TimeInterval, page: Int) {
        let delay: TimeInterval = 0.5
        let preTimeOffset: TimeInterval = 1.0
        let duration: TimeInterval = duration + delay - preTimeOffset
        layoutIfNeeded()
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: .curveEaseInOut,
                       animations: {
                           self.contentOffset.x = self.bounds.size.width * CGFloat(page)
                       }, completion: { _ in
                           if self.isAnimatePointsClearOpacity,
                              !self.isAnimatePointsClearOpacityDone
                           {
                               self.animatePointsClearOpacity()
                               self.isAnimatePointsClearOpacityDone = true
                           }
                       })
    }

    private func runRideProgress(layerToRide: CALayer?, renderIndex: Int, scrollAnimation: Bool = false) {
        if let anim = rideAnim {
            if let layerRide = layerToRide {
                CATransaction.withDisabledActions {
                    layerRide.transform = CATransform3DIdentity
                }
                if scrollAnimation {
                    scrollingProgressAnimatingToPage(anim.duration, page: 1)
                }
                layerRide.add(anim, forKey: "around", withCompletion: { _ in
                    if let presentationLayer = layerRide.presentation() {
                        CATransaction.withDisabledActions {
                            layerRide.position = presentationLayer.position
                            layerRide.transform = presentationLayer.transform
                        }
                    }
                    self.animationDidEnded(renderIndex: Int(renderIndex), animation: anim)
                    layerRide.removeAnimation(forKey: "around")
                })
            }
        }
    }
    
    func animationDidEnded(renderIndex: Int, animation: CAAnimation) {
        let keyPath = animation.value(forKeyPath: "keyPath") as? String
        if let animationKF = animation as? CAKeyframeAnimation, animationKF.path != nil, keyPath == "position" {
            if isAnimatePointsClearOpacity,
               !isAnimatePointsClearOpacityDone
            {
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
    func animateRenderLayers(_ renderIndex: Int, layerOpacity: CGFloat) {
        RenderManager.shared.layers[renderIndex].enumerated().forEach { layerIndex, layer in
            if let animation = dataSource?.animateLayers(chart: self,
                                                         renderIndex: renderIndex,
                                                         layerIndex: layerIndex,
                                                         layer: layer)
            {
                if let animation = animation as? CAAnimationGroup {
                    for anim in animation.animations! {
                        let keyPath = anim.value(forKeyPath: "keyPath") as? String
                        if keyPath == "path" {
                            performPathAnimation(layer, anim, layerOpacity)
                        } else if keyPath == "position" {
                            performPositionAnimation(layer, anim, layerOpacity: layerOpacity)
                        } else if keyPath == "opacity" {
                            performOpacityAnimation(layer, anim)
                        } else {
                            if let keyPath = keyPath {
                                print("Unknown key path \(keyPath)")
                            }
                        }
                    }
                } else {
                    let keyPath = animation.value(forKeyPath: "keyPath") as? String
                    if keyPath == "path" {
                        performPathAnimation(layer, animation, layerOpacity)
                    } else if keyPath == "position" {
                        performPositionAnimation(layer, animation, layerOpacity: layerOpacity)
                    } else if keyPath == "opacity" {
                        performOpacityAnimation(layer, animation)
                    } else if keyPath == "rideProgress" {
                        runRideProgress(layerToRide: layerToRide,
                                        renderIndex: renderIndex,
                                        scrollAnimation: isScrollAnimation && !isScrollAnimnationDone)
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
        
        ruleLeadingAnchor?.isActive = true
        ruletopAnchor?.isActive = true
        rulebottomAnchor?.isActive = true
        rulewidthAnchor?.isActive = true
        
        if let render = renderSource,
           let dataSource = dataSource, render.numberOfRenders > 0
        {
            // layout renders
            layoutRenders(render.numberOfRenders, dataSource)
            // layout rules
            layoutRules()
        }
        
        if !isScrollAnimnationDone, isScrollAnimation {
            isScrollAnimnationDone = true
            
            scrollingProgressAnimatingToPage(scrollingProgressDuration, page: 1)
        } else {
            // Only animate if the points if the render its visible (hidden).
            if rendersIsVisible(renderIndex: Renders.points.rawValue) {
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

    //   public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        super.touchesBegan(touches, with: event)
    //        let location: CGPoint = locationFromTouchInContentView(touches)
    //        //updateLineSelectionLayer(location)
    //        let hitTestLayer: CALayer? = hitTestAsLayer(location) as? CAShapeLayer
    //        if let hitTestLayer = hitTestLayer {
    //            var isSelected: Bool = false
    //            // skip polyline layer
    //            for renderIndex in 1..<RenderManager.shared.layers.count {
    //                // Get the point more near
    //                let selectedLayer = locationToNearestLayer(renderIndex, location: location, true)
    //                if let selectedLayer = selectedLayer {
    //                    if hitTestLayer == selectedLayer {
    //                        if animateLineSelection,
    //                            let path = self.polylinePath {
    //                            let anim = self.animateLineSelection(selectedLayer, path)
    //                            print(anim)
    //                        }
    //
    //                        selectRenderLayerWithAnimation(selectedLayer,
    //                                                       selectedPoint: location,
    //                                                       renderIndex: renderIndex)
    //                        isSelected = true
    //                    }
    //                }
    //            }
    //            //
    //            if !isSelected {
    //                // test the layers
    //                if let _ = locationToLayer( 0,location:  location, mostNearLayer:  true),
    //                    let selectedLayer = locationToLayer(1, location:  location, mostNearLayer:  true), {
    //                    _ = CGPoint( x: selectedLayer.position.x,
    //                                         y: selectedLayer.position.y )
    //                    selectRenderLayerWithAnimation(selectedLayer,
    //                                                   selectedPoint: location,
    //                                                   animation: true,
    //                                                   renderIndex: 1)
    //                }
    //            }
    //        }
    //    }
    //
    //
    //
    //   public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?){
    //        super.touchesMoved(touches, with: event)
    //        let location: CGPoint = xlocationFromTouchInContentView(touches)
    //        //updateLineSelectionLayer(location)
    //        tooltip.moveTooltip(location)
    //    }
    //   public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        super.touchesEnded(touches , with: event)
    //        let location: CGPoint = locationFromTouchInContentView(touches)
    //        tooltip.hideTooltip(location)
    //    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let location: CGPoint = locationFromTouchInContentView(touches)
        // updateLineSelectionLayer(location)
        let hitTestLayer: CALayer? = hitTestAsLayer(location) as? CAShapeLayer
        if let hitTestLayer = hitTestLayer {
            var isSelected: Bool = false
            // all renders
            for render in RenderManager.shared.renders {
                // skip polyline layer for touch
                guard render.index != Renders.polyline.rawValue else { continue }
                // Get the point more near for this render
                let selectedLayerInCurrentRender = render.locationToLayer(location)
                if let selectedLayer = selectedLayerInCurrentRender {
                    if hitTestLayer == selectedLayer {
                        if animateLineSelection,
                           let path = polylinePath
                        {
                            let anim = animateLineSelection(with: selectedLayer, path)
                            print(anim)
                        }
                        
                        selectRenderLayerWithAnimation(render,
                                                       selectedLayer,
                                                        location)
                        isSelected = true
                    }
                }
            }
            //
            if !isSelected {
                // test the layers
                let pointsRender = RenderManager.shared.points
                if let _ = RenderManager.shared.polyline.locationToLayer(location),
                   let selectedLayer = pointsRender.locationToLayer(location) {
                    let selectedLayerPoint = CGPoint(x: selectedLayer.position.x, y: selectedLayer.position.y)
                    print("Location \(location) selectedLayerPoint \(selectedLayerPoint)")
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

            if oldFrame !=  super.frame {
                setNeedsLayout()
            }
       
        }
        get { return super.frame }
    }

    private func layoutForFrame() {
        if updateDataSourceData() {
            updateLayout(ignoreLayoutCache: true)
        } else {
            // Log.print("layout is 1")
        }
    }

    private func updateRendersOpacity() {
        // Create the points from the discrete data using the renders
        print("Updating \(RenderManager.shared.allRendersLayers.count) renders layers opacity ")
        if RenderManager.shared.allRendersLayers.isEmpty == false {
            if let render = renderSource,
               let dataSource = dataSource, render.numberOfRenders > 0
            {
                for renderIndex in 0..<render.numberOfRenders {
                    let layerOpacity = dataSource.renderLayerOpacity(chart: self,
                                                                     renderIndex: renderIndex)
                    // layout renders opacity
                    updateRenderLayersOpacity(for: renderIndex,
                                              layerOpacity: layerOpacity)
                }
            }
        }
        print("Layers visibles \(RenderManager.shared.visibleLayers.count) no visibles \(RenderManager.shared.invisibleLayers.count)")
    }
    
    private func animatePointsClearOpacity(duration: TimeInterval = 4.0) {
        guard RenderManager.shared.points.layers.isEmpty == false else {
            return
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        for layer in RenderManager.shared.points.layers {
            let anim = animationOpacity(layer,
                                        fromValue: CGFloat(layer.opacity),
                                        toValue: 0.0)
            layer.add(anim,
                      forKey: OMSCConfig.animationPointsClearOpacityKey)
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
        
        layoutBezierPath()
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        //        if let ctx = UIGraphicsGetCurrentContext() {
        //            if drawPolylineGradient {
        //                strokeGradient(ctx: ctx,
        //                               layer: polylineLayer,
        //                               points: polylinePoints,
        //                               color: lineColor,
        //                               lineWidth: lineWidth,
        //                               fadeFactor: polylineGradientFadePercentage)
        //            } else {
        //                ctx.saveGState()
        //                // Clip to the path
        //                if let path = polylineLayer.path {
        //                    let pathToFill = UIBezierPath(cgPath: path)
        //                    self.lineColor.setFill()
        //                    pathToFill.fill()
        //                }
        //                ctx.restoreGState()
        //            }
        //        }
        // drawVerticalGridLines()
        // drawHorizalGridLines()
        // Specify a border (stroke) color.
        // UIColor.black.setStroke()
        // pathVertical.stroke()
        // pathHorizontal.stroke()
    }

    // MARK: Scroll Delegate

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isTracking {
            // self.setNeedsDisplay()
        }
        ruleLeadingAnchor?.constant = contentOffset.x
    }

    //  scrollViewDidEndDragging - The scroll view sends this message when
    //    the user’s finger touches up after dragging content.
    //    The decelerating property of UIScrollView controls deceleration.
    //
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {}

    //    scrollViewWillBeginDecelerating - The scroll view calls
    //    this method as the user’s finger touches up as it is
    //    moving during a scrolling operation; the scroll view will continue
    //    to move a short distance afterwards. The decelerating property of
    //    UIScrollView controls deceleration
    //
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        // self.layoutIfNeeded()
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didScrollingFinished(scrollView: scrollView)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            // didEndDecelerating will be called for sure
            return
        } else {
            didScrollingFinished(scrollView: scrollView)
        }
    }

    public func didScrollingFinished(scrollView: UIScrollView) {
        // Log.print("Scrolling \(String(describing: scrollView.classForCoder)) was Finished", .trace)
    }
}
