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


let chartPoints: [Float] =   [1510, 100, 3000, 100, 1200, 13000,
             15000, -1500, 800, 1000, 6000, 1300,
1510, 100, 3000, 100, 1200, 13000,
15000, -1500, 800, 1000, 6000, 1300]



class ViewController: UIViewController, OMScrollableChartDataSource {
    
    func dataPoints(chart: OMScrollableChart, section: Int) -> [Float] {
        return chartPoints
    }
    
    func numberOfPages(chart: OMScrollableChart) -> CGFloat {
        return 2
    }
    
    func numberOfSectionsPerPage(chart: OMScrollableChart) -> Int {
        return 3
    }
    
    @IBOutlet var slider: UISlider!
    @IBOutlet var scrollView: OMScrollableChart!
    @IBOutlet var segmentInterpolation: UISegmentedControl!
    @IBOutlet var sliderAverage: UISlider!
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.bounces = false
        scrollView.dataSource = self
        scrollView.backgroundColor = .clear
        scrollView.isPagingEnabled = true
        
        slider.maximumValue  = 20
        slider.minimumValue  = 1
        slider.value = Float(self.scrollView.approximationTolerance)
        sliderAverage.maximumValue = Float(chartPoints.count)
        sliderAverage.minimumValue = 0
        sliderAverage.value = Float(self.scrollView.numberOfElementsToAverage)
        segmentInterpolation.removeAllSegments()
        segmentInterpolation.insertSegment(withTitle: "none", at: 0, animated: false)
        segmentInterpolation.insertSegment(withTitle: "smoothed", at: 1, animated: false)
        segmentInterpolation.insertSegment(withTitle: "cubicCurve", at: 2, animated: false)
        segmentInterpolation.insertSegment(withTitle: "hermite", at: 3, animated: false)
        segmentInterpolation.insertSegment(withTitle: "catmullRom", at: 4, animated: false)
        segmentInterpolation.selectedSegmentIndex = 0
        
        scrollView.updateData()
    }
    @IBAction  func simplifySliderChange( _ sender: UISlider)  {
        if sender == sliderAverage {
            self.scrollView.numberOfElementsToAverage = Int(sliderAverage.value)
        } else {
            self.scrollView.approximationTolerance = CGFloat(slider.value)
        }
    }
        
    @IBAction  func interpolationSegmentChange( _ sender: Any)  {
        switch segmentInterpolation.selectedSegmentIndex  {
        case 0:
            scrollView.polylineInterpolation = .none
            case 1:
                scrollView.polylineInterpolation = .smoothed
            case 2:
                scrollView.polylineInterpolation = .cubicCurve
            case 3:
                scrollView.polylineInterpolation = .hermite(0.5)
            case 4:
                scrollView.polylineInterpolation = .catmullRom(0.5)
        default:
            assert(false)
        }
     
    }
}

