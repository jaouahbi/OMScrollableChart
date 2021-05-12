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

let chartPoints: [Float] =   [1510, 100,
                              3000, 100,
                              1200, 13000,
                             15000, -1500,
                             800, 1000,
                             6000, 1300]


class ViewController: UIViewController, OMScrollableChartDataSource, OMScrollableChartRenderableProtocol, OMScrollableChartRenderableDelegateProtocol {
    
    var animationTimingTable: [AnimationTiming] = [
        .none,
        .none,
        .oneShot,
        .none,
        .none,
        .none,
        .none
    ]
    func queryAnimation(chart: OMScrollableChart, renderIndex: Int) -> AnimationTiming {
        return animationTimingTable[renderIndex]
    }
    func didSelectDataIndex(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, layer: CALayer) {
        switch renderIndex {
        case 0:break
        case 1: chart.renderSelectedPointsLayer?.position =  layer.position
        case 2:break
        case 3:break
        case 4:break
        default: break
        }
    }
    func animationDidEnded(chart: OMScrollableChart, renderIndex: Int, animation: CAAnimation) {
        switch renderIndex {
        case 0: break
        case 1: break
        case 2: animationTimingTable[renderIndex] = .none
        case 3: break
        case 4: break
        default: break
        }
    }
    func animateLayers(chart: OMScrollableChart,
                       renderIndex: Int,
                       layerIndex: Int,
                       layer: OMGradientShapeClipLayer) -> CAAnimation? {
        switch OMScrollableChart.Renders(rawValue: renderIndex) {
        case .points, .selectedPoint, .currentPoint, .segments:
            return nil
        case .polyline:
            guard let polylinePath = chart.polylinePath else {
                return nil
            }
            return chart.animateLayerPathRideToPoint( polylinePath,
                                                      layerToRide: layer,
                                                      pointIndex: chart.numberOfSections,
                                                      duration: 10)
            
        case .bar1:
            let pathStart = pathsToAnimate[renderIndex - 3][layerIndex]
            return chart.animateLayerPath( layer,
                                           pathStart: pathStart,
                                           pathEnd: UIBezierPath( cgPath: layer.path!))
        case .bar2:
            let pathStart = pathsToAnimate[renderIndex - 3][layerIndex]
            return chart.animateLayerPath( layer,
                                           pathStart: pathStart,
                                           pathEnd: UIBezierPath( cgPath: layer.path!) )
            
        default:
            return nil
        }
    }
    var numberOfRenders: Int {
        return OMScrollableChart.Renders.base.rawValue
    }
    func dataPoints(chart: OMScrollableChart, renderIndex: Int, section: Int) -> [Float] {
        return chartPoints
    }
    func dataLayers(chart: OMScrollableChart, renderIndex: Int, section: Int, points: [CGPoint]) -> [OMGradientShapeClipLayer] {
        switch OMScrollableChart.Renders(rawValue:  renderIndex) {
//        case 0:
//            let layers = chart.updatePolylineLayer(lineWidth: 4,
//                                                   color: .greyishBlue)
//            layers.forEach({$0.name = "polyline"}) //debug
//            return layers
//        case 1:
//            let layers = chart.createPointsLayers(points,
//                                                  size: CGSize(width: 8, height: 8),
//                                                  color: .greyishBlue)
//            layers.forEach({$0.name = "point"})  //debug
//            return layers
//        case 2:
////            if let point = chart.maxPoint(renderIndex: renderIndex) {
////                let layer = chart.createPointLayer(point,
////                                                   size: CGSize(width: 12, height: 12),
////                                                   color: .darkGreyBlueTwo)
////                layer.name = "selectedPoint"  //debug
////                return [layer]
////            }
////            return []
//            return []
        case .bar1:
            let layers =  chart.createRectangleLayers(points, columnIndex: 1, count: 6,
                                                      color: .black)
            layers.forEach({$0.name = "bar income"})  //debug
            self.pathsToAnimate.insert(
                chart.createInverseRectanglePaths(points, columnIndex: 1, count: 6),
                at: 0)
            return layers
        case .bar2:
            
            let layers =  chart.createRectangleLayers(points, columnIndex: 4, count: 6,
                                                      color: .green)
            layers.forEach({$0.name = "bar outcome"})  //debug
            self.pathsToAnimate.insert(
                chart.createInverseRectanglePaths(points, columnIndex: 4, count: 6),
                at: 1)
            return layers
            
        default:
            return []
        }
    }
    var pathsToAnimate = [[UIBezierPath]]()
    func footerSectionsText(chart: OMScrollableChart) -> [String]? {
        return nil
    }
    func dataPointTootipText(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, section: Int) -> String? {
        return nil
    }
    func dataOfRender(chart: OMScrollableChart, renderIndex: Int) -> OMScrollableChart.RenderType {
        return renderType
    }
    func dataSectionForIndex(chart: OMScrollableChart, dataIndex: Int, section: Int) -> String? {
        return nil
    }
    func layerOpacity(chart: OMScrollableChart, renderIndex: Int) -> CGFloat {
        return curOpacityTable[renderIndex]
    }
    func numberOfPages(chart: OMScrollableChart) -> CGFloat {
        return 2
    }
    func numberOfSectionsPerPage(chart: OMScrollableChart) -> Int {
        return 6
    }
    var opacityTableLine: [CGFloat] = [1, 1, 1, 1, 1, 0, 0]
    var opacityTableBar: [CGFloat]  = [0, 0, 0, 0, 0, 1, 1]
    var curOpacityTable: [CGFloat]  = []
    @IBOutlet var toleranceSlider: UISlider!
    @IBOutlet var sliderLimit: UISlider!
    @IBOutlet var chart: OMScrollableChart!
    @IBOutlet var segmentInterpolation: UISegmentedControl!
    @IBOutlet var segmentTypeOfData: UISegmentedControl!
    @IBOutlet var sliderAverage: UISlider!
    
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
        curOpacityTable = opacityTableLine
        
        segmentInterpolation.removeAllSegments()
        segmentInterpolation.insertSegment(withTitle: "none", at: 0, animated: false)
        segmentInterpolation.insertSegment(withTitle: "smoothed", at: 1, animated: false)
        segmentInterpolation.insertSegment(withTitle: "cubicCurve", at: 2, animated: false)
        segmentInterpolation.insertSegment(withTitle: "hermite", at: 3, animated: false)
        segmentInterpolation.insertSegment(withTitle: "catmullRom", at: 4, animated: false)
        segmentInterpolation.selectedSegmentIndex = 4 // catmullRom

        
        segmentTypeOfData.removeAllSegments()
        segmentTypeOfData.insertSegment(withTitle: "discrete", at: 0, animated: false)
        segmentTypeOfData.insertSegment(withTitle: "averaged", at: 1, animated: false)
        segmentTypeOfData.insertSegment(withTitle: "simplify", at: 2, animated: false)
        segmentTypeOfData.insertSegment(withTitle: "regression", at: 3, animated: false)
        segmentTypeOfData.selectedSegmentIndex = 0 // catmullRom
        
        toleranceSlider.maximumValue  = 20
        toleranceSlider.minimumValue  = 1
        toleranceSlider.value        = Float(self.chart.approximationTolerance)
        sliderAverage.maximumValue    = Float(chartPoints.count)
        sliderAverage.minimumValue    = 0
        sliderAverage.value = Float(self.chart.numberOfElementsToAverage)
        
        _ = chart.updateDataSourceData()
        
        let scaledPointsGenerator = chart.scaledPointsGenerator[0]
        
        sliderLimit.maximumValue  = scaledPointsGenerator.maximumValue
        sliderLimit.minimumValue  = scaledPointsGenerator.minimumValue
        
    }
    @IBAction  func limitsSliderChange( _ sender: UISlider)  {
        if sender == sliderLimit {
            let generator = chart.scaledPointsGenerator.first
            generator?.minimum =  Float(CGFloat(sliderLimit.value))
            _ = chart.updateDataSourceData()
        }
    }
    @IBAction  func simplifySliderChange( _ sender: UISlider)  {
        if sender == sliderAverage {
            self.chart.numberOfElementsToAverage = Int(sliderAverage.value)
        } else {
            self.chart.approximationTolerance = CGFloat(toleranceSlider.value)
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
        case 0: renderType = .discrete
        case 1: renderType = .averaged(2)
        case 2: renderType = .approximation(0.5)
        case 3: renderType = .linregress(Int(1))
        default:
            assert(false)
        }
        chart.forceLayoutReload()
    }
}
