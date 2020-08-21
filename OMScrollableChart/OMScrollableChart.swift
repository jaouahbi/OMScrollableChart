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

extension UIColor {
    @nonobjc class var paleGrey: UIColor {
          return UIColor(red: 247.0 / 255.0, green: 247.0 / 255.0, blue: 250.0 / 255.0, alpha: 1.0)
      }
    @nonobjc class var greyishBlue: UIColor {
        return UIColor(red: 89.0 / 255.0, green: 135.0 / 255.0, blue: 164.0 / 255.0, alpha: 1.0)
    }
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
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer {
            CATransaction.commit()
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
protocol PointsGenerator {
    func makePoints(data: [Float], size: CGSize) -> [CGPoint]
    func updateRangeLimits(_ data: [Float])
    var pointEdgeInset: UIEdgeInsets {get}
    var maximumValue: Float {get}
    var minimumValue: Float {get}
    var pointsInsetTop: CGFloat  {get}
    var pointsInsetBottom: CGFloat  {get}
    /// Round  maximun valuer to
    var roundMaxValueTo: Float  {get}
    /// Round  minimun value to
    var roundMinValueTo: Float {get}
    var roundMarkValueTo: Float  {get}
    var staticMinimum: Float?  {get}
    var staticMaximum: Float?  {get}
    var maximunMaximizatorFactor: Float  {get}
    var minimunMaximizatorFactor: Float  {get}
    var range: Float  {get}
    var hScale: CGFloat  {get}
    var isLimitsDirty: Bool {get set}
}
// Default values.
extension PointsGenerator {
    var hScale: CGFloat  {return 1.0}
    var pointsInsetTop: CGFloat  { return 20}
    var pointsInsetBottom: CGFloat  {return 20}
    var staticMinimum: Float?  {return nil }
    var staticMaximum: Float?  {return nil }
    /// Round  minimun/maximun value to
    var roundMaxValueTo: Float {return 10000 }
    var roundMinValueTo: Float {return 1000 }
    var roundMarkValueTo: Float {return 10000 }
    var maximunMaximizatorFactor: Float  {return 1.0}
    var minimunMaximizatorFactor: Float  {return 1.0}
    var range: Float {
        return maximumValue - minimumValue
    }
}
// MRKE: - DiscretePointsGenerator -
class DiscretePointsGenerator: PointsGenerator {
    var pointEdgeInset: UIEdgeInsets = .zero
    var isLimitsDirty: Bool = true
    var maximumValue: Float = 0
    var minimumValue: Float = 0
    func updateRangeLimits(_ data: [Float]) {
        // Normalize values in array (i.e. scale to 0-1)...
        var min: Float = 0
        if let minimum = staticMinimum {
            min = minimum
        } else {
            vDSP_minv(data, 1, &min, vDSP_Length(data.count))
        }
        minimumValue = min.roundToNearestValue(value: roundMinValueTo) * maximunMaximizatorFactor
        var max: Float = 0
        if let maximum = staticMaximum {
            max = maximum
        } else {
            vDSP_maxv(data, 1, &max, vDSP_Length(data.count))
        }
        maximumValue = max.roundToNearestValue(value: roundMaxValueTo) * minimunMaximizatorFactor
        isLimitsDirty = false
    }
    func makePoints(data: [Float], size: CGSize) -> [CGPoint] {
        // claculate the size
        let newSize = CGSize(width: size.width,
                             height: size.height - (pointsInsetBottom + pointsInsetTop))
        var scale = 1 / self.range
        var minusMin = -minimumValue
        var scaled = [Float](repeating: 0, count: data.count)
        //        for (n = 0; n < N; ++n)
        //           scaled[n] = (A[n] + B[n]) * C;
        vDSP_vasm(data, 1, &minusMin, 0, &scale, &scaled, 1, vDSP_Length(data.count))
        let xScale = newSize.width / CGFloat(data.count)
        return scaled.enumerated().map {
            return CGPoint(x: xScale * hScale * CGFloat($0.offset),
                           y: (newSize.height * CGFloat(1.0 - ($0.element.isFinite ? $0.element : 0))) + pointsInsetTop)
        }
    }
}
protocol ChartProtocol {
    associatedtype ChartData
    var discreteData: [ChartData?] {get set}
    func updateDataSourceData() -> Bool
}
protocol OMScrollableChartDataSource: class {
    func dataPoints(chart: OMScrollableChart, renderIndex: Int, section: Int) -> [Float]
    func numberOfPages(chart: OMScrollableChart) -> CGFloat
    func dataLayers(_ render: Int, points: [CGPoint]) -> [OMGradientShapeClipLayer]
    func footerSectionsText(chart: OMScrollableChart) -> [String]?
    func dataPointTootipText(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, section: Int) -> String? 
    func dataOfRender(chart: OMScrollableChart, renderIndex: Int) -> OMScrollableChart.RenderData
    func dataSectionForIndex(chart: OMScrollableChart, dataIndex: Int, section: Int) -> String? 
    func numberOfSectionsPerPage(chart: OMScrollableChart) -> Int
    func isRenderLayersVisible(chart: OMScrollableChart, renderIndex: Int) -> Bool
    func animateLayers(chart: OMScrollableChart, renderIndex: Int, layerIndex: Int ,layer: CAShapeLayer)
}
protocol OMScrollableChartRenderableProtocol: class {
    var numberOfRenders: Int {get}
}


extension OMScrollableChartRenderableProtocol {
    var numberOfRenders: Int {
           return 2
       }
}
@objcMembers
class OMScrollableChart: UIScrollView, UIScrollViewDelegate, ChartProtocol {
    private var pointsLayer: OMGradientShapeClipLayer =  OMGradientShapeClipLayer()
    var polylineLayer: OMGradientShapeClipLayer =  OMGradientShapeClipLayer()
    var dashLineLayers = [OMGradientShapeClipLayer]()
    var rootRule: ChartRuleProtocol?
    var footerRule: ChartRuleProtocol?
    var topRule: ChartRuleProtocol?
    var rules = [ChartRuleProtocol]() // todo
    weak var dataSource: OMScrollableChartDataSource?
    weak var renderSource: OMScrollableChartRenderableProtocol?
    // Content view
    lazy var contentView: UIView =  {
        let lazyContentView = UIView(frame: self.bounds)
        self.addSubview(lazyContentView)
        return lazyContentView
    }()
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
    public enum PolyLineInterpolation {
        case none
        case smoothed
        case cubicCurve
        case catmullRom(_ alpha: CGFloat)
        case hermite(_ alpha: CGFloat)
    }
    // MARK: - UIBezierPaths -
    var polylinePath: UIBezierPath? {
        guard let polylinePoints = polylinePoints else {
            return nil
        }
        switch polylineInterpolation {
        case .none:
            return UIBezierPath(points: polylinePoints, maxYPosition: 0)
        case .smoothed:
            return UIBezierPath(smoothedPoints: polylinePoints, maxYPosition: 0)
        case .cubicCurve:
            return  UIBezierPath(cubicCurvePoints: polylinePoints, maxYPosition: 0)
        case .catmullRom(_):
            return UIBezierPath(catmullRomPoints: polylinePoints, maxYPosition: 0, closed: false, alpha: 0.5)
        case .hermite(_):
            return UIBezierPath(hermitePoints: polylinePoints, maxYPosition: 0)
        }
    }
    /// Polyline Interpolation
    var polylineInterpolation: PolyLineInterpolation = .smoothed {
        didSet {
            updateLayout()
        }
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
    
    
    var isLimitsDirty: Bool = true
    
    /// Round  maximun valuer to
    var roundMaxValueTo: Float = 10000 {
        didSet {
            isLimitsDirty = true
        }
    }
    /// Round  minimun value to
    var roundMinValueTo: Float = 1000 {
        didSet {
            isLimitsDirty = true
        }
    }
    var roundMarkValueTo: Float = 100 {
        didSet {
            isLimitsDirty = true
        }
    }
    var minimum: Float? = 0 {
        didSet {
            isLimitsDirty = true
        }
    }
    var maximum: Float? = nil {
        didSet {
            isLimitsDirty = true
        }
    }
    var maximunMaximizatorFactor: Float = 1.0 {
        didSet {
            isLimitsDirty = true
        }
    }
    var minimunMaximizatorFactor: Float = 1.0 {
        didSet {
            isLimitsDirty = true
        }
        
    }
    var hScale: CGFloat = 1.0
    private(set) var maximumValue: Float = 0
    private(set) var minimumValue: Float = 0
    var pointsInsetTop: CGFloat    = 20
    var pointsInsetBottom: CGFloat = 40
    //    /// Round  maximun valuer to
    //    var roundMaxValueTo: Float = 10000
    //    /// Round  minimun value to
    //    var roundMinValueTo: Float = 1000
    //    var roundMarkValueTo: Float = 100
    //    var minimum: Float? = 0
    //    var maximum: Float? = nil
    //    var maximunMaximizatorFactor: Float = 1.0
    //    var minimunMaximizatorFactor: Float = 1.0
    var range: Float {
        return maximumValue - minimumValue
    }
    func updateRangeLimits(_ data: [Float]) {
        // Normalize values in array (i.e. scale to 0-1)...
        var min: Float = 0
        if let minimum = minimum {
            min = minimum
        } else {
            vDSP_minv(data, 1, &min, vDSP_Length(data.count))
        }
        minimumValue = min.roundToNearestValue(value: roundMinValueTo) * maximunMaximizatorFactor
        var max: Float = 0
        if let maximum = maximum {
            max = maximum
        } else {
            vDSP_maxv(data, 1, &max, vDSP_Length(data.count))
        }
        maximumValue = max.roundToNearestValue(value: roundMaxValueTo) * minimunMaximizatorFactor
        isLimitsDirty = false
    }
    func makePoints(data: [Float], size: CGSize) -> [CGPoint] {
        // claculate the size
        let newSize = CGSize(width: size.width,
                             height: size.height - (pointsInsetBottom + pointsInsetTop))
        var scale = 1 / self.range
        var minusMin = -minimumValue
        var scaled = [Float](repeating: 0, count: data.count)
        //        for (n = 0; n < N; ++n)
        //           scaled[n] = (A[n] + B[n]) * C;
        vDSP_vasm(data, 1, &minusMin, 0, &scale, &scaled, 1, vDSP_Length(data.count))
        let xScale = newSize.width / CGFloat(data.count)
        return scaled.enumerated().map {
            return CGPoint(x: xScale * hScale * CGFloat($0.offset),
                           y: (newSize.height * CGFloat(1.0 - ($0.element.isFinite ? $0.element : 0))) + pointsInsetTop)
        }
    }
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
    
    var dashPattern: [CGFloat] = [3, 6, 3, 6] {
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
    var footerViewHeight: CGFloat = 20
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
                                       height: self.contentSize.height)
        }
        self.updateLayout()
    }
    var renderLayers: [[OMGradientShapeClipLayer]] = []
    var pointsRender: [[CGPoint]] = []
    var dataPointsRender: [[Float]] = []
    
    var isDirtyDataSource: Bool = true
    func updateDataSourceData() -> Bool {
        if let dataSource = dataSource {
            if let render = self.renderSource, render.numberOfRenders > 0  {
                var dataPointsRenderBackup = [[Float]]()
                // get the layers.
                for index in 0..<render.numberOfRenders {
                    let dataPoints = dataSource.dataPoints(chart: self,
                                                           renderIndex: index,
                                                           section: 0)
                    if !dataPointsRender.contains(dataPoints) {
                        isDirtyDataSource = true
                    }
                    dataPointsRenderBackup.insert(dataPoints, at: index)
                }
                if isDirtyDataSource {
                    dataPointsRender.removeAll()
                    dataPointsRender.append(contentsOf: dataPointsRenderBackup)
                } else {
                    isDirtyDataSource = false
                }
            } else {
                // Only exist one render.
                let dataPoints = dataSource.dataPoints(chart: self,
                                                       renderIndex: 0,
                                                       section: 0)
                if !dataPointsRender.contains(dataPoints) {
                    isDirtyDataSource = true
                }
                if isDirtyDataSource {
                    dataPointsRender.removeAll()
                    dataPointsRender.insert(dataPoints, at: 0)
                } else {
                    isDirtyDataSource = false
                }
            }
            if !isDirtyDataSource {
                print("isDirtyData \(isDirtyDataSource)")
            }
            //let numberOfSections = dataSource.numberOfSections(chart: self)
            let oldNumberOfPages = numberOfPages
            let newNumberOfPages = dataSource.numberOfPages(chart: self)
            
            
            if let footerRule = self.footerRule as? OMScrollableChartRuleFooter {
                if let texts =  dataSource.footerSectionsText(chart: self) {
                    footerRule.footerSectionsText = texts
                }
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
    func addDashLineLayer(point: CGPoint,
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
    fileprivate func projectLineStrokeGradient(_ internalPoints: [CGPoint], _ ctx: CGContext, _ gradient: CGGradient) {
        ctx.saveGState()
        for index in 0..<internalPoints.count - 1  {
            var start: CGPoint = internalPoints[index]
            // The ending point of the axis, in the shading's target coordinate space.
            var end: CGPoint  = internalPoints[index+1]
            // Draw the gradient in the clipped region
            let hw = self.lineWidth * 0.5
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
    fileprivate func drawGradient( ctx: CGContext?,
                                   layer: CAShapeLayer,
                                   fadeFactor: CGFloat = 0.4)  {
        if  let ctx = ctx {
            let locations =  [0, fadeFactor, 1 - fadeFactor, 1]
            let gradient = CGGradient(colorsSpace: nil,
                                      colors: [UIColor.white.withAlphaComponent(0.1).cgColor,
                                               lineColor.cgColor,
                                               lineColor.withAlphaComponent(polylineGradientFadePercentage).cgColor ,
                                               UIColor.white.withAlphaComponent(0.8).cgColor] as CFArray,
                                      locations:locations )!
            // Clip to the path, stroke and enjoy.
            if let path = layer.path {
                lineColor.setStroke()
                let curPath = UIBezierPath(cgPath: path)
                curPath.lineWidth = lineWidth
                curPath.stroke()
                curPath.addClip()
                // if we are using the stroke, we offset the from and to points
                // by half the stroke width away from the center of the stroke.
                // Otherwise we tend to end up with fills that only cover half of the
                // because users set the start and end points based on the center
                // of the stroke.
                if let internalPoints = polylinePoints {
                    projectLineStrokeGradient(internalPoints, ctx, gradient)
                }
            }
        }
    }
    public typealias ChartData = (points: [CGPoint], data: [Float])
    enum RenderData {
        case discrete
        case averaged
        case approximation
        case linregress
    }
    
    internal var renderType: [RenderData] = []
    
    var linFunction: (slope: Float, intercept: Float)?
    
    
    enum ChartRenders: Int {
        case polyline = 0
        case points = 1
    }
    var polylinePoints: [CGPoint]?  {
        return pointsRender.count > 0 ? pointsRender[ChartRenders.polyline.rawValue] : nil
    }
    var polylineDataPoints: [Float]? {
        return  dataPointsRender.count > 0 ? dataPointsRender[ChartRenders.polyline.rawValue] : nil
    }
    var pointsPoints: [CGPoint]?  {
        return pointsRender.count > 0 ? pointsRender[ChartRenders.points.rawValue] : nil
    }
    var pointsDataPoints: [Float]? {
        return  dataPointsRender.count > 0 ? dataPointsRender[ChartRenders.points.rawValue] : nil
    }
    
    var averagedData: [ChartData?] = []
    var linregressData: [ChartData?] = []
    var discreteData:  [ChartData?] = []
    var approximationData:  [ChartData?] = []
    func makeAveragedPoints( data: [Float], size: CGSize) ->  ([CGPoint], [Float])? {
        if numberOfElementsToAverage != 0 {
            var result: Float = 0
            let positives = data.map{$0>0 ? $0: abs($0)}
            //            let negatives = data.filter{$0<0}
            //
            //            for ccc in negatives {
            //               let i = data.indexes(of: negatives)
            //            }
            
            let chunked = positives.chunked(into: numberOfElementsToAverage)
            let averagedData: [Float] = chunked.map {
                vDSP_meanv($0, 1, &result, vDSP_Length($0.count));
                return result
            }
            //let averagedData = groupAverage(positives, numberOfElements: positives.count)
            let points = makePoints(data: averagedData, size: size)
            return (points, averagedData)
        }
        return nil
    }
    func makeRawPoints( data: [Float], size: CGSize) ->  ([CGPoint], [Float])? {
        if isLimitsDirty {
            updateRangeLimits(data)
        }
        return (makePoints(data: data, size: size), data)
    }
    func makeApproximationPoints( data: ChartData, size: CGSize) ->  ([CGPoint], [Float])? {
        guard approximationTolerance != 0,
            data.data.count > 0,
            data.points.count > 0 else {
                return nil
        }
        let approximationPoints = OMSimplify.decimate(data.points,
                                                      tolerance: CGFloat(approximationTolerance))
        return (approximationPoints, data.data)
    }
    fileprivate func removeAllLayers() {
        self.renderLayers.forEach {
            $0.forEach({ (layer: CALayer) -> () in
                layer.removeFromSuperlayer()
            })}
        //self.polylineLayer.removeFromSuperlayer()
        self.renderType = []
        self.renderLayers = []
    }
    // MARK: - Tooltip -
    var tooltip: OMBubbleTextView = OMBubbleTextView()
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
    var estimatedTooltipFrame: CGRect {
        let ratio: CGFloat = (1.0 / 8.0) * 0.5
        let superHeight = self.superview?.frame.height ?? 1
        let estimatedTooltipHeight = superHeight * ratio
        return CGRect(x: 0,
                      y: 0,
                      width: 128,
                      height: estimatedTooltipHeight > 0 ? estimatedTooltipHeight : 37.0)
    }
    /// Setup it
    func setupTooltip() {
        tooltip.frame = estimatedTooltipFrame
        tooltip.alpha = tooltipAlpha
        tooltip.font = tooltipFont
        tooltip.textAlignment = .center
        tooltip.layer.cornerRadius = 6
        tooltip.layer.masksToBounds = true
        tooltip.backgroundColor = toolTipBackgroundColor
        tooltip.layer.borderColor = tooltipBorderColor
        tooltip.layer.borderWidth = tooltipBorderWidth
        // Shadow
        tooltip.layer.shadowColor   = UIColor.black.cgColor
        tooltip.layer.shadowOffset  = pointsLayersShadowOffset
        tooltip.layer.shadowOpacity = 0.7
        tooltip.layer.shadowRadius  = 3.0
        
        tooltip.isFlipped           = true
        contentView.addSubview(tooltip)
    }
    // MARK: - Layout Cache -
    // cache hashed frame + points
    var layoutCache = [String: Any]()
    var isLayoutCacheActive: Bool = true
    /// Update internal layout
    // swiftlint:disable cyclomatic_complexity
    /// layoutRenders
    /// - Parameters:
    ///   - numberOfRenders: numberOfRenders
    ///   - dataSource: OMScrollableChartDataSource
    func layoutRenders(_ numberOfRenders: Int, _ dataSource: OMScrollableChartDataSource) {
        // points and layers
        pointsRender.removeAll()
        renderLayers.removeAll()
        // data
        discreteData.removeAll()
        averagedData.removeAll()
        linregressData.removeAll()
        approximationData.removeAll()
        for renderIndex in 0..<numberOfRenders {
            guard dataPointsRender[renderIndex].count > 0 else {
                continue
            }
            // Get the render data (discrete / approx / averaged / regression)
            let dataOfRender = dataSource.dataOfRender(chart: self, renderIndex: renderIndex)
            renderLayers(renderIndex, renderAs: dataOfRender)
            //
            // Update the opacy
            //
            let opacity: Float = dataSource.isRenderLayersVisible(chart: self,
                                                                  renderIndex: renderIndex) ? 1.0 : 0
            self.renderLayers[renderIndex].forEach {
                $0.opacity = opacity
            }
        }
        // Insert the render layer
        let allRendersLayers = renderLayers.flatMap({$0}).enumerated()
        for (renderIndex, layer) in allRendersLayers {
            self.contentView.layer.insertSublayer(layer, at: UInt32(renderIndex))
        }
    }
    /// Update the chart layout
    /// - Parameter forceLayout: Bool
    fileprivate func updateLayout( forceLayout: Bool = false) {
        //GCLog.print("updateLayout for render points blounded at frame \(self.frame).", .trace)
        // If we need to force layout, we must ignore the layoput cache.
        if forceLayout == false {
            if isLayoutCacheActive {
                let flatPointsToRender = pointsRender.flatMap({$0})
                if flatPointsToRender.count > 0 {
                    let frameHash  = self.frame.hashValue
                    let pointsHash = flatPointsToRender.hashValue
                    let dictKey = "\(frameHash ^ pointsHash)"
                    if let item = layoutCache[dictKey] {
                        //GCLog.print("[LCACHE] cache hit \(dictKey) \(item)", .trace)
                        setNeedsDisplay()
                        return
                    }
                    //GCLog.print("[LCACHE] cache miss \(dictKey)")
                    layoutCache.updateValue(pointsRender,
                                            forKey: dictKey)
                }
            }
        }
        // Create the points from the discrete data using the renders
        if dataPointsRender.flatMap {$0}.count > 0 {
            removeAllLayers()
            
            addLeadingRuleIfNeeded(rootRule, view: self)
            addFooterRuleIfNeeded(footerRule)
            
            if let render = self.renderSource,
                let dataSource = dataSource, render.numberOfRenders > 0  {
                // layout renders
                layoutRenders(render.numberOfRenders , dataSource)
                // layout rules
                layoutRules()
                performDelayedAnimations()
            }
        }
    }
    lazy var delayedAnimations: DispatchWorkItem = {
        return DispatchWorkItem {
            if let render = self.renderSource,
                let dataSource = self.dataSource,
                render.numberOfRenders > 0,
                self.renderLayers.flatMap({$0}).count > 0 {
                CATransaction.begin()
                CATransaction.setAnimationDuration(10)
                // The 2 first renders has private animations, ignore it.
                for renderIndex in 2..<render.numberOfRenders  {
                    for (layerIndex, layer) in self.renderLayers[renderIndex].enumerated() {
                        if layer.opacity > 0 {
                            dataSource.animateLayers(chart: self,
                                                     renderIndex: renderIndex,
                                                     layerIndex: layerIndex,
                                                     layer: layer)
                            //                        let pausedTime = layer.timeOffset
                            //                        layer.speed = 1.0
                            //                        layer.timeOffset = 0.0
                            //                        layer.beginTime = 0.0
                            //                        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
                            //                        layer.beginTime = timeSincePause
                        }
                    }
                }
                CATransaction.commit()
            }
            //            // Prepare animations if neeed
            //            if self.animateDashLines {
            //                self.animateDashLinesPhase()
            //            }
            //            if self.animatePointLayers {
            //                self.animateOnSelectPoint(nil,
            //                                          renderIndex: 0)
            //            }
            //            if self.animatePolyLine {
            //                self.polylineLayer.strokeEnd = 0
            //            }
        }
    }()
    
    func cancelDelayedAnimations() {
        // optional: cancel task
        delayedAnimations.cancel()
    }
    
    func performDelayedAnimations() {
        let timeout: TimeInterval = 0.5
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeout,
                                      execute: delayedAnimations)
    }
    // swiftlint:enabled cyclomatic_complexity
    func willSelectPointLayer(_ layer: OMGradientShapeClipLayer, renderIndex: Int) {
    }
    func didSelectPointLayer(_ layer: OMGradientShapeClipLayer, renderIndex: Int) {
    }
    
    var oldFrame: CGRect = .zero
    
    func selectMostNearPoint( point: CGPoint, renderIndex: Int) {
        /// Select the last point if the render is not hidden.
        guard let lastPoint = locationToNearestLayer(point, renderIndex: renderIndex) else {
            return
        }
        selectPointLayer(lastPoint,
                         selectedPoint: point,
                         renderIndex: renderIndex)
    }
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
            //GCLog.print("hitTestLayer found \(hitTestLayer.name) \(hitTestLayer.position) \(location) \(String(describing: hitTestLayer.classForCoder))", .info)
        }
        
        var isSelected: Bool = false
        for renderIndex in 1..<renderLayers.count {
            // Get the point more near
            let selectedLayer = locationToNearestLayer(location,
                                                       renderIndex: renderIndex)
            if let selectedLayer = selectedLayer {
                if hitTestLayer == selectedLayer {
                    if animateLineSelection {
                        self.animateLineOnSelectionPoint()
                    }
                    //GCLog.print("selectedLayer found \(selectedLayer.name) \(selectedLayer.position) \(location) \(String(describing: selectedLayer.classForCoder))", .info)
                    
                    selectPointLayer(selectedLayer,
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
                selectPointLayer(selectedLayer,
                                 selectedPoint: location,
                                 animateFixLocation: true,
                                 renderIndex: 1)
            }
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?){
        super.touchesMoved(touches, with:event)
        let location: CGPoint = locationFromTouch(touches)
        //updateLineSelectionLayer(location)
        tooltip.moveTooltip(location)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches , with: event)
        let location: CGPoint = locationFromTouch(touches)
        tooltip.hideTooltip(location)
        animateRotationAndPerspective(layer: tooltip.layer)
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
    override func layoutSubviews() {
        self.backgroundColor = .clear
        super.layoutSubviews()
        if oldFrame != self.frame {
            if self.updateDataSourceData() {
                self.updateLayout(forceLayout: true)
            } else {
                //GCLog.print("layout is 1")
            }
        } else {
            //GCLog.print("The view frame was unchanged.", .trace)
        }
    }
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if let ctx = UIGraphicsGetCurrentContext() {
            if drawPolylineGradient {
                drawGradient(ctx: ctx,
                             layer: polylineLayer,
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
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
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
    func mean(_ lhs: [Float]) -> Float {
        var result: Float = 0
        vDSP_meanv(lhs, 1, &result, vDSP_Length(lhs.count))
        return result
        
    }
    func measq(_ lhs: [Float]) -> Float {
        var result: Float = 0
        vDSP_measqv(lhs, 1, &result, vDSP_Length(lhs.count))
        return result
        
    }
    public func linregress(_ lhs: [Float], _ rhs: [Float]) -> (slope: Float, intercept: Float) {
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
    
    func makeLinregressPoints(data: ChartData, size: CGSize, numberOfElements: Int) -> ChartData {
        let originalDataIndex: [Float] = data.points.enumerated().map { Float($0.offset) }
        //        let max = originalData.points.max(by: { $0.x < $1.x})!
        //        let distance = mean(originalDataX.enumerated().compactMap{
        //            if $0.offset > 0 {
        //                return originalDataX[$0.offset-1].distance(to: $0.element)
        //            }
        //            return nil
        //        })
        
        
        // let results = originalDataX//.enumerated().map{ return originalDataX.prefix($0.offset+1).reduce(.zero, +)}
        
        linFunction = linregress(originalDataIndex, data.data)
        
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
        let newPoints =  makePoints(data: newData, size: size)
        return (newPoints, newData)
    }
    func linregressDataForIndex(index: Float) -> Float {
        guard let linFunction = linFunction else { return 0 }
        return linFunction.slope * index + linFunction.intercept
    }
}

extension CGPoint: Hashable {
    //    func distance(point: CGPoint) -> Float {
    //        let dx = Float(x - point.x)
    //        let dy = Float(y - point.y)
    //        return sqrt((dx * dx) + (dy * dy))
    //    }
    public var hashValue: Int {
        // iOS Swift Game Development Cookbook
        // https://gist.github.com/FredrikSjoberg/ced4ad5103863ab95dc8b49bdfd99eb2
        return x.hashValue << 32 ^ y.hashValue
    }
}

func ==(lhs: CGPoint, rhs: CGPoint) -> Bool {
    return lhs.distanceFrom(rhs) < 0.000001 //CGPointEqualToPoint(lhs, rhs)
}

extension Array: Hashable where Iterator.Element: Hashable {
    public var hashValue: Int {
        return self.reduce(1, { $0.hashValue ^ $1.hashValue })
    }
}
extension CGRect: Hashable {
    public var hashValue: Int {
        return NSCoder.string(for: self).hashValue
    }
}
