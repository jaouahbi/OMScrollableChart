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
    var zoomIsActive: Bool = true
    var isFooterRuleAnimated: Bool = false
    var isAnimatePointsClearOpacity: Bool = true
    var isAnimatePointsClearOpacityDone: Bool = false
}

@objcMembers
public final class OMScrollableChart: UIScrollView,
    ChartProtocol,
    CAAnimationDelegate,
    UIGestureRecognizerDelegate,
    RenderEngineClientProtocol,
    UIScrollViewDelegate
{
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
    
    var showPolylineNearPoints: Bool = true
    var dashLineLayers = [GradientShapeLayer]()
    var flowDelegate: OMScrollableChartRuleDelegate? = OMScrollableChartRuleFlow()

    var cacheTrackingLayout: Int = 0
    var isCacheStable: Bool {
        return cacheTrackingLayout > 1
    }
    
    var layoutLayer: Bool = true
    var oldFrame: CGRect = .zero
    public var dotPathLayers = [ShapeRadialGradientLayer]()
    public var animations: AnimationConfiguration = .init()
    var bezier: BezierPathSegmenter?
    
    public var ruleManager: RuleManager = .init()
    
    public weak var dataSource: OMScrollableChartDataSource?
    public weak var renderDelegate: OMScrollableChartRenderableDelegateProtocol?
    
    var polylineGradientFadePercentage: CGFloat = 0.4
    var drawPolylineGradient: Bool = true
    var drawPolylineSegmentFill: Bool = false

    public var lineColor = UIColor.greyishBlue
    public var selectedPointColor = UIColor.navyTwo.withAlphaComponent(0.23)
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
    
//    public override func draw(_ rect: CGRect) {
//        super.draw(rect)
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
//        // drawVerticalGridLines()
//        // drawHorizalGridLines()
//        // Specify a border (stroke) color.
//        // UIColor.black.setStroke()
//        // pathVertical.stroke()
//        // pathHorizontal.stroke()
//    }
    
    lazy var currencyFormatter: NumberFormatter = {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.maximumFractionDigits = 0
        // localize to your grouping and decimal separator
        currencyFormatter.locale = Locale(identifier: "es_ES")
        return currencyFormatter
    }()
    
    public var numberOfElementsToGrouping: CGFloat = 3 {
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
    
    // 1 seconds pressing and make zoom
    lazy var longPress: UILongPressGestureRecognizer = {
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        lpgr.minimumPressDuration = 1.0
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        return lpgr
    }()
    
    // MARK: - UILongPressGestureRecognizer Action -
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        if gesture.state != .ended {
            return
        }
        let location = gesture.location(in: self)
        // When logn press is start or running
        if animations.zoomIsActive {
            self.performZoomOnSelection( location, 1.3, true, 1.0)
        }
    }
    

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
//            print("contentOffset is now \(object.contentOffset)")
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
//            print("contentSize is now \(object.contentSize) \(object.bounds)")
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
        
        addPrivateGestureRecognizer()
        
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
    
    func queryDataPointsRender() -> [[Float]] {
        var dataPointsRenderNewDataPoints = [[Float]]()
        if engine.renders.count > 0 {
            // Get the layers.
            for render in engine.renders {
                let dataPoints = dataSource?.dataPoints(chart: self,
                                                        renderIndex: render.index,
                                                        section: 0) ?? []
                dataPointsRenderNewDataPoints.insert(dataPoints, at: render.index)
                
                flowDelegate?.dataPointsChanged(dataPoints: dataPoints, for: render.index)
            }
        } else {
            // Only exist one render.
            let dataPoints = dataSource?.dataPoints(chart: self,
                                                    renderIndex: 0,
                                                    section: 0) ?? []
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
    
    public func updateDataSourceRuleNotification() {
        if let footerRule = ruleManager.footerRule as? OMScrollableChartRuleFooter {
            if let texts = dataSource?.footerSectionsText(chart: self) {
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
            updateRenderEngine(queryDataPointsRender())
            // notify to the rule
            updateDataSourceRuleNotification()
            
            let oldNumberOfPages = numberOfPages
            let newNumberOfPages = dataSource.numberOfPages(chart: self) ?? 0
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
        for index in 0 ..< internalPoints.count - 1 {
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
            let anim = animationWithFadeGroup(layer,
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
        let anima = animationWithFadeGroup(layer,
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
            layers.forEach { $0.opacity = Float(0) }
            return
        }
        layers.forEach { $0.opacity = Float(opacity) }
        
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
        if let dataSource = dataSource {
            // reset the internal data
            resetRenderData()
            // render layer
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
                                         type: dataOfRender)
                
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
        if let dataSource = dataSource {
            print("Regenerate and layout animation.")
            let numberOfLayers = queryDataAndRegenerateRendersLayers()
            print("Regenerated \(numberOfLayers) layers renders.")
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
   
    func animationDidEnded(renderIndex: Int, animation: CAAnimation) {
        let keyPath = animation.value(forKeyPath: "keyPath") as? String
        if let animationKF = animation as? CAKeyframeAnimation, animationKF.path != nil,
           keyPath == AnimationKeyPaths.positionAnimationKey
        {
            if animations.isAnimatePointsClearOpacity,
               !animations.isAnimatePointsClearOpacityDone
            {
                animatePointsClearOpacity()
                animations.isAnimatePointsClearOpacityDone = true
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
                        animationProgressRide(layerToRide: animations.layerToRide,
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

    //
    // cacheIfNeeded
    //
    private func cacheIfNeeded() {
        let flatPointsToRender = engine.points.flatMap { $0 }
        if flatPointsToRender.isEmpty == false {
            let frameHash = frame.hashValue
            let pointsHash = flatPointsToRender.hashValue
            let dictKey = "\(frameHash ^ pointsHash)"
            if (layoutCache[dictKey] as? [[CGPoint]]) != nil {
                print("[LCACHE] cache hit \(dictKey)")
                cacheTrackingLayout += 1
                setNeedsDisplay()
                return
            }
            print("[LCACHE] cache miss \(dictKey)")
            cacheTrackingLayout = 0
            layoutCache.updateValue(engine.points,
                                    forKey: dictKey)
        }
    }

    //
    // regenerateLayerTree
    //
    private func regenerateLayerTree() {
        print("Regenerating the layer tree.")
        
        removeAllLayers()
        addLeadingRuleIfNeeded(ruleManager.rootRule, view: self)
        addFooterRuleIfNeeded(ruleManager.footerRule)
        ruleManager.rulebottomAnchor?.isActive = true

        // layout renders
        layoutRenders()
        // layout rules
        layoutRules()

        if !animations.isScrollAnimnationDone, animations.isScrollAnimation {
            animations.isScrollAnimnationDone = true
            animationScrollingProgressToPage(animations.scrollingAnimationProgressDuration,
                                             page: numberOfPages - 1) {}
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
        print("updateLayout for render points bounded at frame \(frame) Cache: \(ignoreLayoutCache ? "NoCache" : "").")
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
}

extension OMScrollableChart {
    // Just when load
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        setupView()
        clearsContextBeforeDrawing = true
    }
    
    /// touchSelectedLayer
    /// - Parameters:
    ///   - render: render description
    ///   - selectedLayer: selectedLayer description
    ///   - location: location description
    private func touchSelectedLayer(in render: BaseRender,
                                    selectedLayer: ShapeLayer?,
                                    at location: CGPoint)
    {
        guard let layer = selectedLayer else {
            print("nil selected layer, touching it.")
            return
        }
        if animations.animateLineSelection {
            // Animate the points, show on touch and fade out when keeo untouched
            if let path = polylinePath {
                let anim = animateLineSelection(with: layer, path)
                print(anim)
            }
        }
        selectRenderLayerWithAnimation(render, layer, location)
    }
    
    /// printLayersInSections
    private func printLayersInSections() {
        // all renders
        print("[layer] section")
        for render in engine.renders.reversed() {
            render.layers.forEach {
                print(
                    """
                            ($0.name ?? "") \(render.sectionIndex(withPoint: $0.position, numberOfSections: numberOfSections))
                    """)
            }
        }
    }
    
    /// analyzeCurrentSelection
    /// - Parameters:
    ///   - selectedLayerInCurrentRender: layer
    ///   - hitTestShapeLayer: hit test layer
    ///   - render: at render
    ///   - location: witgh location
    /// - Returns: Bool
    func performCurrentSelection(_ renderLayer: GradientShapeLayer?,
                                 _ hitTestShapeLayer: CALayer,
                                 _ render: ReversedCollection<[BaseRender]>.Element,
                                 _ location: CGPoint) -> Bool
    {
        if let selectedLayer = renderLayer {
            touchSelectedLayer(in: render,
                               selectedLayer:
                               selectedLayer,
                               at: location)
            return true
        } else {
            touchSelectedLayer(in: render,
                               selectedLayer: hitTestShapeLayer as? ShapeLayer,
                               at: location)
            return true
        }
        return false
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let location: CGPoint = locationFromTouchInContentView(touches)
        // updateLineSelectionLayer(location)
        let hitTestLayer = hitTestAsLayer(location)
        if let hitTestShapeLayer = hitTestLayer {
            print("Hit layer \(hitTestShapeLayer.name)")
            engine_touchesBegan(location,
                                hitTestShapeLayer: hitTestShapeLayer)
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let location: CGPoint = locationFromTouchInContentView(touches)
        engine_touchesMoved(location)
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let location: CGPoint = locationFromTouchInContentView(touches)
        engine_touchesEnded(location)
    }
    
    /// engine_touchesBegan
    /// - Parameters:
    ///   - location: CGPoint
    ///   - hitTestShapeLayer: CALayer?
    func engine_touchesBegan(_ location: CGPoint, hitTestShapeLayer: CALayer?) {
        var isSelected: Bool = false
        // printLayersInSections()
        
        // run the renders in reverse order
        for render in engine.renders.reversed() {
            // skip untouchable rennders. polyline layer for touch, its a one layer.
            guard render.chars == .touchable else { continue }
            // skip the hidden opacity renders
            let opacity = dataSource?.renderOpacity(chart: self, renderIndex: render.index)
            if let opacity = opacity {
                if opacity > minimunRenderOpacity {
                    // is the render visible
                    if let hitTestShapeLayer = hitTestShapeLayer {
                        // Get the point more near for locaton with this render
                        isSelected = performCurrentSelection(render.locationToLayer(location),
                                                             hitTestShapeLayer,
                                                             render,
                                                             location)
                    }
                } else {
                    print("Render index \(render.index) is hidden, layer ignored.")
                }
            } else {
                print("Render index \(render.index) is hidden, layer ignored.")
            }
        }
        
        if !isSelected {
            // test the layers
            if let _ = engine.renders[RenderIdent.polyline.rawValue].locationToLayer(location),
               let selectedLayer = engine.renders[RenderIdent.points.rawValue].locationToLayer(location)
            {
                let selectedLayerPoint = CGPoint(x: selectedLayer.position.x, y: selectedLayer.position.y)
                print("Location \(location) selectedLayerPoint \(selectedLayerPoint)")
                selectRenderLayerWithAnimation(engine.renders[RenderIdent.points.rawValue],
                                               selectedLayer,
                                               location,
                                               true)
            }
        }
    }

    func engine_touchesMoved(_ location: CGPoint, hitTestShapeLayer: CALayer? = nil) {
        // updateLineSelectionLayer(location)
        tooltip.moveTooltip(location)
    }

    func engine_touchesEnded(_ location: CGPoint) {
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
            print("layout is OK \(frame)")
        }
    }

    /// updateRendersOpacity
    private func updateRendersOpacity() {
        // Create the points from the discrete data using the renders
        print("Updating \(engine.allRendersLayers.count) renders layers opacity ")
        if engine.allRendersLayers.isEmpty == false {
            if let dataSource = dataSource {
                for render in engine.renders.reversed() {
                    print("Check if layers want opacity.")
                    let layerOpacityResult = render.layers.map {
                        dataSource.renderLayerOpacity(chart: self,
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
                                $1.opacity = Float(layerOpacityResult[$0] ?? Opacity.hide.rawValue)
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
//
//    // RGB color using all R, G, B values
//    func RGBColorForOffsetPercentage(percentage: CGFloat) -> UIColor {
//        // RGB 1, 0, 0 = red
//        let minColorRed = 1.0
//        let minColorGreen = 0.0
//        let minColorBlue = 0.0
//
//        // RGB 1, 0 = yellow
//        let maxColorRed = 1.0
//        let maxColorGreen = 1.0
//        let maxColorBlue = 0.0
//
//        let actualRed = (maxColorRed - minColorRed) * Double(percentage) + minColorRed
//        let actualGreen = (maxColorGreen - minColorGreen) * Double(percentage) + minColorGreen
//        let actualBlue = (maxColorBlue - minColorBlue) * Double(percentage) + minColorBlue
//
//        return UIColor(red: CGFloat(actualRed), green: CGFloat(actualGreen), blue: CGFloat(actualBlue), alpha: 1.0)
//    }
    
    // MARK: Scroll Delegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isTracking {
            // self.setNeedsDisplay()
        }
        ruleManager.ruleLeadingAnchor?.constant = contentOffset.x
//
//        let maximumHorizontalOffset = scrollView.contentSize.width - scrollView.frame.width
//        let currentHorizontalOffset = scrollView.contentOffset.x
//        let percentageHorizontalOffset = currentHorizontalOffset / maximumHorizontalOffset
//
//        // this just gets the percentage offset.
//        // 0,0 = no scroll
//        // 1,1 = maximum scroll
//
//        let percentageOffset = CGPoint(x: percentageHorizontalOffset,
//                                       y: scrollView.frame.height)
//        let section = RenderManager.segments.sectionIndex(withPoint: contentOffset,
//                                                          numberOfSections: numberOfSections)
//        let render = RenderManager.segments
//        render.layers.forEach {
//            if section == render.sectionIndex(withPoint: $0.position, numberOfSections: numberOfSections) {
//                print("percentageOffset: \(percentageOffset)")
//                let color = RGBColorForOffsetPercentage(percentage: percentageOffset.x)
////                $0.glowLayer(withColor: color,
////                             withEffect: .small)
//                let glass = GlassLayer()
//                glass.anchorPoint = $0.anchorPoint
//                glass.strokeColor = UIColor.black.cgColor
//                glass.path = $0.path
////                $0.backgroundColor = color.cgColor
//                $0.addSublayer(glass)
//            }
//        }
//
//            let interColor = colorBetween(col1: colors[currPage],
//                                          col2: colors[nextPage],
//                                          percent: percent)
            
//            _ = layer?.applyGradient(of: interColor.makeGradient(), atAngle: 450)
    }

//
//        // calculates intermediate color, percent should in between 0.0 - 1.0
//        func colorBetween(col1: UIColor, col2: UIColor, percent: CGFloat) -> UIColor {
//            let c1 = CIColor(color: col1)
//            let c2 = CIColor(color: col2)
//
//            let alpha = (c2.alpha - c1.alpha) * percent + c1.alpha
//            let red = (c2.red - c1.red) * percent + c1.red
//            let blue = (c2.blue - c1.blue) * percent + c1.blue
//            let green = (c2.green - c1.green) * percent + c1.green
//
//            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
//        }
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {}
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        // self.layoutIfNeeded()
    }
}
