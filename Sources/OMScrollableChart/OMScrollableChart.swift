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
    func dataLayers(chart: OMScrollableChart, renderIndex: Int, section: Int, data: RenderData) -> [GradientShapeLayer]
    func footerSectionsText(chart: OMScrollableChart) -> [String]?
    func dataPointTootipText(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, section: Int) -> String?
    func dataOfRender(chart: OMScrollableChart, renderIndex: Int) -> RenderType
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

//public struct LayerStroker {
//    public var layer: GradientShapeLayer
//    public var points: [CGPoint]
//    public init( layer: GradientShapeLayer, points: [CGPoint]) {
//        self.layer = layer
//        self.points = points
//    }
//}


public struct AnimationConfiguration {
    var animatePointLayers: Bool = false
    var animateLineSelection: Bool = false
    var showPointsOnSelection: Bool = true
    var animateOnRenderLayerSelection: Bool = true
    var animatePolyLine = false
    var animateDashLines: Bool = false
    var animatePointsOnSelectionLayers: Bool = false
    var isAnimateLineSelection: Bool = false
    var isScrollAnimation: Bool = false
    var isScrollAnimnationDone: Bool = false
    public let scrollingAnimationProgressDuration: TimeInterval = 1.2
    var showTooltip: Bool = true
    var rideAnim: CAAnimation?
    var layerToRide: CALayer?
    var ridePath: Path?
    public var pathRideToPointAnimationDuration: TimeInterval = 5.0
    var selectedColor = UIColor.red
    var selectedOpacy: Float = 1.0
    var unselectedOpacy: Float = 0.1
    var unselectedColor = UIColor.clear
    var zoomIsActive: Bool = false
    var isFooterRuleAnimated: Bool = false
}


@objcMembers
public final class OMScrollableChart: UIScrollView,
                                      ChartProtocol,
                                      CAAnimationDelegate,
                                      UIGestureRecognizerDelegate, RenderEngineClientProtocol, UIScrollViewDelegate {
    private var instancedRenderManager: RenderManagerProtocol!
    public var engine: RenderManagerProtocol { instancedRenderManager }
    private func instanciateRenderManager(_ renderManagerClass: AnyClass) {
        let stringFromClass = NSStringFromClass(renderManagerClass)
        let managerClass = NSClassFromString(stringFromClass) as! RenderManagerProtocol.Type
        instancedRenderManager = managerClass.init()
        print("Render engine loaded! version: \(instancedRenderManager.version)")
    }
    
    public var renderManagerClass: RenderManagerProtocol.Type? {
        didSet {
            if let renderManagerClass = renderManagerClass as? AnyClass {
                // instanciate
                instanciateRenderManager(renderManagerClass)
            }
        }
    }
    
//    private var pointsLayer = GradientShapeLayer()
    var dashLineLayers = [GradientShapeLayer]()
    var flowDelegate: OMScrollableChartRuleDelegate? = OMScrollableChartRuleFlow()
    var isAnimatePointsClearOpacity: Bool = true
    var isAnimatePointsClearOpacityDone: Bool = false
    
    var cacheTrackingLayout: Int = 0
    var isCacheStable: Bool {
        return cacheTrackingLayout > 1
    }
    

    
    public var dotPathLayers = [ShapeRadialGradientLayer]()

   
    public var animations: AnimationConfiguration = .init()
    
    var bezier: BezierPathSegmenter?
    var showPolylineNearPoints: Bool = true
    
    public var ruleManager: RuleManager = .init()
    
    public weak var dataSource: OMScrollableChartDataSource?
    public weak var renderSource: OMScrollableChartRenderableProtocol?
    public weak var renderDelegate: OMScrollableChartRenderableDelegateProtocol?
    
    var polylineGradientFadePercentage: CGFloat = 0.4
    var drawPolylineGradient: Bool = true
    var drawPolylineSegmentFill: Bool = false

    public var lineColor = UIColor.greyishBlue
    public var selectedPointColor: UIColor = .darkGreyBlueTwo
    public var lineWidth: CGFloat = 6
    public var strokeLineColor: UIColor?
    


    var pointsLayersShadowOffset = CGSize(width: 0, height: 0.5)

    /// Animate show unselected points

    
    // MARK: - Layout Cache -
    
    // cache hashed frame + points
    var layoutCache = [String: Any]()
    var isLayoutCacheActive: Bool = false
    

    // Content view
    lazy var contentView: UIView = {
        let lazyContentView = UIView(frame: self.bounds)
        lazyContentView.layer.name = "contentViewLayer"
        self.addSubview(lazyContentView)
        return lazyContentView
    }()
    
    // Content view
     public var rootRenderLayer: CALayer {
        return contentView.layer
    }
    
    // Debug polyline path
    var lineShapeLayerLineWidth: CGFloat = 2.0
    public lazy var lineShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = lineShapeLayerLineWidth
        layer.strokeColor = UIColor.black.cgColor
        layer.fillColor = UIColor.clear.cgColor
        
        layer.strokeColor = UIColor.lightGray.cgColor
        layer.lineWidth = 1
        layer.lineDashPattern = [2, 1] // 7 is the length of dash, 3 is length of the gap.
        
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
    
    lazy var pathNearPointsPanGesture: UIPanGestureRecognizer = {
        let rev = UIPanGestureRecognizer(target: self, action: #selector(pathNearPointsHandlePan(_:)))
        rev.delegate = self
        return rev
    }()
    
    var linFunction: (slope: Float, intercept: Float)?
    
    // Polyline render index 0
    public var polylinePoints: [CGPoint]? {
        return engine.renders[RenderIdent.polyline.rawValue].data.points
    }
    
    public var polylineDataPoints: [Float]? {
        return engine.renders[RenderIdent.polyline.rawValue].data.data
    }
    
    // Points render index 1
    public var pointsPoints: [CGPoint]? {
        return engine.renders[RenderIdent.points.rawValue].data.points
    }
    
    public var pointsDataPoints: [Float]? {
        return engine.renders[RenderIdent.points.rawValue].data.data
    }
    
    // Selected Layers
    public var renderSelectedPointsLayer: CAShapeLayer? {
        return engine.renders[RenderIdent.selectedPoint.rawValue].layers.first
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
    private func unregisterNotifications() {
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
        flowDelegate?.deviceRotation()
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
        
        
        self.addPrivateGestureRecognizer()
        
        
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
                                       height: contentSize.height - ruleManager.footerViewHeight)
            
            flowDelegate?.contentSizeChanged(contentSize: newValue)
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
                
                flowDelegate?.dataPointsChanged(dataPoints: dataPoints, for: index)
            }
        } else {
            // Only exist one render.
            let dataPoints = dataSource.dataPoints(chart: self,
                                                   renderIndex: 0,
                                                   section: 0)
            dataPointsRenderNewDataPoints.insert(dataPoints, at: 0)
            
            flowDelegate?.dataPointsChanged(dataPoints: dataPoints, for: 0)
        }
        

        return dataPointsRenderNewDataPoints
    }
    
    func updateRenderEngine(_ dataPointsRender: [[Float]]) {
        
        // Update the renders data
        zip(engine.renders, dataPointsRender).forEach {
            $0.data = RenderData(data: $1, points: [])
        }
    }
    
    public func updateDataSourceRuleNotification(_ dataSource: OMScrollableChartDataSource) {
        if let footerRule = ruleManager.footerRule as? OMScrollableChartRuleFooter {
            if let texts = dataSource.footerSectionsText(chart: self) {
                if texts != footerRule.footerSectionsText {
                    footerRule.footerSectionsText = texts
                    flowDelegate?.footerSectionsTextChanged(texts: texts)
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
                flowDelegate?.numberOfPagesChanged(pages: newNumberOfPages)
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
    public func projectLineStrokeGradient(_ ctx: CGContext,
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
    
//
//    func stroke(in ctx: CGContext,
//                path: CGPath?,
//                lineWidth: CGFloat,
//                startPoint: CGPoint,
//                endPoint: CGPoint,
//                startRadius: CGFloat,
//                endRadius: CGFloat,
//                strokeColor: UIColor,
//                lowColor: UIColor,
//                fadeFactor: CGFloat = 0.8,
//                axial: Bool = true) {
//
//
//        ctx.saveGState()
//
//
//        let locations = [0, fadeFactor, 1 - fadeFactor, 1]
//        let gradient = CGGradient(colorsSpace: nil,
//                                  colors: [lowColor.withAlphaComponent(0.1).cgColor,
//                                           strokeColor.cgColor,
//                                           strokeColor.withAlphaComponent(fadeFactor).cgColor,
//                                           lowColor.withAlphaComponent(0.8).cgColor] as CFArray,
//                                  locations: locations)!
//
//        var start = CGPoint(x: startPoint.x * self.bounds.size.width, y: startPoint.y * self.bounds.size.height)
//        var end   =  CGPoint(x: endPoint.x * self.bounds.size.width, y: endPoint.y * self.bounds.size.height)
//        // The context must be clipped before scale the matrix.
//        if let path = path {
//            ctx.addPath(path)
//            ctx.setLineWidth(lineWidth)
//            ctx.replacePathWithStrokedPath()
//            ctx.clip()
//        }
//
//        // if we are using the stroke, we offset the from and to points
//        // by half the stroke width away from the center of the stroke.
//        // Otherwise we tend to end up with fills that only cover half of the
//        // because users set the start and end points based on the center
//        // of the stroke.
//        let hw = lineWidth * 0.5;
//        start  = end.projectLine(start,length: hw)
//
//
//        ctx.scaleBy(x: self.bounds.size.width,
//                    y: self.bounds.size.height );
//
//        start = CGPoint(x: start.x / self.bounds.size.width, y: start.y / self.bounds.size.height)
//        end   =  CGPoint(x: end.x / self.bounds.size.width, y: end.y / self.bounds.size.height)
//
//
//        let minimumRadius = minRadius(self.bounds.size)
//
//
//        if axial {
//            ctx.drawLinearGradient(gradient,
//                                   start: start ,
//                                   end: end,
//                                   options: [])
//        } else {
//            ctx.drawRadialGradient(gradient,
//                                   startCenter: start ,
//                                   startRadius: startRadius * minimumRadius,
//                                   endCenter:end ,
//                                   endRadius: endRadius * minimumRadius,
//                                   options: [])
//        }
//        ctx.restoreGState();
//
//    }
    
    /// strokeGradient
    /// - Parameters:
    ///   - ctx: ctx description
    ///   - layer: layer description
    ///   - points: points description
    ///   - color: color description
    ///   - lineWidth: lineWidth description
    ///   - fadeFactor: fadeFactor description
    public func strokeGradient(ctx: CGContext?,
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
                curPath.stroke()
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
   
    private func removeAllLayers() {
        engine.removeAllLayers()
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
                                          layerOpacity: CGFloat) {
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
                                         _ animation: CAAnimation) {
        layer.add(animation, forKey: "renderOpacityAnimation", withCompletion: nil)
    }
    

    internal var renderSourceNumberOfRenders: Int {
        if let render = renderSource {
            return render.numberOfRenders
        }
        return 0
    }
 
    
    /// updateRenderLayersOpacity
    /// - Parameters:
    ///   - renderIndex: Index
    ///   - layerOpacity: CGFloat
    private func updateRenderLayersOpacity(for renderIndex: Int,
                                           layerOpacity: CGFloat,
                                           ignorePoints: Bool = true) {
        // Don't delay the opacity
        if ignorePoints,
           renderIndex == RenderIdent.points.rawValue
        {
            print("Render ´points´ not suitable for task.")
            return
        }
        if renderIndex >= engine.renders.count {
            print("Render \(renderIndex) out of bounds.")
            return
        }
        let layers = engine.renders[renderIndex].layers
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
        //        renderEngine.layers.removeAll()
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
            assert(render.numberOfRenders ==  engine.renders.count)
            for render in engine.renders {
                guard render.data.data.isEmpty == false else {
                    print("render \(render.index) has data.")
                    continue
                }
                // Get the render data. ex: discrete / approx / averaged / regression ...
                let dataOfRender = dataSource.dataOfRender(chart: self,
                                                           renderIndex: render.index)
                print("dataOfRender \(dataOfRender) for render \(render.index)")
                
                
                if dataOfRender != render.data.dataType {
                    flowDelegate?.renderDataTypeChanged(in: dataOfRender)
                }
                
                render.data = RenderData(data: render.data.data,
                                         points: render.data.points,
                                         type: dataOfRender )
                
                renderLayers(with: render, size: drawableFrame.size)
            }
            
            print("adding \(engine.allRendersLayers.count) layers")
            // add layers
            for (renderIndex, render) in engine.renders.enumerated() {
                
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
            for render in engine.renders {
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
        if let anim = animations.rideAnim {
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
        engine.renders[renderIndex].layers.enumerated().forEach { layerIndex, layer in
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
                        performRunRideProgressAnimation(layerToRide: animations.layerToRide,
                                                        renderIndex: renderIndex,
                                                        scrollAnimation: animations.isScrollAnimation && !animations.isScrollAnimnationDone,
                                                        page: numberOfPages - 1)
                        animations.isScrollAnimnationDone = true
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
        let flatPointsToRender = engine.points.flatMap { $0 }
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
            layoutCache.updateValue(engine.points,
                                    forKey: dictKey)
        }
    }
    
    
    
    private func regenerateLayerTree() {
        print("Regenerating the layer tree.")
        
        removeAllLayers()
        addLeadingRuleIfNeeded(ruleManager.rootRule, view: self)
        addFooterRuleIfNeeded(ruleManager.footerRule)
        ruleManager.rulebottomAnchor?.isActive = true
        
        if renderSourceNumberOfRenders > 0 {
            // layout renders
            layoutRenders()
            // layout rules
            layoutRules()
        }
        
        if !animations.isScrollAnimnationDone, animations.isScrollAnimation {
            animations.isScrollAnimnationDone = true
            scrollingProgressAnimatingToPage(animations.scrollingAnimationProgressDuration,
                                             page: numberOfPages - 1) {
                
            }
        } else {
            // Only animate if the points if the render its visible (hidden).
            if rendersIsVisible(renderIndex: RenderIdent.points.rawValue) {
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
    
    /// layerDidTouchAtLocation
    /// - Parameters:
    ///   - render: render description
    ///   - selectedLayer: selectedLayer description
    ///   - location: location description
    private func layerDidTouchAtLocation(_ render: BaseRender, _ selectedLayer: ShapeLayer?, _ location: CGPoint) {
        guard let layer = selectedLayer else { return }
        if animations.animateLineSelection {
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
        print("\t\tlayer\t\tsection")
        for render in engine.renders.reversed() {
            render.layers.forEach {
                print(
                
                """
                        \t\t\($0.name ?? "")\t\t\(render.sectionIndex(withPoint: $0.position, numberOfSections: numberOfSections))
                """)
                
            }
        }
    }
    
    func processTouchForVisibleRendes(_ selectedLayerInCurrentRender: GradientShapeLayer?,
                                   _ hitTestShapeLayer: CALayer,
                                   _ render: ReversedCollection<[BaseRender]>.Element,
                                   _ location: CGPoint) -> Bool {
        if let selectedLayer = selectedLayerInCurrentRender {
            if hitTestShapeLayer == selectedLayer ||
                hitTestShapeLayer == selectedLayer.superlayer {
                layerDidTouchAtLocation(render, selectedLayer, location)
                print("[HHS] hitted && selected: \(String(describing: selectedLayer.name))")
                return true
            } else {
                layerDidTouchAtLocation(render, selectedLayer, location)
                print("[HHS] Selected: \(String(describing: selectedLayer.name))")
                return true
            }
        } else {
            if let selectedLayerInCurrentRender = selectedLayerInCurrentRender {
                layerDidTouchAtLocation(render, selectedLayerInCurrentRender, location)
                print("[HHS] selected: \(String(describing: selectedLayerInCurrentRender.name))")
                return true
            }
        }
        
        return false
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let location: CGPoint = locationFromTouchInContentView(touches)
        // updateLineSelectionLayer(location)
        let hitTestLayer = hitTestAsLayer(location)
        
        if let hitTestShapeLayer = hitTestLayer {
            var isSelected: Bool = false
            
//            printLayersInSections()
            
            for render in engine.renders.reversed() {
                // skip polyline layer for touch
                guard render.index != RenderIdent.polyline.rawValue else { continue }
                // Get the point more near for this render
                let selectedLayerInCurrentRender = render.locationToLayer(location)
                if dataSource?.renderOpacity(chart: self, renderIndex: render.index ) ?? 0 > 0 {
                    isSelected = processTouchForVisibleRendes(selectedLayerInCurrentRender,
                                                                hitTestShapeLayer,
                                                                render,
                                                                location)
                } else {
                    print("[HHS] render index \(render.index) is hidden")
                }
            }
            
            if !isSelected {
                // test the layers

                if let _ = engine.renders[RenderIdent.polyline.rawValue].locationToLayer(location),
                   let selectedLayer = engine.renders[RenderIdent.points.rawValue].locationToLayer(location)
                {
                    let selectedLayerPoint = CGPoint(x: selectedLayer.position.x, y: selectedLayer.position.y)
                    print("[HHS] Location \(location) selectedLayerPoint \(selectedLayerPoint)")
                    selectRenderLayerWithAnimation( engine.renders[RenderIdent.points.rawValue],
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
                flowDelegate?.frameChanged(frame: super.frame)
                layoutForFrame()
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
        print("Updating \(engine.allRendersLayers.count) renders layers opacity ")
        if engine.allRendersLayers.isEmpty == false {
            if let render = renderSource, let dataSource = dataSource, render.numberOfRenders > 0 {
                for render in engine.renders.reversed() {
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
            print("Layers visibles \(engine.visibleLayers.count) no visibles \(engine.invisibleLayers.count)")
        } else {
            print("Unexpected empty allRendersLayers")
        }
        
    }
    
    private func animatePointsClearOpacity(duration: TimeInterval = 4.0) {
        guard  engine.renders[RenderIdent.points.rawValue].layers.isEmpty == false else {
            return
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        for layer in  engine.renders[RenderIdent.points.rawValue].layers {
            let anim = performAnimationOpacity(layer,
                                               fromValue: CGFloat(layer.opacity),
                                               toValue: 0.0)
            layer.add(anim,
                      forKey: ScrollableRendersConfiguration.animationPointsClearOpacityKey)
        }
        CATransaction.commit()
    }
    

    
    // MARK: Scroll Delegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isTracking {
            // self.setNeedsDisplay()
        }
        ruleManager.ruleLeadingAnchor?.constant = contentOffset.x
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {}
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        // self.layoutIfNeeded()
    }
}
