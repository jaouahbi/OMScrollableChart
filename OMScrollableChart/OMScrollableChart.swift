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

import UIKit
import Accelerate
// swiftlint:disable file_length
// swiftlint:disable type_body_length


struct OMSCConfig {
    static let animationPointsClearOpacityKey: String = "animationPointsClearOpacityKey"

}
public extension CGPoint {
    
    enum CoordinateSide {
        case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left
    }
    
    static func unitCoordinate(_ side: CoordinateSide) -> CGPoint {
        switch side {
        case .topLeft:      return CGPoint(x: 0.0, y: 0.0)
        case .top:          return CGPoint(x: 0.5, y: 0.0)
        case .topRight:     return CGPoint(x: 1.0, y: 0.0)
        case .right:        return CGPoint(x: 0.0, y: 0.5)
        case .bottomRight:  return CGPoint(x: 1.0, y: 1.0)
        case .bottom:       return CGPoint(x: 0.5, y: 1.0)
        case .bottomLeft:   return CGPoint(x: 0.0, y: 1.0)
        case .left:         return CGPoint(x: 1.0, y: 0.5)
        }
    }
}

extension CATransaction {
    class func withDisabledActions<T>(_ body: () throws -> T) rethrows -> T {
        let actionsWereDisabled = CATransaction.disableActions()
        CATransaction.setDisableActions(true)
        defer {
            CATransaction.setDisableActions(actionsWereDisabled)
        }
        return try body()
    }
}

extension Array where Element: Equatable {
    func indexes(of element: Element) -> [Int] {
        return self.enumerated().filter({ element == $0.element }).map({ $0.offset })
    }
}
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

protocol ChartProtocol {
    associatedtype ChartData
    var discreteData: [ChartData?] {get set}
    func updateDataSourceData() -> Bool
}

struct AnimationTiming: Hashable {
    static func == (lhs: AnimationTiming, rhs: AnimationTiming) -> Bool {
        return lhs.repeatDuration == rhs.repeatDuration &&
            lhs.autoreverses == rhs.autoreverses &&
            lhs.beginTime == rhs.beginTime &&
            lhs.duration == rhs.duration &&
            lhs.speed == rhs.speed &&
            lhs.fillMode == rhs.fillMode &&
            lhs.repeatCount == rhs.repeatCount &&
            lhs.timeOffset == rhs.timeOffset
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(repeatDuration)
        hasher.combine(autoreverses )
        hasher.combine(beginTime)
        hasher.combine(duration)
        hasher.combine(timeOffset)
        hasher.combine(speed)
        hasher.combine(fillMode)
        hasher.combine(repeatCount)
    }
    
    static var noAnimation: AnimationTiming {
        return AnimationTiming()
    }
    static var oneShotAnimation: AnimationTiming {
        return AnimationTiming(beginTime: 0,
                               duration: 0,
                               speed: 1,
                               timeOffset: 0,
                               repeatCount: 1,
                               repeatDuration: 0,
                               autoreverses: false,
                               fillMode: .forwards)
    }
    static var infiniteAnimation: AnimationTiming {
        return AnimationTiming(beginTime: 0,
                               duration: 0,
                               speed: 1,
                               timeOffset: 0,
                               repeatCount: HUGE,
                               repeatDuration: 0,
                               autoreverses: false,
                               fillMode: .forwards)
    }
    
    /* The begin time of the object, in relation to its parent object, if
     * applicable. Defaults to 0. */
    
    var beginTime: CFTimeInterval = 0
    
    
    /* The basic duration of the object. Defaults to 0. */
    
    var duration: CFTimeInterval  = 0
    
    
    /* The rate of the layer. Used to scale parent time to local time, e.g.
     * if rate is 2, local time progresses twice as fast as parent time.
     * Defaults to 1. */
    
    var speed: Float = 1
    
    
    /* Additional offset in active local time. i.e. to convert from parent
     * time tp to active local time t: t = (tp - begin) * speed + offset.
     * One use of this is to "pause" a layer by setting `speed' to zero and
     * `offset' to a suitable value. Defaults to 0. */
    
    var timeOffset: CFTimeInterval = 0
    
    
    /* The repeat count of the object. May be fractional. Defaults to 0. */
    
    var repeatCount: Float  = 0
    
    
    /* The repeat duration of the object. Defaults to 0. */
    
    var repeatDuration: CFTimeInterval = 0
    
    
    /* When true, the object plays backwards after playing forwards. Defaults
     * to NO. */
    
    var autoreverses: Bool = false
    
    
    /* Defines how the timed object behaves outside its active duration.
     * Local time may be clamped to either end of the active duration, or
     * the element may be removed from the presentation. The legal values
     * are `backwards', `forwards', `both' and `removed'. Defaults to
     * `removed'. */
    
    var fillMode: CAMediaTimingFillMode = .removed
}

protocol OMScrollableChartDataSource: class {
    func dataPoints(chart: OMScrollableChart, renderIndex: Int, section: Int) -> [Float]
    func numberOfPages(chart: OMScrollableChart) -> CGFloat
    func dataLayers(chart: OMScrollableChart, renderIndex: Int, section: Int, points: [CGPoint]) -> [OMGradientShapeClipLayer]
    func footerSectionsText(chart: OMScrollableChart) -> [String]?
    func dataPointTootipText(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, section: Int) -> String? 
    func dataOfRender(chart: OMScrollableChart, renderIndex: Int) -> OMScrollableChart.RenderData
    func dataSectionForIndex(chart: OMScrollableChart, dataIndex: Int, section: Int) -> String? 
    func numberOfSectionsPerPage(chart: OMScrollableChart) -> Int
    func renderLayerOpacity(chart: OMScrollableChart, renderIndex: Int) -> CGFloat
    func queryAnimation(chart: OMScrollableChart, renderIndex: Int) -> AnimationTiming
    func animateLayers(chart: OMScrollableChart, renderIndex: Int, layerIndex: Int ,layer: OMGradientShapeClipLayer) -> CAAnimation?
    
    
}
protocol OMScrollableChartRenderableDelegateProtocol: class {
    func animationDidEnded(chart: OMScrollableChart,  renderIndex: Int, animation: CAAnimation)
    func didSelectDataIndex(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, layer: CALayer)
}
protocol OMScrollableChartRenderableProtocol: class {
    var numberOfRenders: Int {get}
}
extension OMScrollableChartRenderableProtocol {
    // Default renders, polyline and points
    var numberOfRenders: Int {
        return 2
    }
}
@objcMembers
class OMScrollableChart: UIScrollView, UIScrollViewDelegate, ChartProtocol, CAAnimationDelegate {
    private var pointsLayer: OMGradientShapeClipLayer =  OMGradientShapeClipLayer()
    var polylineLayer: OMGradientShapeClipLayer =  OMGradientShapeClipLayer()
    var dashLineLayers = [OMGradientShapeClipLayer]()
    var rootRule: ChartRuleProtocol?
    var footerRule: ChartRuleProtocol?
    var topRule: ChartRuleProtocol?
    var rules = [ChartRuleProtocol]() // todo
    weak var dataSource: OMScrollableChartDataSource?
    weak var renderSource: OMScrollableChartRenderableProtocol?
    weak var renderDelegate: OMScrollableChartRenderableDelegateProtocol?
    
    var isAnimatePointsClearOpacity: Bool = true
    var isAnimatePointsClearOpacityDone: Bool = false
    var rideAnim: CAAnimation? = nil
    var layerToRide: CALayer?
    var ridePath: Path?
    
    
    // Content view
    lazy var contentView: UIView =  {
        let lazyContentView = UIView(frame: self.bounds)
        self.addSubview(lazyContentView)
        return lazyContentView
    }()

    // MARK: - Tooltip -
    var tooltip: OMBubbleTextView = OMBubbleTextView()
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
    var toolTipBackgroundColor: UIColor = UIColor.clear {
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
    var scaledPointsGenerator =
        [ScaledPointsGenerator](repeating: DiscreteScaledPointsGenerator(), count: 10)
    // MARK: - Data Bounds -
    // For example: mouths : 6
    var numberOfSectionsPerPage: Int {
        return dataSource?.numberOfSectionsPerPage(chart: self) ?? 1
    }
    var numberOfSections: Int {         // Total
        return numberOfSectionsPerPage * Int(numberOfPages)
    }
    var sectionWidth: CGFloat {
        return self.contentSize.width/CGFloat(numberOfSections)
    }
    var numberOfPages: CGFloat = 1 {
        didSet {
            updateContentSize()
        }
    }
    // MARK: - Polyline -
    /// Polyline Interpolation
    var polylineInterpolation: PolyLineInterpolation = .catmullRom(0.5) {
        didSet {
            updateLayout(ignoreLayout: true) // force layout
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
    
    override func draw(_ layer: CALayer, in ctx: CGContext) {
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
    
    var numberOfElementsToAverage: Int = 3 {
        didSet {
            self.setNeedsLayout()
            self.setNeedsDisplay()
        }
    }
    // 1.0 -> 20.0
    var approximationTolerance: CGFloat = 1.0 {
        didSet {
            self.setNeedsLayout()
            self.setNeedsDisplay()
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
        return internalRulesMarks.sorted(by: {return !($0 > $1)})
    }
    var polylineGradientFadePercentage: CGFloat = 0.4
    var drawPolylineGradient: Bool =  true
    var lineColor = UIColor.greyishBlue
    var lineWidth: CGFloat = 1
    
    var dashPattern: [CGFloat] = [1, 2] {
        didSet {
            dashLineLayers.forEach({($0).lineDashPattern = dashPattern.map{NSNumber(value: Float($0))}})
        }
    }
    var dashLineWidth: CGFloat = 0.5 {
        didSet {
            dashLineLayers.forEach({$0.lineWidth = dashLineWidth})
        }
    }
    var dashLineColor = UIColor.lightGray.withAlphaComponent(0.8).cgColor {
        didSet {
            dashLineLayers.forEach({$0.strokeColor = dashLineColor})
        }
    }
    // MARK: - Footer -
    var decorationFooterRuleColor = UIColor.black {
        didSet {
            footerRule?.decorationColor = decorationFooterRuleColor
        }
    }
    // MARK: - Font color -
    var fontFooterRuleColor = UIColor.black {
        didSet {
            footerRule?.fontColor = fontFooterRuleColor
        }
    }
    var fontRootRuleColor = UIColor.black {
        didSet {
            rootRule?.fontColor = fontRootRuleColor
        }
    }
    var fontTopRuleColor = UIColor.black {
        didSet {
            topRule?.fontColor = fontTopRuleColor
        }
    }
    var footerRuleBackgroundColor = UIColor.black {
        didSet {
            topRule?.backgroundColor = footerRuleBackgroundColor
        }
    }
    var footerViewHeight: CGFloat = 30
    var topViewHeight: CGFloat = 20
    var ruleLeadingAnchor: NSLayoutConstraint?
    var ruletopAnchor: NSLayoutConstraint?
    var rulebottomAnchor: NSLayoutConstraint?
    var rulewidthAnchor: NSLayoutConstraint?
    var ruleFont = UIFont.systemFont(ofSize: 10, weight: .medium)
    var rulesPoints = [CGPoint]()
    var animatePolyLine = false
    var animateDashLines: Bool = false
    var animatePointLayers: Bool = false
    var animateLineSelection: Bool = false
    var pointsLayersShadowOffset = CGSize(width: 0, height: 0.5)
    var selectedColor = UIColor.red
    var selectedOpacy: Float = 1.0
    var unselectedOpacy: Float = 0
    var unselectedColor = UIColor.clear
    private var contentOffsetKOToken: NSKeyValueObservation?
    // MARK: -  register/unregister notifications and KO
    fileprivate func registerNotifications() {
        #if swift(>=4.2)
        let notificationName = UIDevice.orientationDidChangeNotification
        #else
        let notificationName = NSNotification.Name.UIDeviceOrientationDidChange
        #endif
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRotation),
                                               name: notificationName,
                                               object: nil)
        
        contentOffsetKOToken = self.observe(\.contentOffset) { [weak self] object, change in
            // the `[weak self]` is to avoid strong reference cycle; obviously,
            // if you don't reference `self` in the closure, then `[weak self]` is not needed
            //print("contentOffset is now \(object.contentOffset)")
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
    }
    // Unregister the ´orientationDidChangeNotification´ notification
    fileprivate func unregisterNotifications () {
        NotificationCenter.default.removeObserver(self)
    }
    deinit {
        unregisterNotifications()
        contentOffsetKOToken?.invalidate()
        contentOffsetKOToken = nil
    }
    // MARK: - handleRotation -
    @objc func handleRotation() {
        self.updateContentSize()
    }
    // Setup all the view/subviews
    func setupView() {
        self.registerNotifications()
        // Setup the UIScrollView
        self.delegate = self
        if #available(iOS 11, *) {
            self.contentInsetAdjustmentBehavior = .never
        }
        self.createSuplementaryRules()
        self.setupTooltip()
        
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
    fileprivate func updateContentSize() {
        self.layoutIfNeeded()
        let newValue = CGSize(width: self.bounds.width * numberOfPages, height: self.bounds.height)
        if self.contentSize != newValue {
            self.contentSize = newValue
            contentView.frame = CGRect(x: 0,
                                       y: 0,
                                       width: self.contentSize.width,
                                       height: self.contentSize.height - footerViewHeight)
        }
        self.updateLayout()
    }
    
    var drawableFrame: CGRect {
        return CGRect(origin: .zero, size: contentView.frame.size)
    }
    
    //
    //    var isDirtyDataSource: Bool = true
    //    func updateDataSourceData() -> Bool {
    //        if let dataSource = dataSource {
    //            if let render = self.renderSource, render.numberOfRenders > 0  {
    //                var dataPointsRenderNewDataPoints = [[Float]]()
    //                // get the layers.
    //                for index in 0..<render.numberOfRenders {
    //                    let dataPoints = dataSource.dataPoints(chart: self, renderIndex: index, section: 0)
    //                    if !dataPointsRender.contains(dataPoints) {
    //                        isDirtyDataSource = true
    //                    }
    //                    dataPointsRenderNewDataPoints.insert(dataPoints, at: index)
    //                }
    //                if isDirtyDataSource {
    //                    dataPointsRender.removeAll()
    //                    dataPointsRender.append(contentsOf: dataPointsRenderNewDataPoints)
    //                } else {
    //                    isDirtyDataSource = false
    //                }
    //            } else {
    //                // Only exist one render.
    //                let dataPoints = dataSource.dataPoints(chart: self,
    //                                                       renderIndex: 0,
    //                                                       section: 0)
    //                if !dataPointsRender.contains(dataPoints) {
    //                    isDirtyDataSource = true
    //                }
    //                if isDirtyDataSource {
    //                    dataPointsRender.removeAll()
    //                    dataPointsRender.insert(dataPoints, at: 0)
    //                } else {
    //                    isDirtyDataSource = false
    //                }
    //            }
    //            if !isDirtyDataSource {
    //                print("isDirtyData \(isDirtyDataSource)")
    //            }
    //            //let numberOfSections = dataSource.numberOfSections(chart: self)
    //
    //            if let footerRule = self.footerRule as? OMScrollableChartRuleFooter {
    //                if let texts =  dataSource.footerSectionsText(chart: self) {
    //                    if texts != footerRule.footerSectionsText {
    //                        footerRule.footerSectionsText = texts
    //                        print("footerSectionsTextChanged \(isDirtyDataSource)")
    //                    }
    //                }
    //            }
    //            let oldNumberOfPages = numberOfPages
    //            let newNumberOfPages = dataSource.numberOfPages(chart: self)
    //            if oldNumberOfPages != newNumberOfPages {
    //                print("numberOfPagesChanged \(isDirtyDataSource)")
    //                // _delegate.numberOfPagesChanged()
    //            }
    //            self.numberOfPages = newNumberOfPages
    //            return true
    //        }
    //        return false
    //    }
    //
    
    func queryDataPointsRender(_ dataSource: OMScrollableChartDataSource) -> [[Float]] {
        var dataPointsRenderNewDataPoints = [[Float]]()
        if let render = self.renderSource, render.numberOfRenders > 0  {
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
    
    func updateDataSourceData() -> Bool {
        if let dataSource = dataSource {
            // get the data points
            dataPointsRender = queryDataPointsRender(dataSource)
            
            if let footerRule = self.footerRule as? OMScrollableChartRuleFooter {
                if let texts =  dataSource.footerSectionsText(chart: self) {
                    if texts != footerRule.footerSectionsText {
                        footerRule.footerSectionsText = texts
                        // _delegate.footerSectionsTextChanged()
                        print("footerSectionsTextChanged()")
                    }
                }
            }
            let oldNumberOfPages = numberOfPages
            let newNumberOfPages = dataSource.numberOfPages(chart: self)
            if oldNumberOfPages != newNumberOfPages {
                //print("numberOfPagesChanged: \(oldNumberOfPages) -> \(newNumberOfPages)")
                // _delegate.numberOfPagesChanged()
            }
            self.numberOfPages = newNumberOfPages
            return true
        }
        return false
    }
    
    //    fileprivate func updatePolylineLayer(_ polylinePath: UIBezierPath) {
    //        //
    //        polylineLayer.path          = polylinePath.cgPath
    //        polylineLayer.fillColor     = UIColor.clear.cgColor
    //        polylineLayer.strokeColor   = self.lineColor.withAlphaComponent(0.8).cgColor
    //        polylineLayer.lineWidth     = self.lineWidth
    //        //
    //        polylineLayer.shadowColor   = UIColor.black.cgColor
    //        polylineLayer.shadowOffset  = CGSize(width: 0, height:  self.lineWidth * 2)
    //        polylineLayer.shadowOpacity = 0.5
    //        polylineLayer.shadowRadius  = 6.0
    //        //polylineLayer.isHidden = false
    //    }
    //    func updatePolylineLayerIfNeeded() {
    //        guard  let polylinePath = polylinePath else {
    //            return
    //        }
    //        updatePolylineLayer(polylinePath)
    //    }
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
                                      pattern: [NSNumber]? = nil) {
        let lineLayer = OMGradientShapeClipLayer()
        lineLayer.strokeColor = stroke?.cgColor ?? dashLineColor
        lineLayer.lineWidth   = lineWidth ?? dashLineWidth
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
    fileprivate func projectLineStrokeGradient(_ ctx: CGContext,
                                               gradient: CGGradient,
                                               internalPoints: [CGPoint],
                                               lineWidth: CGFloat) {
        ctx.saveGState()
        for index in 0..<internalPoints.count - 1  {
            var start: CGPoint = internalPoints[index]
            // The ending point of the axis, in the shading's target coordinate space.
            var end: CGPoint  = internalPoints[index+1]
            // Draw the gradient in the clipped region
            let hw = lineWidth * 0.5
            start  = end.projectLine(start, length: hw)
            end    = start.projectLine(end, length: -hw)
            ctx.scaleBy(x: self.bounds.size.width,
                        y: self.bounds.size.height )
            ctx.drawLinearGradient(gradient,
                                   start: start,
                                   end: end,
                                   options: [])
        }
        ctx.restoreGState()
    }
    fileprivate func strokeGradient( ctx: CGContext?,
                                     layer: CAShapeLayer,
                                     points: [CGPoint]?,
                                     color: UIColor,
                                     lineWidth: CGFloat,
                                     fadeFactor: CGFloat = 0.4)  {
        if  let ctx = ctx {
            let locations =  [0, fadeFactor, 1 - fadeFactor, 1]
            let gradient = CGGradient(colorsSpace: nil,
                                      colors: [UIColor.white.withAlphaComponent(0.1).cgColor,
                                               color.cgColor,
                                               color.withAlphaComponent(fadeFactor).cgColor ,
                                               UIColor.white.withAlphaComponent(0.8).cgColor] as CFArray,
                                      locations: locations )!
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
                    projectLineStrokeGradient( ctx, gradient: gradient, internalPoints: internalPoints, lineWidth: lineWidth)
                }
            }
        }
    }
    
    
    public typealias ChartData = (points: [CGPoint], data: [Float])
    
    enum RenderData {
        case discrete
        case averaged(Int)
        case approximation(CGFloat)
        case linregress(Int)
        func makePoints( data: [Float], for size: CGSize, generator: ScaledPointsGenerator) -> [CGPoint] {
            switch self {
            case .discrete:
                return generator.makePoints(data: data, size: size)
            case .averaged(let elementsToAverage):
                if elementsToAverage != 0 {
                    var result: Float = 0
                    let positives = data.map{$0>0 ? $0: abs($0)}
                    //            let negatives = data.filter{$0<0}
                    //
                    //            for negative in negatives {
                    //               let i = data.indexes(of: negatives)
                    //            }
                    
                    let chunked = positives.chunked(into: elementsToAverage)
                    let averagedData: [Float] = chunked.map {
                        vDSP_meanv($0, 1, &result, vDSP_Length($0.count));
                        return result
                    }
                    //let averagedData = groupAverage(positives, numberOfElements: positives.count)
                    return generator.makePoints(data: averagedData, size: size)
                }
            case .approximation(let tolerance):
                let points = generator.makePoints(data: data, size: size)
                guard tolerance != 0, points.count > 0 else {
                    return []
                }
                return  OMSimplify.decimate(points, tolerance: CGFloat(tolerance))
            case .linregress(let elements):
                let points = generator.makePoints(data: data, size: size)
                let originalDataIndex: [Float] = points.enumerated().map { Float($0.offset) }
                //        let max = originalData.points.max(by: { $0.x < $1.x})!
                //        let distance = mean(originalDataX.enumerated().compactMap{
                //            if $0.offset > 0 {
                //                return originalDataX[$0.offset-1].distance(to: $0.element)
                //            }
                //            return nil
                //        })
                
                
                // let results = originalDataX//.enumerated().map{ return originalDataX.prefix($0.offset+1).reduce(.zero, +)}
                
                let linFunction: (slope: Float, intercept: Float) = Stadistics.linregress(originalDataIndex, data)
                
                // var index = 0
                let result: [Float] = [Float].init(repeating: 0, count: elements)
                
                let resulLinregress = result.enumerated().map{
                    linFunction.slope * Float($0.offset) + linFunction.intercept }
                //        for item in result  {
                //            result[index] = dataForIndex(index:  Float(index))
                //            index += 1
                //        }
                //
                // add the new points
                let newData = data + resulLinregress
                return generator.makePoints(data: newData, size: size)
            }
            
            return []
        }
        
        var isAveraged: Bool {
            switch self {
            case .averaged(_):
               return true
            default:
                return false
            }
        }
        
    }

    
    var linFunction: (slope: Float, intercept: Float)?
    
    // MARK: Default renders
    enum Renders: Int {
        case polyline       = 0
        case points         = 1
        case selectedPoint  = 2
        case base           = 3  //  public renders base index
    }
    var coreGenerator: ScaledPointsGenerator? {
        return scaledPointsGenerator[Renders.polyline.rawValue]
    }
    // Polyline render index 0
    var polylinePoints: [CGPoint]?  {
        return pointsRender.count > 0 ? pointsRender[Renders.polyline.rawValue] : nil
    }
    var polylineDataPoints: [Float]? {
        return  dataPointsRender.count > 0 ? dataPointsRender[Renders.polyline.rawValue] : nil
    }
    // Polyline render index 1
    var pointsPoints: [CGPoint]?  {
        return pointsRender.count > 0 ? pointsRender[Renders.points.rawValue] : nil
    }
    var pointsDataPoints: [Float]? {
        return  dataPointsRender.count > 0 ? dataPointsRender[Renders.points.rawValue] : nil
    }
    // Selected Layers
    var renderSelectedPointsLayer: CAShapeLayer? {
        return  renderLayers.count > 0 ? renderLayers[Renders.selectedPoint.rawValue].first : nil
    }
    
    var renderLayers: [[OMGradientShapeClipLayer]] = []
    var pointsRender: [[CGPoint]] = []
    var dataPointsRender: [[Float]] = []
    internal var renderType: [RenderData] = []
    var averagedData: [ChartData?] = []
    var linregressData: [ChartData?] = []
    var discreteData:  [ChartData?] = []
    var approximationData:  [ChartData?] = []
    
    func minPoint( renderIndex: Int) -> CGPoint? {
        return  pointsRender[renderIndex].max(by: {$0.x > $1.x})
    }
    func maxPoint( renderIndex: Int) -> CGPoint? {
        return  pointsRender[renderIndex].max(by: {$0.x <= $1.x})
    }
    func makeAveragedPoints( data: [Float], size: CGSize, elementsToAverage: Int) -> [CGPoint]? {
        let generator  = scaledPointsGenerator[0]
        if elementsToAverage != 0 {
            var result: Float = 0
            let positives = data.map{$0>0 ? $0: abs($0)}
            //            let negatives = data.filter{$0<0}
            //
            //            for negative in negatives {
            //               let i = data.indexes(of: negatives)
            //            }
            
            let chunked = positives.chunked(into: elementsToAverage)
            let averagedData: [Float] = chunked.map {
                vDSP_meanv($0, 1, &result, vDSP_Length($0.count));
                return result
            }
            //let averagedData = groupAverage(positives, numberOfElements: positives.count)
            return generator.makePoints(data: averagedData, size: size)
        }
        return nil
    }
    func makeRawPoints(_ data: [Float], size: CGSize) -> [CGPoint] {
        let generator  = scaledPointsGenerator[0]
        generator.updateRangeLimits(data)
        return generator.makePoints(data: data, size: size)
    }
    func makeApproximationPoints( points: [CGPoint], tolerance: CGFloat) -> [CGPoint]? {
        guard tolerance != 0, points.count > 0 else {
            return nil
        }
        return  OMSimplify.decimate(points, tolerance: CGFloat(tolerance))
    }
    fileprivate func removeAllLayers() {
        self.renderLayers.forEach{$0.forEach{$0.removeFromSuperlayer()}}
        self.renderType = []
        self.renderLayers = []
    }
    // MARK: - Layout Cache -
    // cache hashed frame + points
    var layoutCache = [String: Any]()
    var isLayoutCacheActive: Bool = true
    
    var visibleLayers: [CAShapeLayer] {
        return allRendersLayers.filter({$0.opacity == 1.0})
    }
    var invisibleLayers: [CAShapeLayer] {
        return allRendersLayers.filter({$0.opacity == 0})
    }
    
    func performPathAnimation(_ layer: OMGradientShapeClipLayer,
                              _ animation: CAAnimation,
                              _ layerOpacity: CGFloat) {
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
    
    fileprivate func performPositionAnimation(_ layer: OMGradientShapeClipLayer,
                                              _ animation: CAAnimation,
                                              layerOpacity: CGFloat) {
        let anima = animationWithFadeGroup(layer,
                                           toValue: layerOpacity,
                                           animations: [animation])
        if layer.opacity == 0 {
            layer.add(anima, forKey: "renderPositionAnimationGroup", withCompletion: nil)
        } else {
            layer.add(animation, forKey: "renderPositionAnimation", withCompletion: nil)
        }
    }
    
    fileprivate func performOpacityAnimation(_ layer: OMGradientShapeClipLayer,
                                             _ animation: CAAnimation) {
        
        layer.add(animation, forKey: "renderOpacityAnimation", withCompletion: nil)
    }
    
    func updateRenderLayersOpacity( for renderIndex: Int, layerOpacity: CGFloat) {
        // Don't delay the opacity
        print(Renders.points.rawValue)
        if renderIndex == Renders.points.rawValue {
            return
        }
        renderLayers[renderIndex].enumerated().forEach { layerIndex, layer  in
            layer.opacity = Float(layerOpacity)
        }
    }
    
    var allPointsRender: [CGPoint] { return  pointsRender.flatMap{$0}}
    var allDataPointsRender: [Float] { return  dataPointsRender.flatMap{$0}}
    var allRendersLayers: [CAShapeLayer]  {  return renderLayers.flatMap({$0}) }
    func queryDataAndRegenerateRendersLayers(_ numberOfRenders: Int, _ dataSource: OMScrollableChartDataSource) {
        // points and layers
        pointsRender.removeAll()
        renderLayers.removeAll()
        // data
        discreteData.removeAll()
        averagedData.removeAll()
        linregressData.removeAll()
        approximationData.removeAll()
        // render layers
        for renderIndex in 0..<numberOfRenders {
            guard dataPointsRender[renderIndex].count > 0 else {
                continue
            }
            // Get the render data. ex: discrete / approx / averaged / regression ...
            let dataOfRender = dataSource.dataOfRender(chart: self,
                                                       renderIndex: renderIndex)
            renderLayers(renderIndex, renderAs: dataOfRender)
        }
        // add layers
        for (renderIndex, layer) in allRendersLayers.enumerated() {
            // Insert the render layers
            self.contentView.layer.insertSublayer(layer, at: UInt32(renderIndex))
        }
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
        queryDataAndRegenerateRendersLayers(numberOfRenders, dataSource)
        // update with animation
        for renderIndex in 0..<numberOfRenders {
            // Get the opacity
            let  layerOpacity = dataSource.renderLayerOpacity(chart: self,
                                                              renderIndex: renderIndex)
            updateRenderLayersOpacity(for: renderIndex, layerOpacity: layerOpacity)
            
            let timing = dataSource.queryAnimation(chart: self, renderIndex: renderIndex)
            if timing.repeatCount > 0 {
                print("Animating the render:\(renderIndex) layers.")
                animateRenderLayers(renderIndex,
                                    layerOpacity: layerOpacity)
           // } else {
           //     print("The render \(renderIndex) dont want animate its layers.")
            }
        }
    }
    
    fileprivate func scrollingProgressAnimatingToPage(_ duration: TimeInterval, page: Int) {
        let delay: TimeInterval = 0.5
        let preTimeOffset: TimeInterval = 1.0
        let duration: TimeInterval = duration + delay - preTimeOffset
        self.layoutIfNeeded()
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: .curveEaseInOut,
                       animations: {
                self.contentOffset.x = self.frame.size.width * CGFloat(1)
        }, completion: { completed in
            if self.isAnimatePointsClearOpacity &&
                !self.isAnimatePointsClearOpacityDone {
                self.animatePointsClearOpacity()
                self.isAnimatePointsClearOpacityDone = true
            }
        })
    }
    fileprivate func runRideProgress(layerToRide: CALayer?, renderIndex: Int, scrollAnimation: Bool = false) {
        if let anim = self.rideAnim {
            if let layerRide = layerToRide {
                CATransaction.withDisabledActions {
                    layerRide.transform = CATransform3DIdentity
                }
                if scrollAnimation {
                    scrollingProgressAnimatingToPage(anim.duration, page: 1)
                }
                layerRide.add(anim, forKey: "around", withCompletion: {  complete in
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
            if isAnimatePointsClearOpacity  &&
                !isAnimatePointsClearOpacityDone {
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
        renderLayers[renderIndex].enumerated().forEach { layerIndex, layer  in
            if let animation = dataSource?.animateLayers(chart: self,
                                                         renderIndex: renderIndex,
                                                         layerIndex: layerIndex,
                                                         layer: layer) {
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
    var cacheTrackingLayout: Int = 0
    var isCacheStable: Bool {
        return cacheTrackingLayout > 1
    }
    var isScrollAnimation: Bool = true
    var isScrollAnimnationDone: Bool = false
    let scrollingProgressDuration: TimeInterval = 1.2
    
    /// Update the chart layout
    /// - Parameter forceLayout: Bool
    fileprivate func updateLayout( ignoreLayout: Bool = false) {
        //GCLog.print("updateLayout for render points blounded at frame \(self.frame).", .trace)
        // If we need to force layout, we must ignore the layoput cache.
        if ignoreLayout == false {
            if isLayoutCacheActive {
                let flatPointsToRender = pointsRender.flatMap({$0})
                if flatPointsToRender.count > 0 {
                    let frameHash  = self.frame.hashValue
                    let pointsHash = flatPointsToRender.hashValue
                    let dictKey = "\(frameHash ^ pointsHash)"
                    if let item = layoutCache[dictKey] as? [[CGPoint]] {
                        //print("[LCACHE] cache hit \(dictKey) [PKJI]")
                        cacheTrackingLayout += 1
                        setNeedsDisplay()
                        return
                    }
                    //print("[LCACHE] cache miss \(dictKey) [PKJI]")
                    cacheTrackingLayout = 0
                    layoutCache.updateValue(pointsRender,
                                            forKey: dictKey)
                }
            }
        }
        // Create the points from the discrete data using the renders
        if allDataPointsRender.count > 0 {
            //print("\(CALayer.isAnimatingLayers) animations running")
            if CALayer.isAnimatingLayers <= 0 {
                //print("Regenerating the layer tree.")
                removeAllLayers()
                addLeadingRuleIfNeeded(rootRule, view: self)
                addFooterRuleIfNeeded(footerRule)
                if let render = self.renderSource,
                    let dataSource = dataSource, render.numberOfRenders > 0  {
                    // layout renders
                    layoutRenders(render.numberOfRenders , dataSource)
                    // layout rules
                    layoutRules()
                }
                
                if !isScrollAnimnationDone && isScrollAnimation {
                    isScrollAnimnationDone = true
         
                    scrollingProgressAnimatingToPage(scrollingProgressDuration, page: 1)
                } else {
                    // Only animate if the points if the render its visible.
                    if rendersIsVisible(renderIndex: Renders.points.rawValue) {
                        animatePointsClearOpacity()
                    }
                }
            }
        }
    }
    var oldFrame: CGRect = .zero
}


extension OMScrollableChart {
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        setupView()
        self.clearsContextBeforeDrawing = true
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let location: CGPoint = locationFromTouch(touches)
        //updateLineSelectionLayer(location)
        let hitTestLayer: CALayer? = hitTestAsLayer(location) as? CAShapeLayer
        if let hitTestLayer = hitTestLayer {
            var isSelected: Bool = false
            // skip polyline layer
            for renderIndex in 1..<renderLayers.count {
                // Get the point more near
                let selectedLayer = locationToNearestLayer(location,
                                                           renderIndex: renderIndex)
                if let selectedLayer = selectedLayer {
                    if hitTestLayer == selectedLayer {
                        if animateLineSelection,
                            let path = self.polylinePath {
                            let anim = self.animateLineSelection(selectedLayer, path)
                            print(anim)
                        }

                        selectRenderLayerWithAnimation(selectedLayer,
                                                       selectedPoint: location,
                                                       renderIndex: renderIndex)
                        isSelected = true
                    }
                }
            }
            //
            if !isSelected {
                // test the layers
                if let polylineLayer = locationToNearestLayer(location,
                                                              renderIndex: 0),
                    let selectedLayer = locationToNearestLayer(location,
                                                               renderIndex: 1) {
                    let point = CGPoint( x: selectedLayer.position.x,
                                         y: selectedLayer.position.y )
                    selectRenderLayerWithAnimation(selectedLayer,
                                                   selectedPoint: location,
                                                   animation: true,
                                                   renderIndex: 1)
                }
            }
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?){
        super.touchesMoved(touches, with: event)
        let location: CGPoint = locationFromTouch(touches)
        //updateLineSelectionLayer(location)
        tooltip.moveTooltip(location)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches , with: event)
        let location: CGPoint = locationFromTouch(touches)
        tooltip.hideTooltip(location)
    }
    override var contentOffset: CGPoint {
        get {
            return super.contentOffset
        }
        set(newValue) {
            if contentOffset != newValue {
                super.contentOffset = newValue
            }
        }
    }
    override var frame: CGRect {
        set(newValue) {
            super.frame = newValue
            oldFrame = newValue
            self.setNeedsLayout()
        }
        get { return super.frame }
    }
    fileprivate func layoutForFrame() {
        if self.updateDataSourceData() {
            self.updateLayout(ignoreLayout: true)
        } else {
            //GCLog.print("layout is 1")
        }
    }
    fileprivate func updateRendersOpacity() {
        // Create the points from the discrete data using the renders
        //print("[\(Date().description)] [RND] updating render layer opacity [PKJI]")
        if allDataPointsRender.count > 0 {
            if let render = self.renderSource,
                let dataSource = dataSource, render.numberOfRenders > 0  {
                for renderIndex in 0..<render.numberOfRenders {
                    let  layerOpacity = dataSource.renderLayerOpacity(chart: self,
                                                                      renderIndex: renderIndex)
                    // layout renders opacity
                    updateRenderLayersOpacity( for: renderIndex,
                                               layerOpacity: layerOpacity)
                }
            }
        }
        //print("[\(Date().description)] [RND] visibles \(visibleLayers.count) no visibles \(invisibleLayers.count) [PKJI]")
    }

    
    fileprivate func animatePointsClearOpacity( duration: TimeInterval = 4.0) {
        guard renderLayers.flatMap({$0}).count > 0 else {
            return
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        for layer in renderLayers[Renders.points.rawValue] {
            let anim = animationOpacity(layer,
                                        fromValue: CGFloat(layer.opacity),
                                        toValue: 0.0)
            layer.add(anim,
                      forKey: OMSCConfig.animationPointsClearOpacityKey)
        }
        CATransaction.commit()
    }

    override func layoutSubviews() {
        self.backgroundColor = .clear
        super.layoutSubviews()
        if oldFrame != self.frame {
            layoutForFrame()
        } else {
            updateRendersOpacity()
        }
    }
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if let ctx = UIGraphicsGetCurrentContext() {
            if drawPolylineGradient {
                strokeGradient(ctx: ctx,
                               layer: polylineLayer,
                               points: polylinePoints,
                               color: lineColor,
                               lineWidth: lineWidth,
                               fadeFactor: polylineGradientFadePercentage)
            } else {
                ctx.saveGState()
                // Clip to the path
                if let path = polylineLayer.path {
                    let pathToFill = UIBezierPath(cgPath: path)
                    self.lineColor.setFill()
                    pathToFill.fill()
                }
                ctx.restoreGState()
            }
        }
        // drawVerticalGridLines()
        // drawHorizalGridLines()
        // Specify a border (stroke) color.
        // UIColor.black.setStroke()
        // pathVertical.stroke()
        // pathHorizontal.stroke()
    }
    // MARK: Scroll Delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.isTracking {
            //self.setNeedsDisplay()
        }
        ruleLeadingAnchor?.constant = self.contentOffset.x
    }
    //  scrollViewDidEndDragging - The scroll view sends this message when
    //    the user’s finger touches up after dragging content.
    //    The decelerating property of UIScrollView controls deceleration.
    //
    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
    }
    //    scrollViewWillBeginDecelerating - The scroll view calls
    //    this method as the user’s finger touches up as it is
    //    moving during a scrolling operation; the scroll view will continue
    //    to move a short distance afterwards. The decelerating property of
    //    UIScrollView controls deceleration
    //
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        //self.layoutIfNeeded()
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didScrollingFinished(scrollView: scrollView)
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            //didEndDecelerating will be called for sure
            return
        } else {
            didScrollingFinished(scrollView: scrollView)
        }
    }
    func didScrollingFinished(scrollView: UIScrollView) {
        //GCLog.print("Scrolling \(String(describing: scrollView.classForCoder)) was Finished", .trace)
    }
}
// Regression
extension OMScrollableChart {
    
    func makeLinregressPoints(data: ChartData, size: CGSize, numberOfElements: Int, renderIndex: Int) -> ChartData {
        let originalDataIndex: [Float] = data.points.enumerated().map { Float($0.offset) }
        //        let max = originalData.points.max(by: { $0.x < $1.x})!
        //        let distance = mean(originalDataX.enumerated().compactMap{
        //            if $0.offset > 0 {
        //                return originalDataX[$0.offset-1].distance(to: $0.element)
        //            }
        //            return nil
        //        })
        
        
        // let results = originalDataX//.enumerated().map{ return originalDataX.prefix($0.offset+1).reduce(.zero, +)}
        
        linFunction = Stadistics.linregress(originalDataIndex, data.data)
        
        // var index = 0
        let result: [Float] = [Float].init(repeating: 0, count: numberOfElements)
        
        let resulLinregress = result.enumerated().map{ linregressDataForIndex(index: Float($0.offset))}
        //        for item in result  {
        //            result[index] = dataForIndex(index:  Float(index))
        //            index += 1
        //        }
        //
        // add the new points
        let newData = data.data + resulLinregress
        let generator  = scaledPointsGenerator[renderIndex]
        let newPoints =  generator.makePoints(data: newData, size: size)
        return (newPoints, newData)
    }
    func linregressDataForIndex(index: Float) -> Float {
        guard let linFunction = linFunction else { return 0 }
        return linFunction.slope * index + linFunction.intercept
    }
}

class Stadistics {
    
    class func mean(_ lhs: [Float]) -> Float {
        var result: Float = 0
        vDSP_meanv(lhs, 1, &result, vDSP_Length(lhs.count))
        return result
        
    }
    class func measq(_ lhs: [Float]) -> Float {
        var result: Float = 0
        vDSP_measqv(lhs, 1, &result, vDSP_Length(lhs.count))
        return result
        
    }
    class func linregress(_ lhs: [Float], _ rhs: [Float]) -> (slope: Float, intercept: Float) {
        precondition(lhs.count == rhs.count, "Vectors must have equal count")
        let meanx = mean(lhs)
        let meany = mean(rhs)
        var result: [Float] = [Float].init(repeating: 0, count: lhs.count)
        vDSP_vmul(lhs, 1, rhs, 1, &result, 1, vDSP_Length(lhs.count))
        
        let meanxy = mean(result)
        let meanxSqr = measq(lhs)
        
        let slope = (meanx * meany - meanxy) / (meanx * meanx - meanxSqr)
        let intercept = meany - slope * meanx
        return (slope, intercept)
    }
    
}
