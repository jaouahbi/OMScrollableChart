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
import OMScrollableChart
import LibControl

//let chartPoints: [Float] =   [110, 10, 30, 10, 10, 30,
//    150, -150, 80, -40, 60, 10,110, 10, 30, 10, 10, 30,
//    150, -150, 80, -40, 60, 10,110, 10, 30, 10, 10, 30,
//    150, -150, 80, -40, 60, 10,110, 10, 30, 10, 10, 30,
//    150, -150, 80, -40, 60, 10,110, 10, 30, 10, 10, 30,
//    150, -150, 80, -40, 60, 10,110, 10, 30, 10, 10, 30,
//    150, -150, 80, -40, 60, 10]
//             1510, 100, 3000, 100, 1200, 13000,
//15000, -1500, 800, 1000, 6000, 1300]


public protocol RenderClientProtocol {
    var timingTable: [AnimationTiming] {get set}
    var opacityTable: [Opacity]  {get set}
}


enum ExampleRendersIdentify: RenderIdent.RawValue {
    case bar1 = 3
    case bar2 = 4
    case segments = 5
}

public class SegmentsRender: BaseRender {
    override init() {
        super.init(index: ExampleRendersIdentify.segments.rawValue)
    }
}

public class Bar1Render: BaseRender {
    override init() {
        super.init(index: ExampleRendersIdentify.bar1.rawValue)
    }
}

public class Bar2Render: BaseRender {
    override init() {
        super.init(index: ExampleRendersIdentify.bar2.rawValue)
    }
}


public class ExampleRenderManager: RenderManager {
    open override func configureRenders() -> [BaseRender] {
        return super.configureRenders() + [RenderManager.bar1,
                                           RenderManager.bar2,
                                           RenderManager.segments]
    }
}

extension RenderManager {
    
    //
    // Renders
    //
    
    public static var bar1: Bar1Render = Bar1Render()
    public static var bar2: Bar2Render = Bar2Render()
    public static var segments: SegmentsRender = SegmentsRender()
}

class ViewController: UIViewController, OMScrollableChartDataSource, OMScrollableChartRenderableProtocol, OMScrollableChartRenderableDelegateProtocol, RenderClientProtocol {
    var selectedSegmentIndex: Int = 0 {
        didSet {
            chart.setNeedsLayout()
            chart.setNeedsDisplay()
        }
    }
    var chartPointsRandom: [Float] =  []
    
    // RenderClientProtocol
    
    var opacityTable: [Opacity] = []
    var timingTable: [AnimationTiming] = []
    
    // opacity
    
    var opacityTableLine: [Opacity] = [.hide, .show, .show, .hide, .hide, .show]
    var opacityTableBar: [Opacity]  = [.hide, .hide, .hide, .show, .show, .hide]
    
    // animation timing
    
    var timingTableLines: [AnimationTiming] = [
        .none,
        .none,
        .oneShot,
        .none,
        .none,
        .none
    ]
    var timingTableBar: [AnimationTiming] = [
        .none,
        .none,
        .oneShot,
        .none,
        .none,
        .none
    ]
    
    func queryAnimation(chart: OMScrollableChart, renderIndex: Int) -> AnimationTiming {
        return timingTable[renderIndex]
    }
    func didSelectSection(chart: OMScrollableChart, renderIndex: Int, sectionIndex: Int, layer: CALayer) {
        print("didSelectSection \(renderIndex) section index: \(sectionIndex) name: \(String(describing: layer.name))")
        switch renderIndex {
        case ExampleRendersIdentify.bar1.rawValue:
            break
        case ExampleRendersIdentify.bar2.rawValue:
            break
        case ExampleRendersIdentify.segments.rawValue:
            layer.opacity = 1.0
            break
        default: break
        }
    }
    func didSelectDataIndex(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, layer: CALayer) {
        let index: Int = abs(dataIndex - 1)
        let points = chart.engine.renders[renderIndex].data.points
        print("didSelectDataIndex \(renderIndex) dataIndex: \(dataIndex) name: \(String(describing: layer.name))")
        if points.count <= index {
            print("error render index: \(renderIndex) dataIndex: \(dataIndex) name: \(String(describing: layer.name))")
            return
        }
        
        let previousPoint = points[index]
        let indexOfPOint = chart.indexForPoint(renderIndex, point: previousPoint) ?? 0
        switch renderIndex {
        case RenderIdent.points.rawValue:
            chart.renderSelectedPointsLayer?.position = layer.position // update selection layer.
        case ExampleRendersIdentify.segments.rawValue:
            selectedSegmentIndex = indexOfPOint
        default:
            break
        }
    }
    func animationDidEnded(chart: OMScrollableChart, renderIndex: Int, animation: CAAnimation) {
        switch renderIndex {
        case RenderIdent.selectedPoint.rawValue:
            timingTable[renderIndex] = .none
        case  ExampleRendersIdentify.bar1.rawValue:
            break
        case  ExampleRendersIdentify.bar2.rawValue:
            break
        case  ExampleRendersIdentify.segments.rawValue:
            break
        default:
            break
        }
    }
    let pathRideToPointAnimationDuration: TimeInterval = 5.0
    func animateLayers(chart: OMScrollableChart,
                       renderIndex: Int,
                       layerIndex: Int,
                       layer: GradientShapeLayer) -> CAAnimation? {
        switch renderIndex {
        case RenderIdent.selectedPoint.rawValue:
            guard let polylinePath = chart.polylinePath else {
                return nil
            }
            // last section index
            let sectionIndex = chart.numberOfSections * chart.numberOfPages
            return chart.animateLayerPathRideToPoint( polylinePath,
                                                      layerToRide: layer,
                                                      sectionIndex: sectionIndex,
                                                      duration: pathRideToPointAnimationDuration)
        case  ExampleRendersIdentify.bar1.rawValue:
            let pathStart = pathsToAnimate[renderIndex - RenderIdent.base.rawValue ][layerIndex]
            return chart.perfromAnimateLayerPath( layer,
                                           pathStart: pathStart,
                                           pathEnd: UIBezierPath( cgPath: layer.path!))
        case  ExampleRendersIdentify.bar2.rawValue:
            let pathStart = pathsToAnimate[renderIndex - RenderIdent.base.rawValue][layerIndex]
            return chart.perfromAnimateLayerPath( layer,
                                           pathStart: pathStart,
                                           pathEnd: UIBezierPath( cgPath: layer.path!))
        case  ExampleRendersIdentify.segments.rawValue:
            break
        default:
            return nil
        }
        
        return nil
    }
    var numberOfRenders: Int { 3 + RenderIdent.base.rawValue }
    func dataPoints(chart: OMScrollableChart, renderIndex: Int, section: Int) -> [Float] { chartPointsRandom }
    func dataLayers(chart: OMScrollableChart, renderIndex: Int, section: Int, data: DataRender) -> [GradientShapeLayer] {
        switch renderIndex {
        case  ExampleRendersIdentify.bar1.rawValue:
            let layers =  chart.createRectangleLayers(data.points, columnIndex: 1, count: 6, color: .black)
            layers.forEach({$0.name = "bar income"})  //debug
            let paths = chart.createInverseRectanglePaths(data.points, columnIndex: 1, count: 6)
            self.pathsToAnimate.insert(paths, at: 0)
            return layers
        case  ExampleRendersIdentify.bar2.rawValue:
            let layers =  chart.createRectangleLayers(data.points, columnIndex: 4, count: 6, color: .green)
            layers.forEach({$0.name = "bar outcome"})  //debug
            let paths = chart.createInverseRectanglePaths(data.points, columnIndex: 4, count: 6)
            self.pathsToAnimate.insert(paths, at: 1)
            return layers
        case  ExampleRendersIdentify.segments.rawValue:
            let strokeColor: UIColor = UIColor.crayolaTurquoiseBlueColor
            let fillColor: UIColor = UIColor.greyishBlue
            let gradientColor: UIColor = UIColor.darkGreyBlueTwo
            let layers = chart.createSegmentLayers( chart.lineWidth,
                                                    gradientColor,
                                                    strokeColor.withAlphaComponent(0.88),
                                                    fillColor)
            layers.forEach({$0.name = "line segment"})  //debug
            chart.setNeedsLayout()
            return layers
            
        default: break
        }
        return []
    }
    var segmentLayers: [GradientShapeLayer] = []
    var pathsToAnimate = [[UIBezierPath]]()
    func footerSectionsText(chart: OMScrollableChart) -> [String]? { return nil }
    func dataPointTootipText(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, section: Int) -> String? { return nil }
    func dataOfRender(chart: OMScrollableChart, renderIndex: Int) -> RenderDataType { return renderType }
    func dataSectionForIndex(chart: OMScrollableChart, dataIndex: Int, section: Int) -> String? { nil }
    func zPositionForLayer(chart: OMScrollableChart, renderIndex: Int, layer: GradientShapeLayer) -> CGFloat? {
        // the last render at top
        return CGFloat(chart.engine.renders.count - renderIndex)
    }
    func renderOpacity(chart: OMScrollableChart, renderIndex: Int) -> CGFloat {
        opacityTable[renderIndex].rawValue
    }

    func updateSelectedSegmentedOpacity( layer: GradientShapeLayer) -> CGFloat {
        if let path = layer.path {
            let points = Path(cgPath: path).destinationPoints()
            let stroker = LayerStroker(layer: layer, points: points)
            layer.opacity = 1.0
            chart.layersToStroke.append(stroker)
            chart.setNeedsLayout()
            chart.setNeedsDisplay()
            // show it
            return Opacity.show.rawValue
        }
        return Opacity.hide.rawValue
    }
    /// layerOpacityForSegmentRender
    /// - Parameters:
    ///   - renderIndex: renderIndex
    ///   - layer: GradientShapeLayer
    ///   - chart: chart description
    /// - Returns: CGFloat
    private func layerOpacityForSegmentRender( _ chart: OMScrollableChart, _ renderIndex: Int, _ layer: GradientShapeLayer) -> CGFloat? {
        let renders = chart.engine.renders[renderIndex]
        let contains: Bool = renders.layers.contains(layer)
        print("[HHS] render: \(renderIndex) contains: \(contains), layer: \(String(describing: layer.name)) ")
        let indexOfLayer = renders.layers.index(of: layer)
        print("[HHS] layerOpacity for render: \(renderIndex) layer: \(String(describing: layer.name)) #\(indexOfLayer ?? 0) selected: \(selectedSegmentIndex)")
        if let indexOfLayer = indexOfLayer {
            if indexOfLayer == selectedSegmentIndex {
                return updateSelectedSegmentedOpacity(layer: layer)
            }
        } else {
            print("Index not found for layer \(String(describing: layer.name))")
        }
        // Hide it
        return nil
    }
    /// renderLayerOpacity
    /// - Parameters:
    ///   - chart: chart description
    ///   - renderIndex: renderIndex description
    ///   - layer: layer description
    /// - Returns: description
    func renderLayerOpacity(chart: OMScrollableChart, renderIndex: Int, layer: GradientShapeLayer) -> CGFloat? {
        switch renderIndex {
        case 0,1,2,3,4: break
        case ExampleRendersIdentify.segments.rawValue:
            let opacity = layerOpacityForSegmentRender(chart, renderIndex, layer)
            return opacity
        default: break
        }
        return nil
    }
    func numberOfPages(chart: OMScrollableChart) -> Int {
        return 8
    }
    func numberOfSectionsPerPage(chart: OMScrollableChart) -> Int {
        return 6
    }
    @IBOutlet var toleranceSlider: UISlider!
    @IBOutlet var sliderLimit: UISlider!
    @IBOutlet var chart: OMScrollableChart!
    @IBOutlet var segmentInterpolation: UISegmentedControl!
    @IBOutlet var segmentTypeOfData: UISegmentedControl!
    @IBOutlet var segmentTypeOfSimplify: UISegmentedControl!
    @IBOutlet var sliderAverage: UISlider!
    
    @IBOutlet var label1: UILabel!
    @IBOutlet var label2: UILabel!
    @IBOutlet var label3: UILabel!
    @IBOutlet var label4: UILabel!
    @IBOutlet var label5: UILabel!
    @IBOutlet var label6: UILabel!
     

    deinit {
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        chart.bounces = false
        chart.dataSource = self
        chart.renderSource = self
        chart.renderDelegate  = self
        chart.backgroundColor = .clear
        chart.isPagingEnabled = false
        
        chart.renderManagerClass = ExampleRenderManager.self
        
        opacityTable = opacityTableLine
        timingTable  = timingTableLines
        
        
        segmentInterpolation.removeAllSegments()
        segmentInterpolation.insertSegment(withTitle: "none", at: 0, animated: false)
        segmentInterpolation.insertSegment(withTitle: "smoothed", at: 1, animated: false)
        segmentInterpolation.insertSegment(withTitle: "cubicCurve", at: 2, animated: false)
        segmentInterpolation.insertSegment(withTitle: "hermite", at: 3, animated: false)
        segmentInterpolation.insertSegment(withTitle: "catmullRom", at: 4, animated: false)
        segmentInterpolation.selectedSegmentIndex = 4 // catmullRom
        
        segmentTypeOfData.removeAllSegments()
        segmentTypeOfData.insertSegment(withTitle: "discrete", at: 0, animated: false)
        segmentTypeOfData.insertSegment(withTitle: "mean", at: 1, animated: false)
        segmentTypeOfData.insertSegment(withTitle: "simplify", at: 2, animated: false)
        segmentTypeOfData.insertSegment(withTitle: "regression", at: 3, animated: false)
        segmentTypeOfData.selectedSegmentIndex = 0 // discrete
        
        segmentTypeOfSimplify.removeAllSegments()
        segmentTypeOfSimplify.insertSegment(withTitle: "DP radial", at: 0, animated: false)
        segmentTypeOfSimplify.insertSegment(withTitle: "DP decimation", at: 1, animated: false)
        segmentTypeOfSimplify.insertSegment(withTitle: "DP perm", at: 2, animated: false)
        segmentTypeOfSimplify.insertSegment(withTitle: "Visvalingam", at: 3, animated: false)
        segmentTypeOfSimplify.selectedSegmentIndex = 0 // radial
        
        chartPointsRandom = randomFloat(100, max: 50000, min: -50)
        
        toleranceSlider.maximumValue  = 100
        toleranceSlider.minimumValue  = 1
        toleranceSlider.value        = Float(self.chart.approximationTolerance)
        
        sliderAverage.maximumValue = Float(chartPointsRandom.count)
        sliderAverage.minimumValue = 0
        sliderAverage.value       = Float(self.chart.numberOfElementsToMean)
        
        _ = chart.updateDataSourceData()
        
        scaledPointsGenerator = DiscreteScaledPointsGenerator(data: chartPointsRandom)
        
        sliderLimit.maximumValue  = scaledPointsGenerator?.maximumValue ?? 0
        sliderLimit.minimumValue  = scaledPointsGenerator?.minimumValue ?? 0
        
        label1.text = "\(roundf(sliderLimit.minimumValue))"
        label2.text = "\(roundf(sliderLimit.maximumValue))"
        label3.text = "\(roundf(sliderAverage.minimumValue))"
        label4.text = "\(roundf(sliderAverage.maximumValue))"
        label5.text = "\(roundf(toleranceSlider.minimumValue))"
        label6.text = "\(roundf(toleranceSlider.maximumValue))"
    }
    var scaledPointsGenerator: DiscreteScaledPointsGenerator?
    @IBAction  func limitsSliderChange( _ sender: UISlider)  {
        if sender == sliderLimit {
            //scaledPointsGenerator?.minimum = Float(CGFloat(sliderLimit.value))
            _ = chart.updateDataSourceData()
            label1.text = "\(roundf(sender.value))"
        }
    }
    @IBAction  func simplifySliderChange( _ sender: UISlider)  {
        let value = sender.value
        let text  = "\(roundf(sender.value))"
        if sender == sliderAverage {
            if self.chart.numberOfElementsToMean != CGFloat(value) {
                self.chart.numberOfElementsToMean = CGFloat(value)
                label3.text = text
            }
        } else {
            if self.chart.approximationTolerance != CGFloat(value) {
                self.chart.approximationTolerance = CGFloat(value)
                label5.text = text
            }
        }
        typeOfDataSegmentChange(sender)
    }
    @IBAction  func simplifySegmentChange( _ sender: Any)  {
        var simplifyType: SimplifyType = .none
        let index = self.segmentTypeOfSimplify.selectedSegmentIndex
        if index >= 0 {
            switch index {
            case 0:
                simplifyType = .douglasPeuckerRadial
            case 1:
                simplifyType = .douglasPeuckerDecimate
            case 2:
                simplifyType = .ramerDouglasPeuckerPerp
            case 3:
                simplifyType = .visvalingam
            default:
                simplifyType = .none
            }
        }
        let value = self.toleranceSlider.value
        renderType = .simplify(simplifyType, CGFloat(value))
    }
    
    @IBAction  func interpolationSegmentChange( _ sender: Any)  {
        switch segmentInterpolation.selectedSegmentIndex  {
        case 0:
            chart.polylineInterpolation = .none
        case 1:
            chart.polylineInterpolation = .smoothed
        case 2:
            chart.polylineInterpolation = .cubicCurve
        case 3:
            chart.polylineInterpolation = .hermite(0.5)
        case 4:
            chart.polylineInterpolation = .catmullRom(0.5)
        default:
            assert(false)
        }
    }
    var renderType: RenderDataType = .discrete
    @IBAction  func typeOfDataSegmentChange( _ sender: Any)  {
        switch segmentTypeOfData.selectedSegmentIndex  {
        case 0: renderType = .discrete
        case 1:
            let value = CGFloat(self.sliderAverage.value)
            renderType = .stadistics(value)
        case 2:
            var simplifyType: SimplifyType = .none
            let index = self.segmentTypeOfSimplify.selectedSegmentIndex
            if index >= 0 {
                switch index {
                case 0: simplifyType = .douglasPeuckerRadial
                case 1: simplifyType = .douglasPeuckerDecimate
                case 2: simplifyType = .ramerDouglasPeuckerPerp
                case 3: simplifyType = .visvalingam
                default: simplifyType = .none
                }
            }
            renderType = .simplify(simplifyType, CGFloat(self.toleranceSlider.value))
        case 3:
            renderType = .regress(Int(1))
        default:
            assert(false)
        }
        chart.forceLayoutReload()
    }
}
