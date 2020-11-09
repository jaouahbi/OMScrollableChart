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
//let chartPoints: [Float] =   [110, 10, 30, 10, 10, 30,
//    150, -150, 80, -40, 60, 10,110, 10, 30, 10, 10, 30,
//    150, -150, 80, -40, 60, 10,110, 10, 30, 10, 10, 30,
//    150, -150, 80, -40, 60, 10,110, 10, 30, 10, 10, 30,
//    150, -150, 80, -40, 60, 10,110, 10, 30, 10, 10, 30,
//    150, -150, 80, -40, 60, 10,110, 10, 30, 10, 10, 30,
//    150, -150, 80, -40, 60, 10]
//             1510, 100, 3000, 100, 1200, 13000,
//15000, -1500, 800, 1000, 6000, 1300]


class ViewController: UIViewController, OMScrollableChartDataSource, OMScrollableChartRenderableProtocol, OMScrollableChartRenderableDelegateProtocol {
    var selectedSegmentIndex: Int = 0
    var chartPointsRandom: [Float] =  []
    var animationTimingTable: [AnimationTiming] = [
        .none,
        .none,
        .oneShot,
        .none,
        .none,
        .none
    ]
    func queryAnimation(chart: OMScrollableChart, renderIndex: Int) -> AnimationTiming {
        return animationTimingTable[renderIndex]
    }
    func didSelectSection(chart: OMScrollableChart, renderIndex: Int, sectionIndex: Int, layer: CALayer) {
        switch renderIndex {
        case 0:break
        case 1:break
        case 2:break
        case 3:break
        case 4:break
        default: break
        }
    }
    func didSelectDataIndex(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, layer: CALayer) {
        switch renderIndex {
        case OMScrollableChart.Renders.points.rawValue:
            chart.renderSelectedPointsLayer?.position = layer.position
            let previousPoint = chart.pointsRender[renderIndex][abs(dataIndex - 1)]
            selectedSegmentIndex = chart.indexForPoint(previousPoint, renderIndex: renderIndex) ?? 0
            chart.setNeedsLayout()
            chart.setNeedsDisplay()
        default:
            break
        }
    }
    func animationDidEnded(chart: OMScrollableChart, renderIndex: Int, animation: CAAnimation) {
        switch renderIndex {
        case 0:
            break
        case 1:
            break
        case 2:
            animationTimingTable[renderIndex] = .none
        case 3:
            break
        case 4:
            break
        default:
            break
        }
    }
    func animateLayers(chart: OMScrollableChart,
                       renderIndex: Int,
                       layerIndex: Int,
                       layer: OMGradientShapeClipLayer) -> CAAnimation? {
        switch renderIndex {
        case 0, 1: return nil
        case 2:
            guard let polylinePath = chart.polylinePath else {
                return nil
            }
            let animationDuration: TimeInterval = 5.0
            let sectionIndex = chart.numberOfSections / Int(chart.numberOfPages)
            return chart.animateLayerPathRideToPoint( polylinePath,
                                                      layerToRide: layer,
                                                      sectionIndex: sectionIndex,
                                                      duration: animationDuration)
        case 3:
            let pathStart = pathsToAnimate[renderIndex - OMScrollableChart.Renders.base.rawValue ][layerIndex]
            return chart.animateLayerPath( layer,
                                           pathStart: pathStart,
                                           pathEnd: UIBezierPath( cgPath: layer.path!))
        case 4:
            let pathStart = pathsToAnimate[renderIndex - OMScrollableChart.Renders.base.rawValue][layerIndex]
            return chart.animateLayerPath( layer,
                                           pathStart: pathStart,
                                           pathEnd: UIBezierPath( cgPath: layer.path!))
        case 5: return nil
        default:
            return nil
        }
    }
    var numberOfRenders: Int { 3 + OMScrollableChart.Renders.base.rawValue }
    func dataPoints(chart: OMScrollableChart, renderIndex: Int, section: Int) -> [Float] { chartPointsRandom }
    
    func dataLayers(chart: OMScrollableChart, renderIndex: Int, section: Int, points: [CGPoint]) -> [OMGradientShapeClipLayer] {
        switch renderIndex {
        case 3:
            let layers =  chart.createRectangleLayers(points, columnIndex: 1, count: 6, color: .black)
            layers.forEach({$0.name = "bar income"})  //debug
            let paths = chart.createInverseRectanglePaths(points, columnIndex: 1, count: 6)
            self.pathsToAnimate.insert(paths, at: 0)
            return layers
        case 4:
            let layers =  chart.createRectangleLayers(points, columnIndex: 4, count: 6, color: .green)
            layers.forEach({$0.name = "bar outcome"})  //debug
            let paths = chart.createInverseRectanglePaths(points, columnIndex: 4, count: 6)
            self.pathsToAnimate.insert(paths, at: 1)
            return layers
        case 5:
            let path = Path(cgPath: chart.polylinePath!.cgPath)
            let paths = path.pathsFromElements()
            let layers = chart.createSegmentLayers(paths,
                                                   lineWidth: 2.0,
                                                   color: .init(white: 0.78, alpha: 0.7),
                                                   strokeColor: UIColor.purple.withAlphaComponent(0.9))
            layers.forEach({$0.name = "line segment"})  //debug
            return layers
        default:
            return []
        }
    }
    var pathsToAnimate = [[UIBezierPath]]()
    func footerSectionsText(chart: OMScrollableChart) -> [String]? { return nil }
    func dataPointTootipText(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, section: Int) -> String? { return nil }
    func dataOfRender(chart: OMScrollableChart, renderIndex: Int) -> OMScrollableChart.RenderType { return renderType }
    func dataSectionForIndex(chart: OMScrollableChart, dataIndex: Int, section: Int) -> String? { return nil }
    func layerRenderOpacity(chart: OMScrollableChart, renderIndex: Int) -> CGFloat { currentOpacityTable[renderIndex].rawValue }
    func layerOpacity(chart: OMScrollableChart, renderIndex: Int, layer: OMGradientShapeClipLayer) -> CGFloat {
        switch renderIndex {
        case 0:break
        case 1:break
        case 2:break
        case 3:break
        case 4:break
        case 5:
            let indexOfLayer = chart.renderLayers[renderIndex].index(of: layer)
            //print("indexOfLayer", indexOfLayer)
            if let indexOfLayer = indexOfLayer, indexOfLayer == selectedSegmentIndex, let path = layer.path {
                let path = Path(cgPath: path)
                var lastPoint = CGPoint.zero
                var points = [CGPoint]()
                for ele in path.elements {
                    switch ele {
                    case .moveToPoint(point: let point):
                        lastPoint = point
                    case .addLineToPoint(point: let point):
                        lastPoint = point
                    case .addQuadCurveToPoint(destination: let destination, control: _):
                        //let pt1 = Path.pointOfQuad(t: 1.0, from: lastPoint, to: destination, c: control)
                        lastPoint = destination
                    case .addCurveToPoint(destination: let destination, control1: _, control2: _):
                        //let pt2 = Path.pointOfCubic(t: 1.0, from: lastPoint, to: destination, c1: control1, c2: control2)
                        lastPoint = destination
                    case .closeSubpathWithLine: break
                    }
                    points.append(lastPoint)
                }
                chart.layersToStroke.append((layer, points))
                return 1.0
            } else {
                return 0
            }
        default: break
        }
        return currentOpacityTable[renderIndex].rawValue
    }
    func numberOfPages(chart: OMScrollableChart) -> CGFloat {
        return 2
    }
    func numberOfSectionsPerPage(chart: OMScrollableChart) -> Int {
        return 6
    }
    var opacityTableLine: [OMScrollableChart.Opacity] = [.show, .show, .show, .hide, .hide, .show]
    var opacityTableBar: [OMScrollableChart.Opacity]  = [.hide, .hide, .hide, .show, .show, .hide]
    var currentOpacityTable: [OMScrollableChart.Opacity]  = []
    
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
        chart.isPagingEnabled = true
        currentOpacityTable = opacityTableLine
        
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
        segmentTypeOfSimplify.insertSegment(withTitle: "Visvalingam", at: 2, animated: false)
        segmentTypeOfSimplify.selectedSegmentIndex = 0 // discrete
        
        chartPointsRandom = randomFloat(32, max: 50000, min: -50)
        
        toleranceSlider.maximumValue  = 100
        toleranceSlider.minimumValue  = 1
        toleranceSlider.value        = Float(self.chart.approximationTolerance)
        
        sliderAverage.maximumValue = Float(chartPointsRandom.count)
        sliderAverage.minimumValue = 0
        sliderAverage.value       = Float(self.chart.numberOfElementsToMean)
        
        _ = chart.updateDataSourceData()
        
        let scaledPointsGenerator = chart.scaledPointsGenerator[0]
        
        sliderLimit.maximumValue  = scaledPointsGenerator.maximumValue
        sliderLimit.minimumValue  = scaledPointsGenerator.minimumValue
        
        label1.text = "\(roundf(sliderLimit.minimumValue))"
        label2.text = "\(roundf(sliderLimit.maximumValue))"
        label3.text = "\(roundf(sliderAverage.minimumValue))"
        label4.text = "\(roundf(sliderAverage.maximumValue))"
        label5.text = "\(roundf(toleranceSlider.minimumValue))"
        label6.text = "\(roundf(toleranceSlider.maximumValue))"
        
    }
    @IBAction  func limitsSliderChange( _ sender: UISlider)  {
        if sender == sliderLimit {
            let generator = chart.scaledPointsGenerator.first
            generator?.minimum = Float(CGFloat(sliderLimit.value))
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
    }
    @IBAction  func simplifySegmentChange( _ sender: Any)  {
        let index = segmentTypeOfSimplify.selectedSegmentIndex
        if index >= 0 {
            switch index {
            case 0:
                chart.approximationType = .douglasPeuckerRadial
            case 1:
                chart.approximationType = .douglasPeuckerDecimate
            case 2:
                chart.approximationType = .visvalingam
            default:
                chart.approximationType = .none
            }
        }
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
    var renderType: OMScrollableChart.RenderType = .discrete
    @IBAction  func typeOfDataSegmentChange( _ sender: Any)  {
        switch segmentTypeOfData.selectedSegmentIndex  {
        case 0:
            renderType = .discrete
        case 1:
            renderType = .mean(Int(self.sliderAverage.value))
        case 2:
            renderType = .approximation(CGFloat(self.toleranceSlider.value))
        case 3:
            renderType = .linregress(Int(1))
        default:
            assert(false)
        }
        chart.forceLayoutReload()
    }
}
