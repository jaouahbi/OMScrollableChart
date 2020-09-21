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

import Foundation
import UIKit

enum ChartRuleType: Int {
    case leading = 0
    case footer = 1
    case top = 2
    case trailing = 3
}
protocol ChartRuleProtocol: UIView {
    var chart: OMScrollableChart! {get set}
    init(chart: OMScrollableChart!)
    var type: ChartRuleType {get set}
    //var isPointsNeeded: Bool {get set}
    var font: UIFont {get set}
    var fontColor: UIColor {get set}
    var decorationColor: UIColor {get set}
    var leftInset: CGFloat {get set}
    var ruleSize: CGSize {get}
    var views: [UIView]? {get}
    func createLayout() -> Bool
}



// Swift 3.0
extension UIView {

  enum Border {
    case left(constant: CGFloat)
    case right(constant: CGFloat)
    case top(constant: CGFloat)
    case bottom(constant: CGFloat)
  }

  func setBorder(border: UIView.Border, weight: CGFloat, color: UIColor) -> UIView {

    let lineView = UIView()
    addSubview(lineView)
    lineView.backgroundColor = color
    lineView.translatesAutoresizingMaskIntoConstraints = false

    switch border {

    case .left(let constant):
      lineView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
      lineView.topAnchor.constraint(equalTo: topAnchor, constant: -constant).isActive = true
      lineView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: constant).isActive = true
      lineView.widthAnchor.constraint(equalToConstant: weight).isActive = true

    case .right(let constant):
      lineView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
      lineView.topAnchor.constraint(equalTo: topAnchor, constant: constant ).isActive = true
      lineView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -constant ).isActive = true
      lineView.widthAnchor.constraint(equalToConstant: weight).isActive = true

    case .top(let constant):
      lineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
      lineView.leftAnchor.constraint(equalTo: leftAnchor, constant: constant ).isActive = true
      lineView.rightAnchor.constraint(equalTo: rightAnchor, constant: -constant).isActive = true
      lineView.heightAnchor.constraint(equalToConstant: weight).isActive = true

    case .bottom(let constant):
      lineView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
      lineView.leftAnchor.constraint(equalTo: leftAnchor, constant: constant).isActive = true
      lineView.rightAnchor.constraint(equalTo: rightAnchor, constant: -constant).isActive = true
      lineView.heightAnchor.constraint(equalToConstant: weight).isActive = true
    }
    
    return lineView
  }
}

// MARK: - OMScrollableLeadingChartRule -
class OMScrollableLeadingChartRule: UIView, ChartRuleProtocol {
    private var labelViews = [UIView]()
    var views: [UIView]?  {
        return labelViews
    }
    var type: ChartRuleType = .leading
    var chart: OMScrollableChart!
    var decorationColor: UIColor = .black
    //var isPointsNeeded: Bool =  true
    required init(chart: OMScrollableChart!) {
        super.init(frame: .zero)
        self.chart = chart
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }
    var fontColor = UIColor.black {
        didSet {
            views?.forEach({($0 as? UILabel)?.textColor = fontColor})
        }
    }
    var font = UIFont.systemFont(ofSize: 14, weight: .thin) {
        didSet {
            views?.forEach({($0 as? UILabel)?.font = font})
        }
    }
    var ruleSize: CGSize = CGSize(width: 60, height: 0)
    var leftInset: CGFloat = 15
    func createLayout() -> Bool {
        guard let chart = chart else {
            return false
        }
        labelViews.forEach({$0.removeFromSuperview()})
        labelViews.removeAll()
        let fontSize: CGFloat = font.pointSize
  
        for (index, item) in chart.rulesPoints.enumerated() {
            if let stepString = chart.currencyFormatter.string(from: NSNumber(value: chart.rulesMarks[index])) {
                let string = NSAttributedString(string: stepString,
                                                attributes: [NSAttributedString.Key.font: self.font,
                                                             NSAttributedString.Key.foregroundColor: self.fontColor,
                                                             NSAttributedString.Key.strokeColor: UIColor.lightGray])
                let label = UILabel()
                label.attributedText = string
                label.sizeToFit()
                label.frame = CGRect(x: leftInset,
                                     y: (item.y - fontSize),
                                     width: label.bounds.width,
                                     height: label.bounds.height)
                self.addSubview(label)
                labelViews.append(label)
            }
        }
        return true
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if !createLayout() { // TODO: update layout
           // GCLog.print("Unable to create the rule layout",.error)
        }
    }
}


// MARK: - OMScrollableChartRuleFooter -
class OMScrollableChartRuleFooter: UIStackView, ChartRuleProtocol {
   
    
    var leftInset: CGFloat = 15
    var chart: OMScrollableChart!
    //var isPointsNeeded: Bool  =  false
    var type: ChartRuleType = .footer
    var views: [UIView]? {
        return arrangedSubviews
    }
    var footerRuleHeight: CGFloat = 30 {
        didSet {
            setNeedsLayout()
        }
    }
    /// init
    /// - Parameter chart: OMScrollableChart
    required init(chart: OMScrollableChart!) {
        super.init(frame: .zero)
        self.chart = chart
        backgroundColor = .clear
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var ruleSize: CGSize { return CGSize(width: 0, height: footerRuleHeight)}
    var fontColor = UIColor.black {
        didSet {
            views?.forEach({($0 as? UILabel)?.textColor = fontColor})
        }
    }
    var font = UIFont.systemFont(ofSize: 14, weight: .thin) {
        didSet {
            views?.forEach({($0 as? UILabel)?.font = font})
        }
    }
    var footerSectionsText = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"] {
        didSet {
            setNeedsLayout()
        }
    }
    /// Border decoration.
    var borderDecorationWidth: CGFloat = 0.5
    var decorationColor: UIColor = UIColor.darkGreyBlueTwo
    /// create rule layout
    /// - Returns: Bool
    func createLayout() -> Bool {
        guard !self.frame.isEmpty else {
            return false
        }
        self.subviews.forEach({ $0.removeFromSuperview()})
        let width  = chart.sectionWidth
        let height = ruleSize.height
        let numOfSections = Int(chart.numberOfSections)
        let month = Calendar.current.dateComponents([.day, .month, .year], from: Date()).month ?? 0
        //if let month = startIndex {
            let currentMonth = month
            //let symbols = DateFormatter().monthSymbols
            for monthIndex in currentMonth...numOfSections + currentMonth  {
                //GCLog.print("monthIndex: \(monthIndex % footerSectionsText.count) \(footerSectionsText[monthIndex % footerSectionsText.count])", .trace)
                let label = UILabel(frame: .zero)
                label.translatesAutoresizingMaskIntoConstraints = false
                label.text = footerSectionsText[monthIndex % footerSectionsText.count]
                label.textAlignment = .center
                label.font = font
                label.sizeToFit()
                label.backgroundColor = UIColor.white
                label.textColor = fontColor
                self.addArrangedSubview(label)
                label.widthAnchor.constraint(equalToConstant: width).isActive = true
                label.heightAnchor.constraint(equalToConstant: height).isActive = true
               _ = label.setBorder(border: .right(constant: 5),
                                weight: borderDecorationWidth,
                                color: decorationColor)
            }
       // }
        _ = self.setBorder(border: .top(constant: 10),
                       weight: borderDecorationWidth,
                       color: decorationColor)
        return true
    }
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if !createLayout() { // TODO: update layout
           // GCLog.print("Unable to create the rule layout", .error)
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
         if !createLayout() { // TODO: update layout
            //GCLog.print("Unable to create the rule layout" ,.error)
        }
    }
}
