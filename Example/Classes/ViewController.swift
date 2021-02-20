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


public enum RenderPosition: Int {
    case zPositionTop = 1
    case zPositionReserved = 10
}

class ViewController: UIViewController,
                      OMScrollableChartDataSource,
                      OMScrollableChartRenderableDelegateProtocol,
                      RenderClientProtocol {


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
    
    /// for_each_layer_in_section
    /// - Parameters:
    ///   - renderIndex: renderIndex description
    ///   - layer: layer description
    ///   - completion: completion description
    func for_each_layer_in_section(_ renderIndex: Int,
                                   _ layer: CALayer,
                                   _ completion: ((CALayer) -> Void)?) {

        let render = RenderManager.shared.renders[renderIndex]
        for_each_layer_in_section(chart,
                                  render,
                                  layer,
                                  chart.numberOfSections,
                                  completion)
    }
    
    /// for_each_layer_in_section
    /// - Parameters:
    ///   - chart: chart description
    ///   - render: render description
    ///   - layer: layer description
    ///   - numberOfSections: numberOfSections description
    ///   - completion: completion description
    func for_each_layer_in_section(_ chart: OMScrollableChart,
                                   _ render: BaseRender,
                                   _ layer: CALayer,
                                   _ numberOfSections: Int,
                                   _ completion: ((CALayer) -> Void)?) {

        let selectedSectionIndex = render.sectionIndex(withPoint: layer.position,
                                                       numberOfSections: numberOfSections)
        render.layers.forEach {
            let index = render.sectionIndex(withPoint:  $0.position,
                                            numberOfSections: numberOfSections)
            if index == selectedSectionIndex {
                completion?($0)
            }
        }
    }
    
    /// didChangeSection
    /// - Parameters:
    ///   - chart: chart description
    ///   - renderIndex: renderIndex description
    ///   - sectionIndex: sectionIndex description
    ///   - layer: layer description
    func didChangeSection(chart: OMScrollableChart,
                          renderIndex: Int,
                          sectionIndex: Int,
                          layer: CALayer) {
        
        for_each_layer_in_section(renderIndex, layer) {
            $0.glowLayer(withColor: ScrollableChartColorConfiguration.glowColor,
                         withEffect: .normal)
            
        }
    }
    
//    private func renderLayerSelected(_ chart: OMScrollableChart, _ layer: CALayer, _ renderIndex: Int) {
//
//        // update segments layers.
//
//        if let result =
//            chart
//            .engine
//            .renders[renderIndex]
//            .locationToLayer(layer.position, mostNearLayer: true) {
//
//            self.selected?.removeAllAnimations()
//            self.selected?.removeFromSuperlayer()
//
//            chart.rootRenderLayer.addSublayer(result)
//            self.selected = result
//
//            result.opacity = 1.0
//
//            prepareSelectedLayerMask(renderIndex, result)
//        }
//    }
    
    func didSelectDataIndex(chart: OMScrollableChart,
                            renderIndex: Int,
                            dataIndex: Int,
                            layer: CALayer) {
        
        let index: Int = abs(dataIndex - 1)
        let points = chart.engine.renders[renderIndex].data.points
//        print("didSelectDataIndex render index: \(renderIndex) dataIndex: \(dataIndex) name: \(String(describing: layer.name))")
        if points.count <= index {
//            print("error render index: \(renderIndex) dataIndex: \(dataIndex) name: \(String(describing: layer.name))")
            return
        }
        
//        let previousPoint = points[index]
//        let indexOfPOint = chart.indexForPoint(renderIndex, point: previousPoint) ?? 0
        
        switch renderIndex {
            case RenderIdent.points.rawValue:
                // update selection point layer.
                chart.renderSelectedPointsLayer?.position = layer.position
        case RenderIdent.segments.rawValue:
            layer.glowLayer(withColor: ScrollableChartColorConfiguration.selectedPointColor,
                         withEffect: .regular)
            default:
                break
        }
        
//           if let result =
//               chart
//               .engine
//               .renders[renderIndex]
//               .locationToLayer(layer.position, mostNearLayer: true) {
//            print(result.opacity, result.superlayer)
//           }
        
            
//        renderLayerSelected(chart,
//                            layer,
//                            renderIndex)
            

            
//        case ExampleRendersIdentify.segments.rawValue:
//            prepareSelectedLayerMask(renderIndex, layer, previousPoint, indexOfPOint)

    }
//    var selected: ShapeLayer?
    func animationDidEnded(chart: OMScrollableChart, renderIndex: Int, animation: CAAnimation) {
        switch renderIndex {
        case RenderIdent.polyline.rawValue:
            break
        case RenderIdent.points.rawValue:
            break
        case RenderIdent.selectedPoint.rawValue:
            timingTable[renderIndex] = .none
        case  RenderIdent.bar1.rawValue:
            break
        case  RenderIdent.bar2.rawValue:
            break
        case  RenderIdent.segments.rawValue:
            break
        default:
            break
        }
    }

    func animateLayers(chart: OMScrollableChart,
                       renderIndex: Int,
                       layerIndex: Int,
                       layer: GradientShapeLayer) -> CAAnimation? {
        switch renderIndex {
        case RenderIdent.polyline.rawValue:
            break
        case RenderIdent.points.rawValue:
            break
        case RenderIdent.selectedPoint.rawValue:
            guard let polylinePath = chart.polylinePath else {
                return nil
            }
            //
            // Animate until last section index
            //
            
            let duration = chart.animations.pathRideToPointAnimationDuration
            let sectionIndex = chart.numberOfSections * chart.numberOfPages
            return chart.animateLayerPathRideToPoint( polylinePath,
                                                      layerToRide: layer,
                                                      sectionIndex: sectionIndex,
                                                      duration: duration)
        case  RenderIdent.bar1.rawValue:
            let pathStart = pathsToAnimate[renderIndex - RenderIdent.base.rawValue ][layerIndex]
            return chart.animateLayerPath( layer,
                                           pathStart: pathStart,
                                           pathEnd: UIBezierPath( cgPath: layer.path!))
        case  RenderIdent.bar2.rawValue:
            let pathStart = pathsToAnimate[renderIndex - RenderIdent.base.rawValue][layerIndex]
            return chart.animateLayerPath( layer,
                                           pathStart: pathStart,
                                           pathEnd: UIBezierPath( cgPath: layer.path!))
        case  RenderIdent.segments.rawValue:
            break
        default:
            return nil
        }
        
        return nil
    }
   
    func dataPoints(chart: OMScrollableChart, renderIndex: Int, section: Int) -> [Float] { chartPointsRandom }
    func dataLayers(chart: OMScrollableChart, renderIndex: Int, section: Int, data: RenderData) -> [GradientShapeLayer] {
        switch renderIndex {
        case RenderIdent.polyline.rawValue:
            break
        case RenderIdent.points.rawValue:
            break
        case  RenderIdent.bar1.rawValue:
            let layers =  chart.createRectangleLayers(data.points, columnIndex: 1, count: 6, color: .black)
            layers.enumerated().forEach({$1.name = "bar income \($0)"})  //debug
            let paths = chart.createInverseRectanglePaths(data.points, columnIndex: 1, count: 6)
            self.pathsToAnimate.insert(paths, at: 0)
            return layers
        case  RenderIdent.bar2.rawValue:
            let layers =  chart.createRectangleLayers(data.points, columnIndex: 4, count: 6, color: .green)
            layers.enumerated().forEach({$1.name = "bar outcome \($0)"})  //debug
            let paths = chart.createInverseRectanglePaths(data.points, columnIndex: 4, count: 6)
            self.pathsToAnimate.insert(paths, at: 1)
            return layers
        case  RenderIdent.segments.rawValue:
            let layers = chart.createSegmentLayers( chart.lineWidth,
                                                    ScrollableChartColorConfiguration.gradientColor,
                                                    ScrollableChartColorConfiguration.strokeColor,
                                                    ScrollableChartColorConfiguration.fillColor)
            layers.enumerated().forEach({$1.name = "line segment \($0)"})  //debug
            return layers
            
        default: break
        }
        return []
    }
    var segmentLayers: [GradientShapeLayer] = []
    var pathsToAnimate = [[UIBezierPath]]()
    func footerSectionsText(chart: OMScrollableChart) -> [String]? { return nil }
    func dataPointTootipText(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, section: Int) -> String? { return nil }
    func dataOfRender(chart: OMScrollableChart, renderIndex: Int) -> RenderType { return renderType }
    func dataSectionForIndex(chart: OMScrollableChart, dataIndex: Int, section: Int) -> String? { nil }
    
    func zPositionForLayer(chart: OMScrollableChart, renderIndex: Int, layer: GradientShapeLayer) -> CGFloat? {
        // the last render at top
        return nil // CGFloat(RenderPosition.zPositionReserved.rawValue) + CGFloat(renderIndex)
    }
    func renderOpacity(chart: OMScrollableChart, renderIndex: Int) -> CGFloat {
        opacityTable[renderIndex].rawValue
    }

    /// prepareSelectedLayerMask
    /// - Parameters:
    ///   - renderIndex: index
    ///   - layer: ShapeLayer
//    func prepareSelectedLayerMask(_ renderIndex: Int,_ layer: GradientShapeLayer?) {
//        if let layer = layer,
//           let path = layer.path {
//            let points = Path(cgPath: path).destinationPoints()
//
//            configureSelectedLayer( layer: layer, points: points)
//            renderSelectedLayer(layer: layer, points: points)
//
//            chart.strokeGradient(ctx: UIGraphicsGetCurrentContext(),
//                           layer: layer,
//                           points: points,
//                           color: UIColor.greenSea,
//                           lowColor: UIColor.greenSea.complementaryColor,
//                           lineWidth: 1.0,
//                           fadeFactor: 0.8)
//        }
//
//        chart.setNeedsLayout()
//        chart.setNeedsDisplay()
//    }

    
    /// layerOpacityForSegmentRender
    /// - Parameters:
    ///   - renderIndex: renderIndex
    ///   - layer: GradientShapeLayer
    ///   - chart: chart description
    /// - Returns: CGFloat
    private func layerOpacityForSegmentRender( _ chart: OMScrollableChart,
                                               _ renderIndex: Int,
                                               _ layer: GradientShapeLayer) -> CGFloat? {
        let render = chart.engine.renders[renderIndex]
        let contains: Bool = render.layers.contains(layer)
        //        print("Render: \(renderIndex) contains: \(contains), layer: \(String(describing: layer.name)) ")
        let indexOfLayer = render.layers.index(of: layer)
        
        //        print("""
        //
        //            Render: \(renderIndex) layer: \(layer.name) found at index #\(indexOfLayer ?? 0)
        //
        //            """)
        
        if let indexOfLayer = indexOfLayer {
            //                print("Layer index #\(indexOfLayer) found for index: \(renderIndex)")
            let opacity = Opacity.show.rawValue
            //                print("Segment \(opacity) for layer \(layer.name)")
            return opacity
            
        } else {
            //            print("Index not found for layer \(String(describing: layer.name))")
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
//    func renderLayerOpacity(chart: OMScrollableChart, renderIndex: Int, layer: GradientShapeLayer) -> CGFloat? {
//        switch renderIndex {
//        case 0,1,2,3,4: break
//        case RenderIdent.segments.rawValue:
//            if let opacity = layerOpacityForSegmentRender(chart, renderIndex, layer) {
//                print("Segment \(opacity) for layer \(layer.name)")
//                return opacity
//            }
//        default: break
//        }
//        return nil
//    }
    
    
    func renderLayerOpacity(chart: OMScrollableChart, renderIndex: Int, layer: GradientShapeLayer) -> CGFloat? {
        if let opacity = layerOpacityForSegmentRender(chart, renderIndex, layer) {
//            print("Segment \(opacity) for layer \(layer.name)")
            return opacity
        }
        return nil
    }
    
    func numberOfPages(chart: OMScrollableChart) -> Int { 4 }
    func numberOfSectionsPerPage(chart: OMScrollableChart) -> Int { 6 }
    
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
        chart.renderDelegate  = self
        chart.backgroundColor = .clear
        chart.isPagingEnabled = false
        chart.maximumZoomScale = 9.0
        chart.renderManagerClass = RenderManager.self
        
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
        
        chartPointsRandom = randomFloat(200, max: 50000, min: -50)
        
        toleranceSlider.maximumValue  = 100
        toleranceSlider.minimumValue  = 1
        toleranceSlider.value        = Float(self.chart.approximationTolerance)
        
        sliderAverage.maximumValue = Float(chartPointsRandom.count)
        sliderAverage.minimumValue = 0
        sliderAverage.value       = Float(self.chart.numberOfElementsToGrouping)
        
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
//        
//        let nav = createCubicCurve()
//        navigationController?.pushViewController(nav, animated: false)
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
            if self.chart.numberOfElementsToGrouping != CGFloat(value) {
                self.chart.numberOfElementsToGrouping = CGFloat(value)
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
    var renderType: RenderType = .discrete
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
