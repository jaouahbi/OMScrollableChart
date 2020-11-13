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
import LibControl

// swiftlint:disable file_length
// swiftlint:disable type_body_length

public protocol OMScrollableChartRuleDelegate {
    func footerSectionsTextChanged(texts: [String])
    func numberOfPagesChanged(pages: Int)
    func contentSizeChanged(contentSize: CGSize)
    func frameChanged(frame: CGRect)
    func dataPointsChanged(dataPoints: [Float], for index: Int)
    func drawRootRuleText(in frame: CGRect, text: NSAttributedString)
    func renderDataTypeChanged(in dataOfRender:  OMScrollableChart.RenderType)
}

extension UIScrollView {
    func zoom(toPoint zoomPoint : CGPoint, scale : CGFloat, animated : Bool) {
        var scale = CGFloat.minimum(scale, maximumZoomScale)
        scale = CGFloat.maximum(scale, self.minimumZoomScale)
        
        var translatedZoomPoint : CGPoint = .zero
        translatedZoomPoint.x = zoomPoint.x + contentOffset.x
        translatedZoomPoint.y = zoomPoint.y + contentOffset.y
        
        let zoomFactor = 1.0 / zoomScale
        
        translatedZoomPoint.x *= zoomFactor
        translatedZoomPoint.y *= zoomFactor
        
        var destinationRect : CGRect = .zero
        destinationRect.size.width = frame.width / scale
        destinationRect.size.height = frame.height / scale
        destinationRect.origin.x = translatedZoomPoint.x - destinationRect.size.width * 0.5
        destinationRect.origin.y = translatedZoomPoint.y - destinationRect.size.height * 0.5
        
        if animated {
            UIView.animate(withDuration: 0.55, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.6, options: [.allowUserInteraction], animations: {
                self.zoom(to: destinationRect, animated: false)
            }, completion: {
                completed in
                if let delegate = self.delegate, delegate.responds(to: #selector(UIScrollViewDelegate.scrollViewDidEndZooming(_:with:atScale:))), let view = delegate.viewForZooming?(in: self) {
                    delegate.scrollViewDidEndZooming!(self, with: view, atScale: scale)
                }
            })
        } else {
            zoom(to: destinationRect, animated: false)
        }
    }
}

struct ScrollChartConfiguration {
    static let animationPointsOpacityKey: String = "animationPointsClearOpacityKey"
    
    static let maxNumberOfRenders: Int = 10

}

public protocol ChartProtocol {
    associatedtype ChartData
    var discreteData: [ChartData?] {get set}
    func updateDataSourceData() -> Bool
}

public enum AnimationTiming {
    case none
    case oneShot
    case infinite
}

public protocol OMScrollableChartDataSource: class {
    func dataPoints(chart: OMScrollableChart, renderIndex: Int, section: Int) -> [Float]
    func numberOfPages(chart: OMScrollableChart) -> CGFloat
    func dataLayers(chart: OMScrollableChart, renderIndex: Int, section: Int, points: [CGPoint]) -> [OMGradientShapeClipLayer]
    func footerSectionsText(chart: OMScrollableChart) -> [String]?
    func dataPointTootipText(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, section: Int) -> String? 
    func dataOfRender(chart: OMScrollableChart, renderIndex: Int) -> OMScrollableChart.RenderType
    func dataSectionForIndex(chart: OMScrollableChart, dataIndex: Int, section: Int) -> String? 
    func numberOfSectionsPerPage(chart: OMScrollableChart) -> Int
    func layerOpacity(chart: OMScrollableChart, renderIndex: Int, layer: OMGradientShapeClipLayer) -> CGFloat
    func renderOpacity(chart: OMScrollableChart, renderIndex: Int) -> CGFloat
    func queryAnimation(chart: OMScrollableChart, renderIndex: Int) -> AnimationTiming
    func animateLayers(chart: OMScrollableChart, renderIndex: Int, layerIndex: Int ,layer: OMGradientShapeClipLayer) -> CAAnimation?
    
    
}
public  protocol OMScrollableChartRenderableDelegateProtocol: class {
    func animationDidEnded(chart: OMScrollableChart,  renderIndex: Int, animation: CAAnimation)
    func didSelectDataIndex(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, layer: CALayer)
    func didSelectSection(chart: OMScrollableChart,
                                    renderIndex: Int,
                                    sectionIndex: Int, layer: CALayer)
    
    
}
public protocol OMScrollableChartRenderableProtocol: class {
    var numberOfRenders: Int {get}
}
public  extension OMScrollableChartRenderableProtocol {
    // Default renders, polyline and points
    var numberOfRenders: Int {
        return 3
    }
}

/** Maps values in the range 0...1 to 0...1 using an exponential curve. */
func curve(_ value: CGFloat, rate: CGFloat) -> CGFloat {
  precondition(rate > 0.0)
  precondition(value >= 0.0)
  guard value < 1.0 else { return 1.0 }
  return 1 - exp(rate + rate / (value - 1.0))
}

public class OMContainerView: UIView {
//  var shape: UIBezierPath?
//  override func draw(_ rect: CGRect) {
//    guard let shape = shape else { return }
//    // Draw successively smaller paths with a new color
//    let steps = Int(max(shape.bounds.maxX, shape.bounds.maxY))
//    let stepFactor = 1.0 / CGFloat(steps)
//    let shapeMid = CGPoint(x: shape.bounds.midX, y: shape.bounds.midY)
//
//    for i in 0..<steps {
//      let copy = UIBezierPath(cgPath: shape.cgPath)
//
//      // scale and center
//      let scale = CGFloat(steps - i) * stepFactor
//      copy.apply(CGAffineTransform(scaleX: scale, y: scale))
//      let copyMid = CGPoint(x: copy.bounds.midX, y: copy.bounds.midY)
//      copy.apply(CGAffineTransform(translationX: shapeMid.x - copyMid.x,
//                                   y: shapeMid.y - copyMid.y))
//
//      // generate color and set it as fill color
//      let colorScale = curve(CGFloat(i) * stepFactor, rate: 1.0)
//      UIColor(red: colorScale,
//              green: colorScale,
//              blue: 1.0,
//              alpha: 1.0).setFill()
//
//      // fill the shape
//      copy.stroke()
//    }
//  }
}


@objcMembers
public class OMScrollableChart: UIScrollView, UIScrollViewDelegate, ChartProtocol, CAAnimationDelegate {
    public enum Opacity: CGFloat {
        case hide = 0.0
        case show = 1.0
    }
    public var layersToStroke: [(OMGradientShapeClipLayer, [CGPoint])] = []
    private var pointsLayer: OMGradientShapeClipLayer =  OMGradientShapeClipLayer()
    var polylineLayer: OMGradientShapeClipLayer =  OMGradientShapeClipLayer()
    var dashLineLayers = [OMGradientShapeClipLayer]()
//    var rootRule: ChartRuleProtocol?
//    var footerRule: ChartRuleProtocol?
//    var topRule: ChartRuleProtocol?
//    var rules = [ChartRuleProtocol]() // todo
    var ruleManager: RuleManager = .init()
    public weak var dataSource: OMScrollableChartDataSource?
    public weak var renderSource: OMScrollableChartRenderableProtocol?
    public weak var renderDelegate: OMScrollableChartRenderableDelegateProtocol?
    var polylineGradientFadePercentage: CGFloat = 0.4
    var drawPolylineGradient: Bool =  true
    var lineColor = UIColor.greyishBlue
    public var lineWidth: CGFloat = 16
    var footerViewHeight: CGFloat = 30
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
    var isAnimatePointsClearOpacity: Bool = true
    var showTooltip: Bool = true
    var rideAnim: CAAnimation? = nil
    var layerToRide: CALayer?
    var ridePath: Path?
    
    // Content view
    public lazy var contentView: OMContainerView =  {
        let lazyContentView = OMContainerView(frame: self.bounds)
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
    public var toolTipBackgroundColor: UIColor = UIColor.clear {
        didSet {
            tooltip.backgroundColor = toolTipBackgroundColor
        }
    }
    public var tooltipFont = UIFont.systemFont(ofSize: 12, weight: .light) {
        didSet {
            tooltip.font = tooltipFont
        }
    }
    public var tooltipAlpha: CGFloat = 0 {
        didSet {
            tooltip.alpha = tooltipAlpha
        }
    }
//    public var scaledPointsGenerator =
//        [ScaledPointsGenerator](repeating: ScaledPointsGenerator([], size: .zero, insets: UIEdgeInsets(top: 0, left: 0,bottom: 0,right: 0)),
//                                count: ScrollChartConfiguration.maxNumberOfRenders)
    // MARK: - Data Bounds -
    // For example: mouths : 6
    public var numberOfSectionsPerPage: Int {
        return dataSource?.numberOfSectionsPerPage(chart: self) ?? 1
    }
    public var numberOfSections: Int {         // Total
        return numberOfSectionsPerPage * Int(numberOfPages)
    }
    public var sectionWidth: CGFloat {
        return self.contentSize.width/CGFloat(numberOfSections)
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
    
//    override  public func draw(_ layer: CALayer, in ctx: CGContext) {
//        super.draw(layer, in: ctx)
//        updateRendersOpacity()
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
    
    public var numberOfElementsToMean: CGFloat = 2 {
        didSet {
            forceLayoutReload()  // force layout
        }
    }
    // 1.0 -> 20.0
    public var approximationTolerance: CGFloat = 1.0 {
        didSet {
            forceLayoutReload()  // force layout
        }
    }
    // MARK: - Rules -
    public var numberOfRuleMarks: CGFloat = 1 {
        didSet {
            setNeedsLayout()
        }
    }
    internal var internalRulesMarks = [Float]()
    public var rulesMarks: [Float] {
        return internalRulesMarks.sorted(by: {return !($0 > $1)})
    }
   
    public var dashPattern: [CGFloat] = [2, 4] {
        didSet {
            dashLineLayers.forEach({($0).lineDashPattern = dashPattern.map{NSNumber(value: Float($0))}})
        }
    }
    public  var dashLineWidth: CGFloat = 2 {
        didSet {
            dashLineLayers.forEach({$0.lineWidth = dashLineWidth})
        }
    }
    public var dashLineColor = UIColor.lightGray.withAlphaComponent(0.8).cgColor {
        didSet {
            dashLineLayers.forEach({$0.strokeColor = dashLineColor})
        }
    }
    // MARK: - Footer -
    public var decorationFooterRuleColor = UIColor.black {
        didSet {
            ruleManager.footerRule?.decorationColor = decorationFooterRuleColor
        }
    }
    // MARK: - Font color -
    public var fontFooterRuleColor = UIColor.black {
        didSet {
            ruleManager.footerRule?.fontColor = fontFooterRuleColor
        }
    }
    public var fontRootRuleColor = UIColor.black {
        didSet {
            ruleManager.rootRule?.fontColor = fontRootRuleColor
        }
    }
    public var fontTopRuleColor = UIColor.black {
        didSet {
            ruleManager.topRule?.fontColor = fontTopRuleColor
        }
    }
    public var footerRuleBackgroundColor = UIColor.black {
        didSet {
            ruleManager.topRule?.backgroundColor = footerRuleBackgroundColor
        }
    }

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
    private func unregisterNotifications () {
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
    //    private func updateLineSelectionLayer(_ location: CGPoint) {
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
        self.layoutIfNeeded()
        let newValue = CGSize(width: self.bounds.size.width * numberOfPages, height: self.bounds.size.height)
        if self.contentSize != newValue {
            self.contentSize = newValue

            contentView.frame = CGRect(x: 0,
                                       y: 0,
                                       width: self.contentSize.width,
                                       height: self.contentSize.height - footerViewHeight)
            
            
            flowDelegate?.contentSizeChanged(contentSize: newValue)
            
           // scaledPointsGenerator.forEach {$0.size = contentView.bounds.size}
            
            print("ContentSize chaged frame for: \(self.contentView.bounds)")

            forceLayoutReload()
        }
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
    
    func queryDataSourceForRenderDataPoints(_ dataSource: OMScrollableChartDataSource) -> [[Float]] {
        var dataPointsRenderNewDataPoints = [[Float]]()
        if let render = self.renderSource, render.numberOfRenders > 0  {
            // get the layers.
            for index in 0..<render.numberOfRenders {
                let dataPoints = dataSource.dataPoints(chart: self,
                                                       renderIndex: index,
                                                       section: 0)
                let dataPointsChanged = renderDataPoints.first?.hashValue != dataPoints.hashValue
                if dataPointsChanged {
                    //scaledPointsGenerator[index].data = dataPoints
                    flowDelegate?.dataPointsChanged(dataPoints: dataPoints, for: index)
                }
       
                dataPointsRenderNewDataPoints.insert(dataPoints, at: index)
            }
        } else {
            // Only exist one render.
            let dataPoints = dataSource.dataPoints(chart: self,
                                                   renderIndex: 0,
                                                   section: 0)
            let dataPointsChanged = renderDataPoints.first?.hashValue != dataPoints.hashValue
            if dataPointsChanged {
                //scaledPointsGenerator.first?.data = dataPoints
                flowDelegate?.dataPointsChanged(dataPoints: dataPoints, for: 0)
            }
            dataPointsRenderNewDataPoints.insert(dataPoints, at: 0)
        }
        return dataPointsRenderNewDataPoints
    }
    
    public class OMScrollableChartRuleFlow: OMScrollableChartRuleDelegate {
        public func renderDataTypeChanged(in dataOfRender: OMScrollableChart.RenderType) {
            print("renderDataTypeChanged", dataOfRender)
        }
        
        public func drawRootRuleText(in frame: CGRect, text: NSAttributedString) {
            print("drawRootRuleText", frame, text)
        }
        
        public func footerSectionsTextChanged(texts: [String]) {
            print("footerSectionsTextChanged", texts)
        }
        
        public func numberOfPagesChanged(pages: Int) {
            print("numberOfPagesChanged", pages)
        }
        
        public func contentSizeChanged(contentSize: CGSize) {
            print("contentSizeChanged", contentSize)
        }
        
        public func frameChanged(frame: CGRect) {
            print("frameChanged", frame)
        }
        
        public func dataPointsChanged(dataPoints: [Float], for index: Int) {
            print("dataPointsChanged", index,  dataPoints)
        }
    }
    var flowDelegate: OMScrollableChartRuleDelegate? = OMScrollableChartRuleFlow()
    
    public func updateDataSourceData() -> Bool {
        if let dataSource = dataSource {
            // get the data points
            renderDataPoints = queryDataSourceForRenderDataPoints(dataSource)
            if let footerRule = ruleManager.footerRule as? OMScrollableChartRuleFooter {
                if let texts = dataSource.footerSectionsText(chart: self) {
                    if texts != footerRule.footerSectionsText {
                        footerRule.footerSectionsText = texts
                        flowDelegate?.footerSectionsTextChanged(texts: texts)
                    }
                }
            }
            let oldNumberOfPages = numberOfPages
            let newNumberOfPages = dataSource.numberOfPages(chart: self)
            if oldNumberOfPages != newNumberOfPages {
                //print("numberOfPagesChanged: \(oldNumberOfPages) -> \(newNumberOfPages)")
                self.numberOfPages = newNumberOfPages
                flowDelegate?.numberOfPagesChanged(pages: Int(newNumberOfPages))
                return true
            }
        }
        return false
    }
    
    //    private func updatePolylineLayer(_ polylinePath: UIBezierPath) {
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
    private func projectLineStrokeGradient(_ ctx: CGContext,
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
            ctx.scaleBy(x: contentView.bounds.size.width,
                        y: contentView.bounds.size.height )
            ctx.drawLinearGradient(gradient,
                                   start: start,
                                   end: end,
                                   options: [])
        }
        ctx.restoreGState()
    }
    private func strokeGradient( ctx: CGContext?,
                                     layer: CAShapeLayer,
                                     points: [CGPoint]?,
                                     color: UIColor,
                                     lineWidth: CGFloat,
                                     fadeFactor: CGFloat = 0.4)  {
        if  let ctx = ctx {
            let locations =  [0, fadeFactor, 1 - fadeFactor, 1]
            // Create the gradient
            let gradientStroke = CGGradient(colorsSpace: nil,
                                      colors: [UIColor.black.withAlphaComponent(0.1).cgColor,
                                               UIColor.tan.darker.cgColor,
                                               UIColor.tan.darker.withAlphaComponent(fadeFactor).cgColor ,
                                               UIColor.black.withAlphaComponent(0.8).cgColor] as CFArray,
                                      locations: locations )!
            
            let gradient = CGGradient(colorsSpace: nil,
                                      colors: [UIColor.black.withAlphaComponent(0.1).cgColor,
                                               color.cgColor,
                                               color.withAlphaComponent(fadeFactor).cgColor ,
                                               UIColor.black.withAlphaComponent(0.8).cgColor] as CFArray,
                                      locations: locations )!
            // Clip to the path, stroke and enjoy.
            if let path = layer.path {
                
                // stroke 1
                ctx.setLineWidth(lineWidth)
                ctx.saveGState()
                ctx.addPath(path)
                ctx.replacePathWithStrokedPath()
                ctx.clip()
                // if we are using the stroke, we offset the from and to points
                // by half the stroke width away from the center of the stroke.
                // Otherwise we tend to end up with fills that only cover half of the
                // because users set the start and end points based on the center
                // of the stroke.
                guard let internalPoints = points else {
                    return
                }
                
                projectLineStrokeGradient( ctx,
                                       gradient: gradientStroke,
                                        internalPoints: internalPoints,
                                           lineWidth: lineWidth)
                
                ctx.addPath(path)
                ctx.clip()
                ctx.drawLinearGradient(gradient,
                                       start: internalPoints.last!,
                                       end: internalPoints.first!,
                                       options: [.drawsAfterEndLocation,.drawsBeforeStartLocation])
                ctx.restoreGState()
            }
        }
    }

    public typealias ChartData = (points: [CGPoint], data: [Float])
    
    public enum RenderType: Equatable{
        case discrete
        case mean(CGFloat)
        case approximation(CGFloat)
        case linregress(Int)
//        func makePoints( data: [Float], for size: CGSize, generator: ScaledPointsGenerator) -> [CGPoint] {
//            switch self {
//            case .discrete:
//                return generator.makePoints(data: data, size: size)
//            case .mean(let elementsToMean):
//                if elementsToMean != 0 {
//                    var result: Float = 0
//                    let positives = data.map{$0>0 ? $0: abs($0)}
//                    //            let negatives = data.filter{$0<0}
//                    //
//                    //            for negative in negatives {
//                    //               let i = data.indexes(of: negatives)
//                    //            }
//
//                    let chunked = positives.chunked(into: elementsToMean)
//                    let meanData: [Float] = chunked.map {
//                        vDSP_meanv($0, 1, &result, vDSP_Length($0.count));
//                        return result
//                    }
//                    //let meanData = groupAverage(positives, numberOfElements: positives.count)
//                    return generator.makePoints(data: meanData, size: size)
//                }
//            case .approximation(let tolerance):
//                let points = generator.makePoints(data: data, size: size)
//                guard tolerance != 0, points.isEmpty == false else {
//                    return []
//                }
//                return  OMSimplify.simplifyDouglasPeuckerDecimate(points, tolerance: CGFloat(tolerance))
//            case .linregress(let elements):
//                let points = generator.makePoints(data: data, size: size)
//                let originalDataIndex: [Float] = points.enumerated().map { Float($0.offset) }
//                //        let max = originalData.points.max(by: { $0.x < $1.x})!
//                //        let distance = mean(originalDataX.enumerated().compactMap{
//                //            if $0.offset > 0 {
//                //                return originalDataX[$0.offset-1].distance(to: $0.element)
//                //            }
//                //            return nil
//                //        })
//
//
//                // let results = originalDataX//.enumerated().map{ return originalDataX.prefix($0.offset+1).reduce(.zero, +)}
//
//                let linFunction: (slope: Float, intercept: Float) = Stadistics.linregress(originalDataIndex, data)
//
//                // var index = 0
//                let result: [Float] = [Float].init(repeating: 0, count: elements)
//
//                let resulLinregress = result.enumerated().map{
//                    linFunction.slope * Float($0.offset) + linFunction.intercept }
//                //        for item in result  {
//                //            result[index] = dataForIndex(index:  Float(index))
//                //            index += 1
//                //        }
//                //
//                // add the new points
//                let newData = data + resulLinregress
//                return generator.makePoints(data: newData, size: size)
//            }
//
//            return []
//        }
//
//        var isMean: Bool {
//            switch self {
//            case .mean(_):
//               return true
//            default:
//                return false
//            }
//        }
    }

    
    var linFunction: (slope: Float, intercept: Float)?
    
    // MARK: Default renders
    public  enum Renders: Int {
        case polyline       = 0
        case points         = 1
        case selectedPoint   = 2
        case base           = 3  //  public renders base index
    }
    // Polyline render index 0
    var polylinePoints: [CGPoint]?  {
        return pointsRender.isEmpty == false ? pointsRender[Renders.polyline.rawValue] : nil
    }
    var polylineDataPoints: [Float]? {
        return renderDataPoints.isEmpty == false ? renderDataPoints[Renders.polyline.rawValue] : nil
    }
    // Polyline render index 1
    var pointsPoints: [CGPoint]?  {
        return pointsRender.isEmpty == false ? pointsRender[Renders.points.rawValue] : nil
    }
    var pointsDataPoints: [Float]? {
        return renderDataPoints.isEmpty == false ? renderDataPoints[Renders.points.rawValue] : nil
    }
    // Selected Layers
    public var renderSelectedPointsLayer: CAShapeLayer? {
        return renderLayers.isEmpty == false ? renderLayers[Renders.selectedPoint.rawValue].first : nil
    }
    
    public var renderLayers: [[OMGradientShapeClipLayer]] = []
    public var pointsRender: [[CGPoint]] = []
    public var renderDataPoints: [[Float]] = []
    internal var renderType: [RenderType] = []
    public  var meanData: [ChartData?] = []
    public var linregressData: [ChartData?] = []
    public var discreteData:  [ChartData?] = []
    public var approximationData:  [ChartData?] = []
    
    
    func relation(with type: RenderType, renderIndex: Int) -> CGFloat {
        var total: Int = 0
        switch type {
        case .discrete:
            total = discreteData[renderIndex]?.data.count ?? 0
        case .mean(_):
            total = meanData[renderIndex]?.data.count ?? 0
        case .approximation(_):
            total = approximationData[renderIndex]?.data.count ?? 0
        case .linregress(_):
            total = linregressData[renderIndex]?.data.count ?? 0
        }
        return CGFloat(total) / CGFloat(numberOfSections)
    }

    
    var zoomIsActive: Bool = false
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
      var zoomRect = CGRect.zero
      zoomRect.size.height = contentView.frame.size.height / scale
      zoomRect.size.width  = contentView.frame.size.width  / scale
      let newCenter = contentView.convert(center, from: self)
      zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
      zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
      return zoomRect
    }
    
//    var oldFooterTransform3D: CATransform3D?
//    var oldRootTransform3D: CATransform3D?
    
    func minPoint(in renderIndex: Int) -> CGPoint? {
        return pointsRender[renderIndex].max(by: {$0.x > $1.x})
    }
    func maxPoint(in renderIndex: Int) -> CGPoint? {
        return pointsRender[renderIndex].max(by: {$0.x <= $1.x})
    }
    func makeAveragedPoints( data: [Float], size: CGSize, elementsToAverage: Int) -> [CGPoint]? {
        if elementsToAverage != 0 {
            var result: Float = 0
            let positives = data.map{$0>0 ? $0: abs($0)}
            //            let negatives = data.filter{$0<0}
            //
            //            for negative in negatives {
            //               let i = data.indexes(of: negatives)
            //            }
            
            let chunked = positives.chunked(into: elementsToAverage)
            let meanData: [Float] = chunked.map {
                vDSP_meanv($0, 1, &result, vDSP_Length($0.count));
                return result
            }
            //let meanData = groupAverage(positives, numberOfElements: positives.count)
            return ScaledPointsGenerator(meanData, size: size).makePoints()
        }
        return nil
    }
    // https://stackoverflow.com/questions/61879898/how-to-get-a-centerpoint-from-an-array-of-cgpoints
    func makeMeanPoints( data: [Float], size: CGSize, elementsToMean: CGFloat) -> [CGPoint] {
        var meanPoints: [CGPoint] = []
        let points = ScaledPointsGenerator(data, size: size).makePoints()
        guard elementsToMean > 0 else {
            return points
        }
        let chunked = points.chunked(into: max(1,Int(elementsToMean)))
        for item in chunked {
            meanPoints.append( item.mean() ?? .zero)
        }
        return meanPoints
    }
    func makeMeanCentroidPoints( data: [Float], size: CGSize, elementsToMeanCentroid: CGFloat) -> [CGPoint] {
        var meanPoints: [CGPoint] = []
        let points = ScaledPointsGenerator(data, size: size).makePoints()
        guard elementsToMeanCentroid > 0 else {
            return points
        }
        let chunked = points.chunked(into: max(1,Int(elementsToMeanCentroid)))
        for item in chunked {
            meanPoints.append( item.centroid() ?? .zero)
        }
        return meanPoints
    }
    func makeMean( data: [Float], size: CGSize, elementsToMean: CGFloat) -> ChartData {
        var meanData: [Float] = []
        let chunked = data.chunked(into: max(1,Int(elementsToMean)))
        for item in chunked {
            meanData.append( item.mean() )
        }
        let pts = ScaledPointsGenerator(meanData, size: contentView.bounds.size).makePoints()
        return (pts, meanData)
    }
    
    /// Make raw discrete points
    /// - Parameters:
    ///   - data: Data
    ///   - size: CGSize
    /// - Returns: Array of discrete CGPoint
    func makeRawPoints(_ data: [Float], size: CGSize) -> [CGPoint] {
        return ScaledPointsGenerator(data, size: contentView.bounds.size).makePoints()
    }
    
    public var approximationType: SimplifyType = .douglasPeuckerRadial {
        didSet {
            forceLayoutReload()
        }
    }
    
    internal var renderSourceNumberOfRenders: Int {
        if let render = self.renderSource {
           return  render.numberOfRenders
        }
        return 0
    }
    
    public enum SimplifyType {
        case none
        case douglasPeuckerRadial
        case douglasPeuckerDecimate
        case visvalingam
        case ramerDouglasPeucker
    }
    func makeApproximationPoints( points: [CGPoint], type: SimplifyType, tolerance: CGFloat) -> [CGPoint]? {
        guard tolerance != 0, points.isEmpty == false else {
            return nil
        }
        switch type {
        case .none:
            return nil
        case .douglasPeuckerRadial:
            return  OMSimplify.douglasPeuckerRadialSimplify(points, tolerance: CGFloat(tolerance), highestQuality: true)
        case .douglasPeuckerDecimate:
            return OMSimplify.douglasPeuckerDecimateSimplify(points, tolerance: tolerance )
        case .visvalingam:
            return OMSimplify.visvalingamSimplify(points, limit: tolerance * tolerance)
        case .ramerDouglasPeucker:
            return OMSimplify.ramerDouglasPeuckerSimplify(points, epsilon: Double(tolerance * tolerance))
        }
    }
    private func removeAllLayers() {
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
    
    private func performPositionAnimation(_ layer: OMGradientShapeClipLayer,
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
    
    private func performOpacityAnimation(_ layer: OMGradientShapeClipLayer,
                                             _ animation: CAAnimation) {
        
        layer.add(animation, forKey: "renderOpacityAnimation", withCompletion: nil)
    }
    /// updateRenderLayersOpacity
    /// - Parameters:
    ///   - renderIndex: index
    ///   - layerOpacity: CGFloat
    func updateRenderLayersOpacity( for renderIndex: Int, layerOpacity: CGFloat) {
        // Don't delay the opacity
        if renderLayers.isEmpty || renderIndex == Renders.points.rawValue {
            return
        }
        renderLayers[renderIndex].enumerated().forEach { layerIndex, layer  in
            layer.opacity = Float(layerOpacity)
        }
    }
    
    var allPointsRender: [CGPoint] { return  pointsRender.flatMap{$0}}
    var allDataPointsRender: [Float] { return  renderDataPoints.flatMap{$0}}
    var allRendersLayers: [CAShapeLayer]  {  return renderLayers.flatMap({$0}) }
    private func resetRenderData() {
        // points and layers
        pointsRender.removeAll()
        renderLayers.removeAll()
        // data
        discreteData.removeAll()
        meanData.removeAll()
        linregressData.removeAll()
        approximationData.removeAll()
        
        renderType.removeAll()
    }
    
    func queryDataAndRegenerateRendersLayers(_ numberOfRenders: Int, _ dataSource: OMScrollableChartDataSource) {
        resetRenderData()
        // Render layers
        for renderIndex in 0..<numberOfRenders {
            guard renderDataPoints[renderIndex].isEmpty == false else {
                print("skip \(renderIndex) for regenerate layers")
                continue
            }
            // Get the render data. ex: discrete / approx / averaged / regression for each render
            let dataOfRender = dataSource.dataOfRender(chart: self, renderIndex: renderIndex)
            // Do render layers
//            if renderType.count > renderIndex {
//                if !(renderType[renderIndex] == dataOfRender) {
                    flowDelegate?.renderDataTypeChanged(in: dataOfRender)
//                }
//            }
            renderLayers(renderIndex, renderAs: dataOfRender)
        }
        // Add layers
        for (renderIndex, layer) in allRendersLayers.enumerated() {
            // Insert the render layers
            self.contentView.layer.insertSublayer(layer, at: UInt32(renderIndex))
        }
    }
    
    /// rendersIsVisible
    /// - Parameter renderIndex: <#renderIndex description#>
    /// - Returns: <#description#>
    func rendersIsVisible(renderIndex: Int) -> Bool {
        if let dataSource = dataSource {
            return dataSource.renderOpacity(chart: self,
                                                 renderIndex: renderIndex) == Opacity.show.rawValue
        }
        return false
    }
    
    /// rendersLayerIsVisible
    /// - Parameters:
    ///   - renderIndex: <#renderIndex description#>
    ///   - layer: <#layer description#>
    /// - Returns: <#description#>
    func rendersLayerIsVisible(renderIndex: Int, layer: OMGradientShapeClipLayer) -> Bool {
        if let dataSource = dataSource {
            return dataSource.layerOpacity(chart: self,
                                           renderIndex: renderIndex,
                                           layer: layer) == Opacity.show.rawValue
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
            let layerOpacity = dataSource.renderOpacity(chart: self, renderIndex: renderIndex)
            // update it
            updateRenderLayersOpacity(for: renderIndex, layerOpacity: layerOpacity)
            let timing = dataSource.queryAnimation(chart: self, renderIndex: renderIndex)
            if timing == .oneShot ||
                timing == .infinite {
                print("Animating the render:\(renderIndex) layers.")
                animateRenderLayers(renderIndex, layerOpacity: layerOpacity)
            } else {
                print("The render \(renderIndex) dont want animate its layers.")
            }
        }
    }
    /// scrollingProgressAnimatingToPage
    /// - Parameters:
    ///   - duration: TimeInterval
    ///   - page: Int
    private func scrollingProgressAnimatingToPage(_ duration: TimeInterval, page: Int) {
        let delay: TimeInterval = 0.5
        let preTimeOffset: TimeInterval = 1.0
        let duration: TimeInterval = duration + delay - preTimeOffset
        let xPositionDisp = self.frame.size.width * CGFloat(page)
        self.layoutIfNeeded()
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: .curveEaseInOut,
                       animations: {
                        self.contentOffset.x = xPositionDisp
        }, completion: { completed in
            if self.isAnimatePointsClearOpacity {
                self.animateRenderPointsOpacity(to: 0.0)
            }
        })
    }
    /// Run Path Ride Progress
    /// - Parameters:
    ///   - layerToRide: layer
    ///   - renderIndex: index
    ///   - scrollAnimation: Bool
    private func runRideProgress(layerToRide: CALayer?, renderIndex: Int, scrollAnimation: Bool = false) {
        if let anim = self.rideAnim {
            if let layerRide = layerToRide {
                CATransaction.withDisabledActions {
                    layerRide.transform = CATransform3DIdentity
                }
                if scrollAnimation {
                    scrollingProgressAnimatingToPage(anim.duration, page: Int(self.numberOfPages) - 1)
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
    /// animationDidEnded
    /// - Parameters:
    ///   - renderIndex: Int
    ///   - animation: CAAnimation
    func animationDidEnded(renderIndex: Int, animation: CAAnimation) {
        let keyPath = animation.value(forKeyPath: "keyPath") as? String
        if let animationKF = animation as? CAKeyframeAnimation,
           animationKF.path != nil,
           keyPath == "position" {
            if isAnimatePointsClearOpacity {
                animateRenderPointsOpacity(to: 0.0)
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
    
    /// Perform the layout animations
    private func performAnimations() {
        if !isScrollAnimnationDone && isScrollAnimation {
            isScrollAnimnationDone = true
            let scrollToPage = Int(self.numberOfPages) - 1
            scrollingProgressAnimatingToPage(scrollingProgressDuration,
                                        page: scrollToPage)
        } else {
            // Only animate if the points if the render its visible.
            if rendersIsVisible(renderIndex: Renders.points.rawValue) {
                animateRenderPointsOpacity(to: 0.0)
            }
        }
    }
    /// Update the chart layout
    /// - Parameter forceLayout: Bool
    private func updateLayout( ignoreLayoutCache: Bool = false) {
        print("updateLayout for render points blounded at frame \(self.frame).")
        // If we need to force layout, we must ignore the layoput cache.
        if ignoreLayoutCache == false {
            if isLayoutCacheActive {
                let flatPointsToRender = pointsRender.flatMap({$0})
                if flatPointsToRender.isEmpty == false {
                    let frameHash  = self.frame.hashValue
                    let pointsHash = flatPointsToRender.hashValue
                    let dictKey = "\(frameHash ^ pointsHash)"
                    if let item = layoutCache[dictKey] as? [[CGPoint]] {
                        print("[LCACHE] cache hit \(dictKey) [\(item.count))]")
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
        if allDataPointsRender.isEmpty == false {
            //print("\(CALayer.isAnimatingLayers) animations running")
            if ignoreLayoutCache {
                print("Regenerating the layer tree. for: \(self.contentView.bounds) \(ignoreLayoutCache)")
                removeAllLayers()
                addLeadingRuleIfNeeded(ruleManager.rootRule, view: self)
                addFooterRuleIfNeeded(ruleManager.footerRule)
                rulebottomAnchor?.isActive = true
 
                if let render = self.renderSource,
                    let dataSource = dataSource, render.numberOfRenders > 0  {
                    // layout renders
                    layoutRenders(render.numberOfRenders, dataSource)
                    // layout rules
                    layoutRules()
                }
                // animate layers
                performAnimations()
            }
        }
    }
    var oldFrame: CGRect = .zero
}

extension OMScrollableChart {
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.clearsContextBeforeDrawing = true
        setupView()
    }
    
    func renderResolution(with type: RenderType, renderIndex: Int) -> CGFloat {
        var total: Int = 0
        switch type {
        case .discrete:
            total = discreteData[renderIndex]?.data.count ?? 0
        case .mean(_):
            total = meanData[renderIndex]?.data.count ?? 0
        case .approximation(_):
            total = approximationData[renderIndex]?.data.count ?? 0
        case .linregress(_):
            total = linregressData[renderIndex]?.data.count ?? 0
        }
        return CGFloat(total) / CGFloat(numberOfSections)
    }

    private func onHitTestLayer(at location: CGPoint, _ hitTestLayer: CALayer) {
        var isSelected: Bool = false
        // skip polyline layer, start in points
        for renderIndex in Renders.points.rawValue..<renderLayers.count {
            // Get the point more near
            let selectedLayerFromLoc = locationToLayer(renderIndex, location: location)
            if let selectedLayer = selectedLayerFromLoc {
                if hitTestLayer == selectedLayer ||
                    hitTestLayer.position == selectedLayer.position {
                    if isAnimateLineSelection {
//                        if let path = self.polylinePath {
                         // TODO
//                            let animatiom: CAAnimation? = self.animateLineSelection( with: selectedLayer, path)
//                            print(animatiom)
//                        }
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
            let polylineLayer = locationToLayer(Renders.polyline.rawValue,
                                                location: location,
                                                mostNearLayer: true)
            let pointsLayers = locationToLayer(Renders.points.rawValue,
                                               location: location,
                                               mostNearLayer: true)
            
            if let polylineLayerUnwarp = polylineLayer,
               let selectedLayer = pointsLayers {
                
                //let point = CGPoint( x: selectedLayer.position.x, y: selectedLayer.position.y )
                
                selectRenderLayerWithAnimation(selectedLayer,
                                               selectedPoint: location,
                                               animation: true,
                                               renderIndex: Renders.points.rawValue)
            }
        }
    }
    
    private func onTouchesBegan(_ touches: Set<UITouch>) {
        let location: CGPoint = locationFromTouchInContentView(touches)
        //updateLineSelectionLayer(location)
        let hitTestLayer: CALayer? = hitTestAsLayer(location) as? CAShapeLayer
        if let hitTestLayer = hitTestLayer {
            onHitTestLayer(at: location, hitTestLayer)
        }
    }
    override  public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        onTouchesBegan(touches)
    }
    fileprivate func onTouchesMoved(_ touches: Set<UITouch>) {
        let location: CGPoint = locationFromTouchInContentView(touches)
        //updateLineSelectionLayer(location)
        tooltip.moveTooltip(location)
    }
    override  public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?){
        super.touchesMoved(touches, with: event)
        onTouchesMoved(touches)
    }
    fileprivate func onTouchesEnded(_ touches: Set<UITouch>) {
        let location: CGPoint = locationFromTouchInContentView(touches)
        tooltip.hideTooltip(location)
    }
    override  public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches , with: event)
        onTouchesEnded(touches)
    }
    private func updateRendersOpacity() {
        // Create the points from the discrete data using the renders
        guard renderLayers.flatMap({$0}).isEmpty == false else {
            return
        }
            if let render = self.renderSource,
                let dataSource = dataSource, render.numberOfRenders > 0  {
                for renderIndex in 0..<render.numberOfRenders {
                    let opacity = dataSource.renderOpacity(chart: self, renderIndex: renderIndex)
                    if opacity == 1.0 {
                        // query the layers
                        updateRendersLayerOpacity()
                    } else {
                        // layout renders opacity
                        updateRenderLayersOpacity(for: renderIndex, layerOpacity: opacity)
                    }
                }
            }
        
    }
    private func updateRendersLayerOpacity() {
        guard renderLayers.flatMap({$0}).isEmpty == false else {
            return
        }
        if let render = self.renderSource, let dataSource = dataSource, render.numberOfRenders > 0  {
            for renderIndex in 0..<render.numberOfRenders {
                renderLayers[renderIndex].enumerated().forEach { layerIndex, layer  in
                    let opacity = dataSource.layerOpacity(chart: self, renderIndex: renderIndex, layer: layer)
                    // layout renders opacity
                    layer.opacity = Float(opacity)
                }
            }
        }
    }
    var renderPointsAllLayers: [OMGradientShapeClipLayer] {
        return renderLayers[Renders.points.rawValue]
    }
    /// Animate Points Opacity
    /// - Parameters:
    ///   - opacity: Opacity
    ///   - duration: TimeInterval
    private func animateRenderPointsOpacity( to opacity: CGFloat, duration: TimeInterval = 4.0) {
        guard renderLayers.flatMap({$0}).isEmpty == false else {
            return
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        for layer in self.renderPointsAllLayers {
            let anim = animationOpacity(layer, fromValue: CGFloat(layer.opacity), toValue: opacity)
            layer.add(anim,
                      forKey: ScrollChartConfiguration.animationPointsOpacityKey)
        }
        CATransaction.commit()
    }
    override  public var contentOffset: CGPoint {
        get {
            return super.contentOffset
        }
        set(newValue) {
            if contentOffset != newValue {
                super.contentOffset = newValue
            }
        }
    }
    override  public var frame: CGRect {
        set(newValue) {
            super.frame = newValue
            oldFrame = newValue
            self.setNeedsLayout()
        }
        get { return super.frame }
    }
    public func forceLayoutReload() { self.updateLayout(ignoreLayoutCache: true) }
    internal func layoutForFrame() {
        if self.updateDataSourceData() {
            self.forceLayoutReload()
        } else {
            print("layout is OK")
        }
    }
    override  public func layoutSubviews() {
        self.backgroundColor = .clear
        super.layoutSubviews()
        if oldFrame != self.frame {
            flowDelegate?.frameChanged(frame: frame)
            layoutForFrame()
            oldFrame = self.frame
        } else {
            updateRendersOpacity()
        }
    }
    

    override  public func draw(_ rect: CGRect) {
        //super.draw(rect)
//        if let ctx = UIGraphicsGetCurrentContext() {
//            if drawPolylineGradient {
//               for layer in layersToStroke {
//                   strokeGradient(ctx: ctx,
//                                  layer: layer.0,
//                                  points: layer.1,
//                                  color: lineColor.darker,
//                                  lineWidth: lineWidth,
//                                  fadeFactor: 0.8)
//               }
//
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
    }
    // MARK: Scroll Delegate
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.isTracking {
            self.setNeedsDisplay()
        }
        ruleLeadingAnchor?.constant = self.contentOffset.x
    }
    //  scrollViewDidEndDragging - The scroll view sends this message when
    //    the user’s finger touches up after dragging content.
    //    The decelerating property of UIScrollView controls deceleration.
    //
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
    }
    
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.contentView

    }
    //    scrollViewWillBeginDecelerating - The scroll view calls
    //    this method as the user’s finger touches up as it is
    //    moving during a scrolling operation; the scroll view will continue
    //    to move a short distance afterwards. The decelerating property of
    //    UIScrollView controls deceleration
    //
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        //self.layoutIfNeeded()
    }
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didScrollingFinished(scrollView: scrollView)
    }
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            //didEndDecelerating will be called for sure
            return
        } else {
            didScrollingFinished(scrollView: scrollView)
        }
    }
    public func didScrollingFinished(scrollView: UIScrollView) {
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
        
        linFunction = Array.linregress(originalDataIndex, data.data)
        
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
        let newPoints = ScaledPointsGenerator(newData, size: size).makePoints()
        return (newPoints, newData)
    }
    func linregressDataForIndex(index: Float) -> Float {
        guard let linFunction = linFunction else { return 0 }
        return linFunction.slope * index + linFunction.intercept
    }
}

public struct RuleManager {
    var rootRule: ChartRuleProtocol?
    var footerRule: ChartRuleProtocol?
    var topRule: ChartRuleProtocol?
    var rules = [ChartRuleProtocol]()
}

public protocol UpdateProtocol {
    func updateContentSize()
    func updateDataSourceData() -> Bool
    func updateRules()
    func updateNumberOfPages() -> Bool
    func updateRenderDataPoints()
    func updateRendersLayers()
}

