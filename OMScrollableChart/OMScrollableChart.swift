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

/*
 
 
 //        let newApproximationRatio = 1.0 / (scale / (maximumZoomScale - minimumZoomScale))
 //        self.approximationRatio = newApproximationRatio
 
 var pinchGesture = UIPinchGestureRecognizer()
 
 Use this code
 
 override func viewDidLoad() {
 super.viewDidLoad()
 
 self.textview1.userInteractionEnabled = true
 self.textview1.multipleTouchEnabled = true
 
 self.pinchGesture = UIPinchGestureRecognizer(target: self, action:#selector(pinchRecognized(_:)))
 self.textview1.addGestureRecognizer(self.pinchGesture)
 
 // Do any additional setup after loading the view.
 }
 
 @IBAction func pinchRecognized(pinch: UIPinchGestureRecognizer) {
 let fontSize = self.textview1.font!.pointSize*(pinch.scale)/2
 if fontSize > 12 && fontSize < 32{
 textview1.font = UIFont(name: self.textview1.font!.fontName, size:fontSize)
 }
 }
 */

class OMTooltip: UILabel {
    
    var tooltipMoveAnimationDuration: TimeInterval = 0.2
    var tooltipShowAnimationDuration: TimeInterval = 0.5
    var tooltipHideAnimationDuration: TimeInterval = 4.0
    
    override func sizeThatFits( _ size: CGSize) -> CGSize {
        let result = super.sizeThatFits(size)
        return CGSize(width: result.width + 30,
                      height: result.height + 5)
    }
    
    func setText(_ name: String?) {
        text = name
        sizeToFit()
    }
    func show(_ position : CGPoint) {
        
        
        UIView.animate(withDuration: tooltipShowAnimationDuration, delay: 0.1, options: [ .curveEaseOut], animations: {
            self.alpha  = 1.0
            self.move(position)
        }, completion: { finished in
            
        })
    }
    
    
    func move(_ location: CGPoint) {
        UIView.animate(withDuration: self.tooltipMoveAnimationDuration) {
            self.frame  = CGRect(x: location.x,
                                 y: location.y,
                                 width: self.frame.width,
                                 height: self.frame.height)
        }
    }
    
    func hide(_ location: CGPoint) {
        UIView.animate(withDuration: tooltipHideAnimationDuration) {
            self.alpha = 0
        }
    }
    
    
}
class OMPointLayer: CAShapeLayer {
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    var center: CGPoint {
        return CGPoint(x: bounds.width/2, y: bounds.height/2)
    }
    
    var radius: CGFloat {
        return (bounds.width + bounds.height)/2
    }
    
    var colors: [UIColor] = [UIColor.clear, UIColor.clear] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var locations: [CGFloat] = [0.0, 1.0]
    var cgColors: [CGColor] {
        return colors.map({ (color) -> CGColor in
            return color.cgColor
        })
    }
    
    override init() {
        super.init()
        needsDisplayOnBoundsChange = true
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init()
    }
    
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        ctx.saveGState()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors as CFArray, locations: locations) else {
            return
        }
        let endRadius = sqrt(pow(frame.width/2, 2) + pow(frame.height/2, 2))
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0.0, endCenter: center, endRadius: endRadius, options: CGGradientDrawingOptions(rawValue: 0))
    }
}

extension Array where Element: Comparable {
    var indexOfMax: Index? {
        guard var maxValue = self.first else { return nil }
        var maxIndex = 0
        
        for (index, value) in self.enumerated() {
            if value > maxValue {
                maxValue = value
                maxIndex = index
            }
        }
        
        return maxIndex
    }
    var indexOfMin: Index? {
        guard var maxValue = self.first else { return nil }
        var maxIndex = 0
        
        for (index, value) in self.enumerated() {
            if value < maxValue {
                maxValue = value
                maxIndex = index
            }
        }
        
        return maxIndex
    }
}

extension Float {
    func roundToNearestValue(value: Float) -> Float {
        let remainder = truncatingRemainder(dividingBy: value)
        let shouldRoundUp = remainder >= value/2 ? true : false
        let multiple = floor(self / value)
        let returnValue = !shouldRoundUp ? value * multiple : value * multiple + value
        return returnValue
    }
}

protocol ChartProtocol {
    associatedtype ChartData
    var originalData: ChartData? {get set}
    func updateData() -> Bool
}

protocol OMScrollableChartDataSource: class {
    func dataPoints(chart: OMScrollableChart, section: Int) -> [Float]
    func numberOfPages(chart: OMScrollableChart) -> CGFloat
    // func numberOfSections(chart: OMScrollableChart) -> Int
}

//
//class FadeScrollView: UIScrollView, UIScrollViewDelegate {
//
//    let fadePercentage: CGFloat = 0.2
//    let gradientLayer = CAGradientLayer()
//    let transparentColor = UIColor.clear.cgColor
//    let opaqueColor = UIColor.black.cgColor
//
//    var topOpacity: CGColor {
//        let scrollViewHeight = frame.size.height
//        let scrollContentSizeHeight = contentSize.height
//        let scrollOffset = contentOffset.y
//
//        let alpha:CGFloat = (scrollViewHeight >= scrollContentSizeHeight || scrollOffset <= 0) ? 1 : 0
//
//        let color = UIColor(white: 0, alpha: alpha)
//        return color.cgColor
//    }
//
//    var bottomOpacity: CGColor {
//        let scrollViewHeight = frame.size.height
//        let scrollContentSizeHeight = contentSize.height
//        let scrollOffset = contentOffset.y
//
//        let alpha:CGFloat = (scrollViewHeight >= scrollContentSizeHeight || scrollOffset + scrollViewHeight >= scrollContentSizeHeight) ? 1 : 0
//
//        let color = UIColor(white: 0, alpha: alpha)
//        return color.cgColor
//    }
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//
//        self.delegate = self
//        let maskLayer = CALayer()
//        maskLayer.frame = self.bounds
//
//        gradientLayer.frame = CGRect(x: self.bounds.origin.x, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
//        gradientLayer.colors = [topOpacity, opaqueColor, opaqueColor, bottomOpacity]
//        gradientLayer.locations = [0, NSNumber(floatLiteral: fadePercentage), NSNumber(floatLiteral: 1 - fadePercentage), 1]
//        maskLayer.addSublayer(gradientLayer)
//
//        self.layer.mask = maskLayer
//    }
//
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        gradientLayer.colors = [topOpacity, opaqueColor, opaqueColor, bottomOpacity]
//    }
//
//}

//https://gist.github.com/pixeldock/f1c3b2bf0f7fe48d412c09fcb2705bf1

extension Array {
    func takeElements(_ numberOfElements: Int, startAt: Int = 0) -> Array {
        var numberOfElementsToGet = numberOfElements
        if numberOfElementsToGet > count - startAt {
            numberOfElementsToGet = count - startAt
        }
        let from = Array(self[startAt..<count])
        return Array(from[0..<numberOfElementsToGet])
    }
}


class OMScrollableChart: UIScrollView, UIScrollViewDelegate, ChartProtocol {
    
    
    public enum PolyLineInterpolation {
        case none
        case smoothed
        case cubicCurve
        case catmullRom(_ alpha: CGFloat)
        case hermite(_ alpha: CGFloat)
    }
    
    public enum PolyLineSimplyfication {
        case none
        case approximation(_ number: Int)
        case averaged(_ groupby: Int)
        
    }
    var simply: PolyLineSimplyfication = .none
    
    private var pointCircleLayers = [OMPointLayer]()
    
    // MARK: - UIBezierPaths -
    private var linePathDashPoints: UIBezierPath? {
        guard let internalPoints = internalPoints else {
            return nil
        }
        let linePathDashPoints = UIBezierPath(points: internalPoints, maxYPosition: self.frame.maxY)
        return linePathDashPoints
    }
    private  var linePathPoints: UIBezierPath? {
        guard let internalPoints = internalPoints else {
            return nil
        }
        let linePathPoints = UIBezierPath(pointPoints: internalPoints, pointSize: 6)
        return linePathPoints
    }
    
    //var approximationLineColor:  UIColor = .brown
    
    var currentPath: UIBezierPath? {
        guard let internalPoints = internalPoints else {
            return nil
        }
        switch polylineInterpolation {
        case .none:
            return UIBezierPath(points: internalPoints, maxYPosition: self.frame.maxY)
        case .smoothed:
            return UIBezierPath(smoothedPoints: internalPoints,
                                maxYPosition: self.frame.maxY)
        case .cubicCurve:
            return  UIBezierPath(cubicCurvePoints: internalPoints, maxYPosition: self.frame.maxY)
        case .catmullRom(_):
            return UIBezierPath(catmullRomPoints: internalPoints, maxYPosition: self.frame.maxY, closed: false, alpha: 0.5)
        case .hermite(_):
            return UIBezierPath(hermitePoints: internalPoints, maxYPosition: self.frame.maxY)
        }
    }
    
    private  var pointsLayer: CAShapeLayer =  CAShapeLayer()
    private  var currentLayer: CAShapeLayer =  CAShapeLayer()
    private var linePathDashPointsLayer: CAShapeLayer = CAShapeLayer()
    
    // TODO: If the size of the discrete points dont change
    func updateLayersIfNeeded() {
        
        guard let linePathPoints = linePathPoints,
            let currentPath = currentPath,
            let linePathDashPoints = linePathDashPoints else {
                return
        }
        
        pointsLayer.path = linePathPoints.cgPath
        pointsLayer.fillColor = UIColor.gray.cgColor
        pointsLayer.strokeColor = self.lineColor.withAlphaComponent(0.8).cgColor
        pointsLayer.lineWidth = self.lineWidth
        
        pointsLayer.shadowColor = UIColor.black.cgColor
        pointsLayer.shadowOffset = CGSize(width: 0, height: self.lineWidth * 2)
        pointsLayer.shadowOpacity = 0.5
        pointsLayer.shadowRadius  = 6.0
        pointsLayer.frame = CGRect(x: 0,y: 0, width: self.contentSize.width, height: self.frame.height)
        
        pointsLayer.isHidden = showPoints
        
        linePathDashPointsLayer.path = linePathDashPoints.cgPath
        linePathDashPointsLayer.lineDashPattern = dashPattern as [NSNumber]
        linePathDashPointsLayer.fillColor = nil
        linePathDashPointsLayer.strokeColor = dashLineColor
        linePathDashPointsLayer.lineWidth = dashLineWidth
        linePathDashPointsLayer.frame = CGRect(x: 0,y: 0, width: self.contentSize.width, height: self.frame.height)
        linePathDashPointsLayer.isHidden = true
        
        currentLayer.path = currentPath.cgPath
        currentLayer.fillColor = UIColor.clear.cgColor
        currentLayer.strokeColor = self.lineColor.withAlphaComponent(0.8).cgColor
        currentLayer.lineWidth = self.lineWidth
        
        currentLayer.shadowColor = UIColor.black.cgColor
        currentLayer.shadowOffset = CGSize(width: 0, height:  self.lineWidth * 2)
        currentLayer.shadowOpacity = 0.5
        currentLayer.shadowRadius = 6.0
        currentLayer.isHidden = true
        
    }
    
    var dashLineLayers = [CAShapeLayer]()
    //    private var pathVertical = UIBezierPath()
    //    private var pathHorizontal = UIBezierPath()
    
    var activeLayer: CAShapeLayer?
    
    private var rootRule: ChartRuleProtocol?
    
    private var footerRule: ChartRuleProtocol?
    
    private var topRule: ChartRuleProtocol?
    var rules = [ChartRuleProtocol]() // todo
    weak var dataSource: OMScrollableChartDataSource?
    var contentView: UIView!
    
    //    var footerView: UIStackView = UIStackView(frame: .zero)
    //    var topView: UIStackView     = UIStackView(frame: .zero)
    
    /// <#Description#>
    var polylineInterpolation: PolyLineInterpolation = .smoothed {
        didSet {
            updateLayout()
        }
    }
    
    var numberOfRuleMarks: CGFloat = 4 {
        didSet {
            setNeedsLayout()
        }
    }
    var internalRuelesMarks = [Float]()
    var rulesMarks: [Float] {
        return internalRuelesMarks.sorted(by: {return !($0 > $1)})
    }
    var showZeroMark: Bool = false {
        didSet {
            internalCalcRules()
        }
    }
    var showLimitsMarks: Bool = false {
        didSet {
            internalCalcRules()
        }
    }
    
    func calcRules() -> Bool {
        guard numberOfRuleMarks > 0 && (range != 0)  else {
            return false
        }
        internalRuelesMarks.removeAll()
        
        internalCalcRules()
        
        if showZeroMark {
            internalRuelesMarks.append(0)
        }
        
        if showLimitsMarks {
            internalRuelesMarks.append(maximumValue)
        }
        rulesPoints = makePoints(data: rulesMarks, size: contentSize)
        
        rules.forEach{$0.setNeedsLayout()}
        
        return true
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
    
    // Calculate the rules marks positions
    func internalCalcRules() {
        
        let counter = Int(numberOfRuleMarks) + Int(showLimitsMarks ? 1 : 0) + Int( showZeroMark ? 1 : 0)
        let roundedStep = range / Float(counter)
        
        for ruleMarkIndex in 0..<counter + 1    {
            let value = minimumValue + Float(roundedStep) * Float(ruleMarkIndex)
            internalRuelesMarks.append(value.roundToNearestValue(value: roundMarkValueTo))
        }
    }
    
    internal func updateRangeLimits(_ data: [Float]) {
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
    var minimum: Float? = nil {
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
    var range: Float {
        return maximumValue - minimumValue
    }
    
    private(set) var rawData: [Float]? {
        didSet {
            isLimitsDirty = true
        }
    }
    
    var hScale: CGFloat = 1.0
    var gradientFadePercentage: CGFloat = 0.2
    
    private(set) var maximumValue: Float = 0
    private(set) var minimumValue: Float = 0
    
    
    
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
    
    var linFunction: (slope: Float, intercept: Float)?
    func makeLinregressPoints(_ size: CGSize, numberOfElements: Int) -> ChartData
    {
        guard let originalData = originalData else {return  ([],  [] )}
        let originalDataIndex: [Float] = originalData.points.enumerated().map { Float($0.offset) }
        //        let max = originalData.points.max(by: { $0.x < $1.x})!
        //        let distance = mean(originalDataX.enumerated().compactMap{
        //            if $0.offset > 0 {
        //                return originalDataX[$0.offset-1].distance(to: $0.element)
        //            }
        //            return nil
        //        })
        
        
        // let results = originalDataX//.enumerated().map{ return originalDataX.prefix($0.offset+1).reduce(.zero, +)}
        
        linFunction = linregress(originalDataIndex, originalData.data)
        
        // var index = 0
        let result: [Float] = [Float].init(repeating: 0, count: numberOfElements)
        
        let resultre = result.enumerated().map{ dataForIndex(index: Float($0.offset))}
        //        for item in result  {
        //            result[index] = dataForIndex(index:  Float(index))
        //            index += 1
        //        }
        //
        
        let newData = originalData.data + resultre
        let newPoints =  makePoints(data: newData, size: size)
        return (newPoints,  resultre )
        
    }
    
    func dataForIndex(index: Float) -> Float {
        guard let linFunction = linFunction else { return 0 }
        return linFunction.slope * index + linFunction.intercept
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
    var dashPattern: [CGFloat] = [3, 3, 3, 3]
    var dashLineWidth: CGFloat = 0.5
    var drawGradient: Bool = true
    var gradientBaseColor = UIColor.lightGray
    var lineColor = UIColor.darkGray
    var fontFooterRuleColor = UIColor.black {
        didSet {
            footerRule?.fontColor = fontFooterRuleColor 
        }
    }
    var decorationFooterRuleColor = UIColor.black {
        didSet {
            footerRule?.decorationColor = decorationFooterRuleColor
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
    var dashLineColor = UIColor.gray.withAlphaComponent(0.8).cgColor
    var lineWidth: CGFloat = 1
    var approximationLineWidth: CGFloat = 0.5
    var footerViewHeight: CGFloat = 20
    var topViewHeight: CGFloat = 20
    var tooltipFont = UIFont.systemFont(ofSize: 14)
    var ruleFont = UIFont.systemFont(ofSize: 10, weight: .medium)
    var rulesPoints = [CGPoint]()
    var ruleLeadingAnchor: NSLayoutConstraint?
    var ruletopAnchor: NSLayoutConstraint?
    var rulebottomAnchor: NSLayoutConstraint?
    var rulewidthAnchor: NSLayoutConstraint?
    
    var ruleFooterLeadingAnchor: NSLayoutConstraint?
    var ruleFooterTopAnchor: NSLayoutConstraint?
    var ruleFooterBottomAnchor: NSLayoutConstraint?
    var ruleFooterWidthAnchor: NSLayoutConstraint?
    var ruleFooterHeightAnchor: NSLayoutConstraint?
    
    var showPoints: Bool = true
    var verticalMargins: ( CGFloat, CGFloat) = (0, 0)
    var circleSelectedColor = UIColor.red
    var circleSelectedOpacy: Float = 1.0
    var circleUnselectedOpacy: Float = 0
    var circleUnselectedColor = UIColor.blue
    var circleOutterColor = UIColor(white: 0.11, alpha: 0.5)
    var animatePolyLine = false
    var animateDashLines: Bool = false
    var circleSize: CGSize = .zero
    var numberOfPages: CGFloat = 1 {
        didSet {
            updateContentSize()
        }
    }
    var toolTipBackgroundColor: UIColor = UIColor.white
    var tooltipSize: CGSize = CGSize(width: 128, height: 128)
    
    var animatePointLayers: Bool = false
    var scaleFactor: CGFloat = 0.015
    var circleShadowOffset = CGSize(width: 0, height: 0.5)
    //var singleTap: UITapGestureRecognizer?
    //    var currentLayerIndex: Int = -1
    //    var allLayers = [CAShapeLayer]()
    //    @IBAction func tapRecognized(tap: UITapGestureRecognizer) {
    //        print("tap \(tap.numberOfTouches)")
    //        currentLayerIndex = (currentLayerIndex + 1) % allLayers.count
    //        self.activeLayer = allLayers[currentLayerIndex]
    //        self.allLayers.filter({$0 != self.activeLayer}).forEach({$0.isHidden = true})
    //        self.activeLayer!.isHidden = false
    //        dump(activeLayer)
    //        self.contentView.setNeedsDisplay()
    //    }
    //    var pinchGesture: UIPinchGestureRecognizer?
    //    @IBAction func pinchRecognized(pinch: UIPinchGestureRecognizer) {
    //        let newScale = pinch.scale
    //        print("pitch \(newScale)")
    //        self.numberOfPages = ceil(newScale)
    //        print(newScale)
    //    }
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        setupView()
        self.clearsContextBeforeDrawing = true
    }
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
    }
    // Unregister the ´orientationDidChangeNotification´ notification
    fileprivate func unregisterNotifications () {
        NotificationCenter.default.removeObserver(self)
    }
    // Setup the UIScrollView
    func setupScrollView () {
        self.delegate = self
        if #available(iOS 11, *) {
            self.contentInsetAdjustmentBehavior = .never
        }
    }
    func setupRules() {
        let newRule = OMScrollableChartRule(chart: self)
        newRule.chart = self
        newRule.font  = ruleFont
        newRule.fontColor = fontRootRuleColor
        let footerRule = OMScrollableChartRuleFooter(chart: self)
        footerRule.chart = self
        footerRule.font  = ruleFont
        footerRule.fontColor = fontFooterRuleColor
        //        self.addSubview(footerRule)
        //        self.addSubview(newRule)
        self.rootRule = newRule
        self.footerRule = footerRule
        self.rules.append(newRule)
        self.rules.append(footerRule)
    }
    // Setup all the view/subviews
    func setupView() {
        self.registerNotifications()
        self.setupRules()
        self.setupScrollView()
        self.setupContentView()
    }
    
    func setupGestures() {
        //self.delaysContentTouches = false
        //self.singleTap = UITapGestureRecognizer(target: self, action: #selector(tapRecognized(tap:)))
        //self.singleTap?.numberOfTapsRequired = 1
        //self.singleTap?.numberOfTouchesRequired = 1
        //self.addGestureRecognizer(singleTap!)
        //self.pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchRecognized(pinch:)))
        // self.contentView.addGestureRecognizer(self.pinchGesture!)
    }
    
    func setupContentView() {
        self.contentView = UIView(frame: self.bounds)
        self.addSubview(contentView)
        //        NSLayoutConstraint.activate([
        //            // constrain scrollView to all 4 sides with 20-pts padding
        ////            topAnchor.constraint(equalTo: superview!.safeAreaLayoutGuide.topAnchor, constant: 20.0),
        ////            bottomAnchor.constraint(equalTo: superview!.safeAreaLayoutGuide.bottomAnchor, constant: -20.0),
        ////            leadingAnchor.constraint(equalTo: superview!.safeAreaLayoutGuide.leadingAnchor, constant: 20.0),
        ////            trailingAnchor.constraint(equalTo: superview!.safeAreaLayoutGuide.trailingAnchor, constant: -20.0),
        //
        //            // constrain contentView to all 4 sides of scrollView with 8-pts padding
        //            contentView.topAnchor.constraint(equalTo: topAnchor, constant: 20.0),
        //            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20.0),
        //            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
        //            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
        //        ])
        
        //        self.contentView.layer.borderColor = UIColor.red.cgColor
        //        self.contentView.layer.borderWidth = 2
    }
    
    
    // MARK: - Rotation support -
    fileprivate func updateContentSize() {
        self.layoutIfNeeded()
        let newValue = CGSize(width: self.bounds.width * numberOfPages, height: self.bounds.height)
        if self.contentSize != newValue {
            self.contentSize = newValue
            
            contentView.frame = CGRect(x: 0, y: 0, width: self.contentSize.width, height: self.contentSize.height)
        }
        self.updateLayout()
    }
    // MARK: - handleRotation -
    @objc func handleRotation() {
        self.updateContentSize()
    }
    deinit {
        self.unregisterNotifications()
    }
    func updateData() -> Bool {
        if let dataSource = dataSource {
            //let numberOfSections = dataSource.numberOfSections(chart: self)
            let newData = dataSource.dataPoints(chart: self, section: 0)
            let newNumberOfPages = dataSource.numberOfPages(chart: self)
            //print(self.rawData == newData)
            //print(newNumberOfPages == self.numberOfPages)
            self.rawData = newData
            self.numberOfPages = newNumberOfPages
            return true
            //}
        }
        return false
    }
    var numberOfSectionsPerPage  = 6          // For example: mouths
    //    var numberOfItemsPerSection: Int {          // For example: weeks
    //        return (rawData.count)! / numberOfSections
    //    }
    var numberOfSections: Int {         // Total
        return numberOfSectionsPerPage * Int(numberOfPages)
    }
    //    var numberOfItems: Int {           // Total
    //        return numberOfItemsPerSection * Int(numberOfPages)
    //    }
    //    var numberOfColumns: Int {
    //        return (numberOfItemsPerSection * numberOfSectionsPerPage) * Int(numberOfPages)
    //    }
    //    var itemWidth: CGFloat {
    //        return self.contentSize.width/CGFloat(numberOfColumns)
    //    }
    //
    var sectionWidth: CGFloat {
        return self.contentSize.width/CGFloat(numberOfSections)
    }
    
    //    fileprivate var gridHeight: CGFloat
    //    {
    //        return self.contentSize.height/CGFloat(numberOfRows)
    //    }
    
    
    //    fileprivate func drawVerticalGridLines()
    //    {
    //        pathVertical = UIBezierPath()
    //        pathVertical.lineWidth = 1
    //
    //        for index in 1...Int(numberOfColumns) - 1
    //        {
    //            let start = CGPoint(x: CGFloat(index) * itemWidth, y: 0)
    //            let end = CGPoint(x: CGFloat(index) * itemWidth, y: self.frame.height)
    //            pathVertical.move(to: start)
    //            pathVertical.addLine(to: end)
    //
    //            //            let start2 = CGPoint(x: CGFloat(index) * itemWidth, y: 0)
    //            //            let end2 = CGPoint(x: CGFloat(index) * itemWidth, y: 10)
    //            //            pathVertical.move(to: start2)
    //            //            pathVertical.addLine(to: end2)
    //        }
    //
    //        //Close the path.
    //        pathVertical.close()
    //
    //    }
    //
    //
    //    fileprivate func drawHorizalGridLines()
    //    {
    //        pathHorizontal = UIBezierPath()
    //        pathHorizontal.lineWidth = 1
    //        for index in 1...Int(numberOfRows) - 1
    //        {
    //            let start = CGPoint(x:  0, y: CGFloat(index) * gridHeight)
    //            let end = CGPoint(x:  bounds.width+contentOffset.x, y: CGFloat(index) * gridHeight)
    //            pathHorizontal.move(to: start)
    //            pathHorizontal.addLine(to: end)
    //        }
    //
    //        //Close the path.
    //        pathHorizontal.close()
    //
    //    }
    
    //    func drawDashLine( point: CGPoint, pointe: CGPoint ) {
    //        let path = UIBezierPath()
    //        // define the pattern & apply it
    //        path.setLineDash(dashPattern, count: dashPattern.count, phase: 0)
    //        path.lineWidth = dashLineWidth
    //        path.move(to: point)
    //        path.addLine(to: pointe)
    //        path.stroke()
    //    }
    
    
    func addDashLineLayer(point: CGPoint, pointe: CGPoint, stroke: UIColor? = nil, lineWidth: CGFloat? = nil, pattern: [NSNumber]? = nil) {
        
        let lineLayer = CAShapeLayer()
        lineLayer.strokeColor = stroke?.cgColor ?? dashLineColor
        lineLayer.lineWidth = lineWidth ?? dashLineWidth
        lineLayer.lineDashPattern = pattern ?? dashPattern as [NSNumber]
        let path = CGMutablePath()
        path.addLines(between: [point,
                                pointe])
        lineLayer.path = path
        dashLineLayers.append(lineLayer)
        contentView.layer.addSublayer(lineLayer)
    }
    
    // Draw the line.
    fileprivate func drawGradient( ctx: CGContext?) {
        if  let ctx = ctx {
            let gradient = CGGradient(colorsSpace: nil, colors: [UIColor.white.withAlphaComponent(0.1).cgColor,
                                                                 gradientBaseColor.cgColor,
                                                                 gradientBaseColor.withAlphaComponent(gradientFadePercentage).cgColor ,
                                                                 UIColor.white.withAlphaComponent(0.8).cgColor
                /*
                 UIColor.black.cgColor*/] as CFArray,
                                      locations: [0, gradientFadePercentage, 1 - gradientFadePercentage, 1] )!
            
            
            
            ctx.saveGState()
            
            // Clip to the path, stroke and enjoy.
            if let path = activeLayer?.path {
                lineColor.setStroke()
                let curPath = UIBezierPath(cgPath: path)
                curPath.lineWidth = lineWidth
                curPath.stroke()
                curPath.addClip()
                
                // Draw the gradient in the clipped region
                ctx.drawLinearGradient(gradient,
                                       start: CGPoint(x: rootRule!.ruleSize.width, y: 0),
                                       end: CGPoint(x: rootRule!.ruleSize.width, y: contentSize.height),
                                       options: [.drawsAfterEndLocation])
                
                
                
            }
            
            
            
            ctx.restoreGState()
        }
    }
    //    // Draw the line.
    //    fileprivate func drawGradientApproximation( ctx: CGContext?) {
    //        if  let ctx = ctx {
    //
    //            let gradientApproximation = CGGradient(colorsSpace: nil, colors: [UIColor.white.withAlphaComponent(0.1).cgColor,
    //                                                                              approximationLineColor.withAlphaComponent(0.8).cgColor,
    //                                                                              approximationLineColor.withAlphaComponent(gradientFadePercentage).cgColor ,
    //                                                                              UIColor.white.withAlphaComponent(0.8).cgColor
    //                /*
    //                 UIColor.black.cgColor*/] as CFArray,
    //                                                   locations: [0, gradientFadePercentage, 1 - gradientFadePercentage, 1] )!
    //
    //
    //            ctx.saveGState()
    //
    //            // Clip to the path, stroke and enjoy.
    //            if  let approximationPath = linePathApproximationPointsLayer.path {
    //
    //
    //                approximationLineColor.setStroke()
    //                let approximationPath = UIBezierPath(cgPath: approximationPath)
    //                approximationPath.lineWidth = approximationLineWidth
    //                approximationPath.stroke()
    //                approximationPath.addClip()
    //
    //                // Draw the gradient in the clipped region
    //                ctx.drawLinearGradient(gradientApproximation,
    //                                       start: CGPoint(x: rootRule!.ruleSize.width, y: 0),
    //                                       end: CGPoint(x: rootRule!.ruleSize.width, y: contentSize.height),
    //                                       options: [.drawsAfterEndLocation])
    //            }
    //
    //
    //
    //            ctx.restoreGState()
    //        }
    //   }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if let ctx = UIGraphicsGetCurrentContext() {
            if drawGradient {
                drawGradient(ctx: ctx)
                //if approximationRatio > 0 {
                // drawGradientApproximation(ctx: ctx)
                //  }
            } else {
                
                ctx.saveGState()
                // Clip to the path
                if let path = activeLayer?.path {
                    let pathToFill = UIBezierPath(cgPath: path)
                    self.gradientBaseColor.setFill()
                    pathToFill.fill()
                }
                ctx.restoreGState()
            }
        }
        //drawVerticalGridLines()
        //drawHorizalGridLines()
        // Specify a border (stroke) color.
        // UIColor.black.setStroke()
        // pathVertical.stroke()
        //        pathHorizontal.stroke()
    }
    var pointsInsetTop: CGFloat    = 20
    var pointsInsetBottom: CGFloat = 40
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
    
    //    func groupAverage(_ arr: [Float], numberOfElements:Int) -> [Float] {
    //        var result = [Float]();
    //        var sum: Float
    //        let to = arr.count/numberOfElements
    //        var index: Int = 0
    //        for i in stride(from: 0, to: to, by: 1)
    //        {
    //            sum = 0;
    //            //      let xx = (arr.count - numberOfElements * i)
    //            for j in stride(from: 0, to: numberOfElements , by: 1) {
    //                // Check if value is numeric. If not use default value as 0
    //                index = (i*numberOfElements)+j
    //                sum += arr[index]
    //            }
    //
    //            result.append( sum / Float(numberOfElements))
    //
    //        }
    //        let rest = (arr.count % numberOfElements)
    //        if rest > 0  {
    //            sum = 0;
    //            for i in stride(from: arr.count - rest, to: rest, by: 1)
    //            {
    //                sum += arr[i]
    //            }
    //            result.append( sum / Float(rest))
    //
    //        }
    //        return result
    //    }
    
    typealias ChartData = (points: [CGPoint], data: [Float])
    
    var averagedData: ChartData? {
        didSet {
            //            guard let data = averagedData else {
            //                return
            //            }
            //            if type == .averaged {
            //                updateRangeLimits(data.data)
            //            }
        }
    }
    enum TypeOfData {
        case raw
        case averaged
        case approximation
        case linregress
    }
    
    var type: TypeOfData = .raw
    var internalPoints: [CGPoint]?  {
        return currentData?.points
    }
    
    var internalData: [Float]?  {
        return currentData?.data
    }
    
    var currentData: ChartData? {
        switch type {
        case .raw:
            return originalData
        case .averaged:
            if numberOfElementsToAverage == 0 {
                return  originalData
            } else {
                return averagedData
            }
        case .approximation:
            if approximationTolerance == 0 {
                return originalData
            } else {
                return approximationData
            }
        case .linregress:
            return linregressData
        }
    }
    
    
    var linregressData: ChartData? {
        didSet {
            //            guard let data = linregressData else {
            //                return
            //            }
            
            //            if type == .linregress {
            //                updateRangeLimits(data.data)
            //            }
        }
    }
    var originalData: ChartData? {
        didSet {
            //            guard let data = originalData else {
            //                return
            //            }
            
            //if type == .raw {
            //updateRangeLimits(data.data)
            //}
        }
    }
    var approximationData: ChartData? {
        didSet {
            //            guard let data = approximationData else {
            //                return
            //            }
            //            if type == .approximation {
            //                updateRangeLimits(data.data)
            //            }
        }
    }
    func makeAveragedPoints( data: [Float], size: CGSize) ->  ([CGPoint], [Float])? {
        if numberOfElementsToAverage != 0 {
            var result: Float = 0
            let positives = data.map{$0>0 ? $0 : abs($0)}
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
    
    func makeApproximationPoints( size: CGSize) ->  ([CGPoint], [Float])? {
        guard approximationTolerance != 0, let data = self.originalData else {
            return nil
        }
        
        
        let approximationPoints = OMSimplify.decimate(data.points, tolerance: CGFloat(approximationTolerance))
        
        return (approximationPoints, data.data)
        
        // Brute force the numberOfResultPoints
        //        var bruteforceTolerance = 0
        //        var maximunCount        = 100
        //        var approximationPoints: [CGPoint]?
        //        //let xxx = OMSimplify.simplify2(data.points)
        //        repeat {
        //            bruteforceTolerance += 1
        //            approximationPoints = OMSimplify.decimate(data.points, tolerance: CGFloat(bruteforceTolerance))
        //            if numberOfResultPoints >= approximationPoints!.count {
        //                return (approximationPoints!, data.data)
        //            }
        //            maximunCount -= 1
        //        } while(maximunCount > 0)
        //        return (approximationPoints ?? data.points , data.data)
    }
    
    
    //    func addSubFooterViews() {
    //
    //        for item in footerLabels
    //        {
    //            footerView.removeArrangedSubview(item)
    //            item.removeFromSuperview()
    //        }
    //        footerLabels.removeAll()
    //        //let date = Calendar.current.dateComponents([.day , .month , .year], from: Date())
    //        for index in 0...Int(numberOfSection) - 1
    //        {
    //            let label = UILabel(frame: .zero)
    //            label.translatesAutoresizingMaskIntoConstraints = false
    //            label.text = DateFormatter().monthSymbols[index]
    //            label.textAlignment = .center
    //            label.sizeToFit()
    //            label.backgroundColor = UIColor.white
    //            label.textColor = UIColor.black
    //            //                label.layer.borderColor = UIColor.lightGray.cgColor
    //            //                label.layer.borderWidth = 1
    //            footerView.addArrangedSubview(label)
    //
    //
    //            label.widthAnchor.constraint(equalToConstant: sectionWidth).isActive = true
    //            label.heightAnchor.constraint(equalToConstant: footerViewHeight).isActive = true
    //
    //            footerLabels.append(label)
    //
    //        }
    //
    //        //        for item in topLabels
    //        //        {
    //        //            topView.removeArrangedSubview(item)
    //        //            item.removeFromSuperview()
    //        //        }
    //        //        topLabels.removeAll()
    //        //        for index in 0...Int(numberOfColumns)
    //        //        {
    //        //            let label = UILabel(frame: .zero)
    //        //            label.translatesAutoresizingMaskIntoConstraints = false
    //        //            //label.text = DateFormatter().shortWeekdaySymbols[0]
    //        //            label.textAlignment = .center
    //        //            //label.sizeToFit()
    //        //            label.backgroundColor = UIColor(white: CGFloat(CGFloat(1.0 / Double(numberOfColumns)) * CGFloat(index)), alpha: 1.0)
    //        //            label.textColor = UIColor.black
    //        //            label.layer.borderColor = UIColor.lightGray.cgColor
    //        //            label.layer.borderWidth = 1
    //        //            topView.addArrangedSubview(label)
    //        //
    //        //
    //        //            label.widthAnchor.constraint(equalToConstant: itemWidth).isActive = true
    //        //            label.heightAnchor.constraint(equalToConstant: topViewHeight).isActive = true
    //        //
    //        //            topLabels.append(label)
    //        //
    //        //        }
    //
    //    }
    
    func addRootRule(_ rule: ChartRuleProtocol, view: UIView?) {
        assert(rule.type == .root)
        if rule.superview == nil {
            rule.translatesAutoresizingMaskIntoConstraints = false
            
            if let view = view  {
                view.insertSubview(rule, at: 0)
            } else {
                self.insertSubview(rule, at: 0)
            }
            
            ruleLeadingAnchor  = rule.leadingAnchor.constraint(equalTo: self.leadingAnchor)
            ruletopAnchor =         rule.topAnchor.constraint(equalTo: self.topAnchor)
            rulebottomAnchor =          rule.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            rulewidthAnchor =          rule.widthAnchor.constraint(equalToConstant: CGFloat(rule.ruleSize.width))
            
            
            
            ruleLeadingAnchor?.isActive  = true
            ruletopAnchor?.isActive  = true
            rulebottomAnchor?.isActive  = true
            rulewidthAnchor?.isActive  = true
        }
        
    }
    fileprivate func addFooterRule(_  ruleFooter: ChartRuleProtocol? = nil, view: UIView? = nil) {
        guard let ruleFooter = ruleFooter else {
            return
        }
        assert(ruleFooter.type == .footer)
        if ruleFooter.superview == nil {
            ruleFooter.translatesAutoresizingMaskIntoConstraints = false
            
            if let view = view  {
                view.addSubview(ruleFooter)
            } else {
                self.addSubview(ruleFooter)
            }
            
            let width = ruleFooter.ruleSize.width > 0 ? ruleFooter.ruleSize.width: contentSize.width
            
            ruleFooter.backgroundColor = UIColor.gray
            ruleFooter.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
            ruleFooter.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
            ruleFooter.topAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -footerViewHeight).isActive = true
            ruleFooter.heightAnchor.constraint(equalToConstant: CGFloat(ruleFooter.ruleSize.height)).isActive = true
            ruleFooter.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
    }
    
    fileprivate func addTopRule(_ ruleTop: ChartRuleProtocol? = nil) {
        guard let ruleTop = ruleTop else {
            return
        }
        assert(ruleTop.type == .top)
        //ruleTop.removeFromSuperview()
        ruleTop.translatesAutoresizingMaskIntoConstraints = false
        ruleTop.backgroundColor = UIColor.clear
        self.addSubview(ruleTop)
        //        topView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        //        topView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        ruleTop.topAnchor.constraint(equalTo:  self.topAnchor).isActive = true
        ruleTop.heightAnchor.constraint(equalToConstant: CGFloat(topViewHeight)).isActive = true
        ruleTop.widthAnchor.constraint(equalToConstant: contentSize.width).isActive = true
        ruleTop.backgroundColor = .gray
    }
    
    
    fileprivate func createSuplementaryRules() {
        //       self.layer.borderColor = UIColor.red.cgColor
        //       self.layer.borderWidth = 1
        
        
        if let rootRule = rootRule {
            addRootRule(rootRule,view: self)
            rootRule.layer.borderColor = UIColor.red.cgColor
            rootRule.layer.borderWidth = 1
        }
        
        if let footerRule = footerRule {
            addFooterRule(footerRule)
            footerRule.layer.borderColor = UIColor.red.cgColor
            footerRule.layer.borderWidth = 1
        }
        
        if let topRule = topRule {
            addTopRule(topRule)
            topRule.layer.borderColor = UIColor.red.cgColor
            topRule.layer.borderWidth = 1
        }
    }
    
    fileprivate func removeAllLayers() {
        self.pointCircleLayers.forEach({ (layer: CALayer) -> () in
            layer.removeFromSuperlayer()
        })
        self.pointCircleLayers.removeAll()
        self.activeLayer?.removeFromSuperlayer()
        //self.linePathApproximationPointsLayer.removeFromSuperlayer()
    }
    var tolltipBorderColor = UIColor.black.cgColor
    var tooltipBorderWidth: CGFloat = 0.2
    lazy var tooltip: OMTooltip = {
        let label = OMTooltip(frame: CGRect(x: 0, y: 0, width: 128, height: 30))
        label.font = tooltipFont
        label.alpha = 0
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.backgroundColor = toolTipBackgroundColor
        label.layer.borderColor = tolltipBorderColor
        label.layer.borderWidth = tooltipBorderWidth
        label.layer.shadowColor   = UIColor.black.cgColor
        label.layer.shadowOffset  = circleShadowOffset
        label.layer.shadowOpacity = 0.7
        label.layer.shadowRadius  = 3.0
        self.contentView.addSubview(label)
        return label
    }()
    var touchScreenLineLayerColor = UIColor.clear
    var touchScreenLineWidth: CGFloat = 0.5
    var touchScreenLineLayerPath: UIBezierPath?
    
    lazy var touchScreenLineLayer: CAShapeLayer = {
        let lineLayer = CAShapeLayer()
        lineLayer.lineJoin = CAShapeLayerLineJoin.round
        lineLayer.shadowColor   = UIColor.yellow.cgColor
        //lineLayer.shadowOffset  = circleShadowOffset
        lineLayer.shadowOpacity = 0.7
        lineLayer.shadowRadius  = 1.0
        self.contentView.layer.addSublayer(lineLayer)
        return lineLayer
    }()
    var animateLineSelection: Bool = true
    fileprivate func updateLineSelectionLayer(_ location: CGPoint) {
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint( x: location.x, y: topViewHeight))
        linePath.addLine(to: CGPoint( x: location.x, y: self.footerRule!.frame.origin.y ))
        //touchScreenLineLayerPath = linePath
        touchScreenLineLayer.strokeColor = touchScreenLineLayerColor.cgColor
        touchScreenLineLayer.lineWidth = touchScreenLineWidth
        
        //        if animateLineSelection {
        //
        //            animateLineSelection(c, linePath.cgPath, 2)
        //
        //
        //        } else{
        touchScreenLineLayer.path = linePath.cgPath
        //     }
        
        
        
    }
    func selectPointCircleLayer(_ layer: CAShapeLayer) {
        
        let allUnselectedPoints = self.pointCircleLayers.filter { $0 != layer }
        allUnselectedPoints.forEach { (layer: CAShapeLayer) in
            layer.fillColor = self.circleUnselectedColor.cgColor
            layer.opacity   = circleUnselectedOpacy
        }
        
        layer.fillColor = self.circleSelectedColor.cgColor
        layer.opacity   = self.circleSelectedOpacy
    }
    
    func touchPointAsLayer( _ location: CGPoint) -> OMPointLayer? {
        let mapped = pointCircleLayers.map {
            return $0.frame.origin.distance(from: location)
        }
        guard let index = mapped.indexOfMin else{
            return nil
        }
        return self.pointCircleLayers[index]
    }
    
    func hitTestTouchPointAsLayer( _ location: CGPoint) -> CAShapeLayer? {
        if let layer = self.contentView.layer.hitTest(location) as? CAShapeLayer { // If you hit a layer and if its a Shapelayer
            return layer
        }
        return nil
    }
    func willSelectPointLayer(_ layer: CAShapeLayer)
    {
        
        
    }
    func didSelectPointLayer(_ layer: CAShapeLayer)
    {
        
    }
    
    
    func selectPointLayer(_ layer: OMPointLayer)
    {
        selectPointCircleLayer(layer)
        
        if animatePointLayers {
            animateOnSelectPoint(layer)
        }
        
        willShowTooltip(tooltip)
        
        if let string = dataStringFromPoint(layer.position) {
            tooltip.setText(string)
            tooltip.show(layer.position)
        }
        
        
        didShowTooltip(tooltip)
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches , with: event)
        
        let location: CGPoint = locationFromTouch(touches)
        
        updateLineSelectionLayer(location)
        if let layer = hitTestTouchPointAsLayer(location) ?? touchPointAsLayer(location) , let pointLayer = layer as? OMPointLayer  {
            willSelectPointLayer(pointLayer)
            selectPointLayer(pointLayer)
            didSelectPointLayer(pointLayer)
        }
        
    }
    fileprivate func locationFromTouch(_ touches: Set<UITouch>) -> CGPoint {
        if let touch = touches.first {
            return touch.location(in: self.contentView)
        }
        
        return .zero
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?){
        super.touchesMoved(touches , with:event)
        let location: CGPoint = locationFromTouch(touches)
        updateLineSelectionLayer(location)
        tooltip.move(location)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches , with: event)
        let location: CGPoint = locationFromTouch(touches)
        willHideTooltip(tooltip)
        tooltip.hide(location)
        didHideTooltip(tooltip)
    }
    open func willShowTooltip(_ toolTip: OMTooltip)
    {
        
        
    }
    open func didShowTooltip(_ toolTip: OMTooltip)
    {
        
        
    }
    open func willHideTooltip(_ toolTip: OMTooltip)
    {
        
    }
    open func didHideTooltip(_ toolTip: OMTooltip)
    {
        
    }
    
    fileprivate func addPointsLayers( _ points: [CGPoint] , size:CGSize, unselectedColor: UIColor) -> [OMPointLayer] {
        var layers =  [OMPointLayer]()
        for point in points {
            let circleLayer = OMPointLayer()
            let scaled = Swift.min(self.bounds.width, self.bounds.width) * scaleFactor
            let layerSize = size == .zero ? CGSize(width: scaled, height: scaled): size
            circleLayer.bounds = CGRect(x: 0,
                                        y: 0,
                                        width: layerSize.width,
                                        height: layerSize.height)
            
            let path = UIBezierPath(ovalIn: circleLayer.bounds).cgPath
            circleLayer.path            = path
            circleLayer.fillColor       = unselectedColor.cgColor
            circleLayer.position        = point
            circleLayer.strokeColor     = UIColor.black.cgColor
            circleLayer.lineWidth       = 0.5
            
            //            circleLayer.shadowColor     = UIColor.black.cgColor
            //            circleLayer.shadowOffset    = circleShadowOffset
            //            circleLayer.shadowOpacity   = 0.7
            //            circleLayer.shadowRadius    = 3.0
            circleLayer.isHidden        = !showPoints
            
            circleLayer.bounds = circleLayer.path!.boundingBoxOfPath
            self.contentView.layer.addSublayer(circleLayer)
            layers.append(circleLayer)
        }
        
        return layers
    }
    
    func indexForPoint(_ point: CGPoint) -> Int?
    {
        let newPoint = CGPoint(x: point.x, y: point.y)
        return originalData?.points.map ({ $0.distance(to: newPoint)}).indexOfMin
    }
    
    func dataStringFromPoint(_ point: CGPoint) -> String? {
        if self.type == .averaged {
            if let firstIndex = indexForPoint(point) {
                let item: Double = Double(originalData!.data[firstIndex])
                if let currentStep = currencyFormatter.string(from: NSNumber(value: item)) {
                    return  currentStep
                }
            }
        } else {
            if let firstIndex = internalPoints!.firstIndex(of: point)  {
                let item: Double = Double(internalData![firstIndex])
                if let currentStep = currencyFormatter.string(from: NSNumber(value:item)) {
                    return currentStep
                }
            }
        }
        
        return nil
    }
    
    fileprivate func layoutRules() {
        // rules lines
        guard let rule = rootRule, calcRules() else {
            return
        }
        
        dashLineLayers.forEach({$0.removeFromSuperlayer()})
        
        let zeroMarkIndex = rulesMarks.firstIndex(of: 0)
        let padding: CGFloat = rule.ruleSize.width
        let width = contentView.frame.width
        rulesPoints.enumerated().forEach { (offset: Int, item: CGPoint) in
            
            if showZeroMark == false || zeroMarkIndex != offset {
                addDashLineLayer(point: CGPoint(x: padding, y: item.y),
                                 pointe: CGPoint(x: width, y: item.y))
            } else {
                if zeroMarkIndex == offset {
                    addDashLineLayer(point: CGPoint(x: padding, y: item.y),
                                     pointe: CGPoint(x: width, y: item.y),
                                     stroke: UIColor.blue.withAlphaComponent(0.3),
                                     lineWidth: 2,
                                     pattern: [8, 6])
                }
            }
        }
        

        
        // Mark for display the rule.
        
        rules.forEach {
            if $0.isPointsNeeded {
                $0.isPointsNeeded = $0.createLayout()
            }
        }
        
    }
    
    fileprivate func updateLayout() {
        if let rawData = rawData {
            removeAllLayers()
            createSuplementaryRules()
            
            self.originalData   = makeRawPoints(data: rawData, size: contentSize)
            self.linregressData = makeLinregressPoints(contentSize, numberOfElements: 90)
            self.averagedData = makeAveragedPoints(data: rawData, size: contentSize)
            self.approximationData = makeApproximationPoints( size: contentSize)
        
            updateLayersIfNeeded()
            activeLayer = currentLayer
            
            if let activeLayer = activeLayer {
                
                self.contentView.layer.addSublayer(self.activeLayer!)
                
                if animatePolyLine {
                    currentLayer.strokeEnd = 0
                }
                
                
                
                if showPoints {
                    guard let currentData = currentData else {
                        return
                    }
                    
                    pointCircleLayers = addPointsLayers(currentData.points,
                                                        size: CGSize(width: circleSize.width * 3, height: circleSize.height * 3),
                                                        unselectedColor: circleUnselectedColor.withAlphaComponent(0.5))
                    
                    
                    
                }
                layoutRules()
                
                currentLayer.frame = contentView.bounds
                //
                if self.animateDashLines {
                    animateDashLinesPhase()
                }
                if self.animatePolyLine {
                    animateLine()
                }
                
                setNeedsDisplay()
            }
            //            if self.animatePointLayers {
            //                animateOnSelectPoint(nil)
            //            }
        }
    }
    
    override var contentOffset: CGPoint {
        get {
            return super.contentOffset
        }
        set(newValue) {
            if contentOffset != newValue {
                super.contentOffset = newValue
                let aff = CGAffineTransform(translationX: contentOffset.x, y: contentOffset.y)
                dashLineLayers.forEach({
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    $0.setAffineTransform(aff)
                    CATransaction.commit()
                })
            }
        }
    }
    
    override var frame: CGRect {
        set(newValue){
            super.frame = newValue;
            self.setNeedsLayout()
        }
        get { return super.frame}
    }
    
    override func layoutSubviews() {
        self.backgroundColor = .clear
        super.layoutSubviews()
        if self.updateData() {
            self.updateLayout()
        } else {
            //print("layout is ok")
        }
    }
    /// animatePoints
    /// - Parameters:
    ///   - layers: CAShapeLayer
    ///   - delay: TimeInterval delay [0.1]
    ///   - duration: TimeInterval duration [ 2.0]
    func animatePoints(_ layers: [CAShapeLayer], delay: TimeInterval = 0.1, duration: TimeInterval = 2.0) {
        var currentDelay = delay
        for point in layers {
            point.opacity = 1
            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
            fadeAnimation.toValue = 0.3
            fadeAnimation.beginTime = CACurrentMediaTime() + currentDelay
            fadeAnimation.duration = duration
            fadeAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            fadeAnimation.fillMode = CAMediaTimingFillMode.forwards
            fadeAnimation.isRemovedOnCompletion = false
            point.add(fadeAnimation, forKey: nil)
            currentDelay += 0.05
        }
    }
    
    func animateOnSelectPoint(_ selectedLayer: OMPointLayer, duration: TimeInterval = 2.0) {
        
        if let index = self.pointCircleLayers.firstIndex(of: selectedLayer) {
            let count = self.pointCircleLayers.count - 1
            let pointBegin = self.pointCircleLayers.takeElements(index)
            let pointEnd   = self.pointCircleLayers.takeElements(count - index,
                                                                 startAt: index + 1)
            animatePoints(pointBegin.reversed(), duration: duration)
            animatePoints(pointEnd, duration: duration)
        }
    }
    
    func animateLineSelection(_ layer: CAShapeLayer,_ newPath: CGPath, _ duration: TimeInterval = 1) {
        // the new origin of the CAShapeLayer within its view
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue =  layer.path           // animate from current position ...
        animation.toValue = newPath                        // ... to whereever the new position is
        animation.duration = duration
        animation.isAdditive = true
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        // set the shape's final position to be the new position so when the animation is done, it's at its new "home"
        layer.add(animation, forKey: nil)
    }
    
    func animateDashLinesPhase() {
        for layer in dashLineLayers {
            let animation = CABasicAnimation(keyPath: "lineDashPhase")
            animation.fromValue = 0
            animation.toValue = layer.lineDashPattern?.reduce(0) { $0 - $1.intValue } ?? 0
            animation.duration = 1
            animation.repeatCount = .infinity
            layer.add(animation, forKey: "line")
        }
    }
    
    func animateLine() {
        let fromValue = self.contentOffset.x / self.contentSize.width
        let growAnimation = CABasicAnimation(keyPath: "strokeEnd")
        //let fromValue =  self.contentSize.width /  self.contentOffset.x == 0 ? 1 :  self.contentOffset.x
        growAnimation.fromValue = fromValue
        growAnimation.toValue = 1
        growAnimation.beginTime = CACurrentMediaTime() + 0.5
        growAnimation.duration = 1.5
        growAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        growAnimation.fillMode = CAMediaTimingFillMode.forwards
        growAnimation.isRemovedOnCompletion = false
        activeLayer?.add(growAnimation, forKey: "StrokeAnimation")
        
        //        let startAnimation = CABasicAnimation(keyPath: "strokeStart")
        //        startAnimation.fromValue = 0
        //        startAnimation.toValue = 0.8
        //
        //        let endAnimation = CABasicAnimation(keyPath: "strokeEnd")
        //        endAnimation.fromValue = 0.2
        //        endAnimation.toValue = 1.0
        //
        //        let animation = CAAnimationGroup()
        //        animation.animations = [startAnimation, endAnimation]
        //        animation.duration = 2
        //        catmullRomLineLayer.add(animation, forKey: "MyAnimation")
    }
    
    
    
}
extension OMScrollableChart {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if self.isTracking {
            self.setNeedsDisplay()
            // ...
        }
        ruleLeadingAnchor?.constant = self.contentOffset.x
        //        self.layoutIfNeeded()
        //        //
        //        rule?.frame = CGRect(x: self.frame.origin.x+self.contentOffset.x,
        //                             y: self.frame.origin.y+self.contentOffset.y,
        //                             width: ruleWidth,
        //                             height: self.frame.height)
    }
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        setContentOffset(self.contentOffset, animated: true)
    }
    
    
    
}
