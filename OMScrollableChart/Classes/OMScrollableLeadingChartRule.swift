//// Copyright 2018 Jorge Ouahbi
////
//// Licensed under the Apache License, Version 2.0 (the "License");
//// you may not use this file except in compliance with the License.
//// You may obtain a copy of the License at
////
////     http://www.apache.org/licenses/LICENSE-2.0
////
//// Unless required by applicable law or agreed to in writing, software
//// distributed under the License is distributed on an "AS IS" BASIS,
//// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//// See the License for the specific language governing permissions and
//// limitations under the License.
//


import UIKit



public enum Index: Int {
    case bad = -1
}


// Uncategorized functions.

public func NSLocalizedString(_ key: String,
                              tableName: String? = nil,
                              bundle: Bundle = Bundle.main,
                              value: String = "",
                              comment: String = "") -> String {
    Foundation.NSLocalizedString(key, tableName: tableName,bundle: bundle,value: value,comment: comment)
}


public protocol OMScrollableChartRuleDelegate {
    func footerSectionsTextChanged(texts: [String])
    func footerSectionDidTouchUpInside(section: CGFloat, selectedView: UIView?)
    func footerSectionDidTouchUpInsideMove(section: CGFloat, selectedView: UIView?, location: CGPoint)
    func footerSectionDidTouchUpInsideRelease(section: CGFloat, selectedView: UIView?)
    func numberOfPagesChanged(pages: CGFloat)
    func contentSizeChanged(contentSize: CGSize)
    func frameChanged(frame: CGRect)
    func dataPointsChanged(dataPoints: [Float], for index: Int)
    func drawRootRuleText(in frame: CGRect, text: NSAttributedString)
    func renderDataTypeChanged(in dataOfRender: OMScrollableChart.RenderType, for index: Int)
    func updateRenderLayers( index: Int, with layers: [CALayer])
    func updateRenderData(index: Int, data: Data?)
    func deviceRotation()
    func regeneratingRendersLayers()
    
}

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
    
    var font: UIFont {get set}
    var fontColor: UIColor {get set}
    var fontStrokeColor: UIColor {get set}
    var decorationColor: UIColor {get set}
    var leftInset: CGFloat {get set}
    var ruleSize: CGSize {get}
    var views: [UIView]? {get}
    func layoutRule() -> Bool
    func onFooterRuleSectionIndexSelected(at index: CGFloat?) -> Bool
    func subviewIndexFromPoint(_ location: CGPoint) -> Int
}

extension ChartRuleProtocol {
    /// onFooterRuleSectionIndexSelected
    /// - Parameter location: CGPoint
    func onFooterRuleSectionIndexSelected(at index: CGFloat? = nil ) -> Bool {
        guard let ruleViews = self.views else { return false }
        if let sectionSelectedIndex = index {
            let idx = Int(sectionSelectedIndex)
            let selectedFooterView = ruleViews[idx]
            guard let delegate = chart.renderDelegate else { return false }
            
            print("Notify section selected index",
                  sectionSelectedIndex,
                  selectedFooterView,
                  delegate)
            
            // notify
//            for render in RenderManager.shared.ruleEventsRenders {
//                // OMScrollableChartRenderableDelegateProtocol
//                delegate.didTouchFooterSectionView(chart: chart,
//                                                   renderIndex: render.index,
//                                                   sectionIndex: Int(sectionSelectedIndex),
//                                                   view: selectedFooterView)
//            }
            
            chart
                .flowDelegate?
                .footerSectionDidTouchUpInside(section: sectionSelectedIndex,
                                                         selectedView: selectedFooterView)
            
            return true
        }
        return false
    }
    func subviewIndexFromPoint(_ location: CGPoint) -> Int {
        guard let views = views else {
            return Index.bad.rawValue
        }
        for (index, view) in views.enumerated() {
            if view.frame.contains(location) {
                //we found the finally touched view
                print(index,"Found it", view)
                return index
            }
        }
        return Index.bad.rawValue
    }
}





//
// MARK: - OMScrollableLeadingChartRule -
//
class OMScrollableLeadingChartRule: UIView, ChartRuleProtocol {
    private var labelViews = [UIView]()
    var views: [UIView]?  {
        return labelViews
    }
    var type: ChartRuleType = .leading
    var chart: OMScrollableChart!
    var decorationColor: UIColor = .black

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
    var fontStrokeColor = UIColor.lightGray
    var font = UIFont.systemFont(ofSize: 14, weight: .thin) {
        didSet {
            views?.forEach({($0 as? UILabel)?.font = font})
        }
    }
    var ruleSize: CGSize = CGSize(width: 60, height: 0)
    var leftInset: CGFloat = 15
    func layoutRule() -> Bool {
        guard let chart = chart else {
            return false
        }
        labelViews.forEach({$0.removeFromSuperview()})
        labelViews.removeAll()
        let fontSize: CGFloat = font.pointSize
                
        for (index, item) in chart.ruleManager.rulesPoints.enumerated() {
                if let stepString = chart.currencyFormatter.string(from: NSNumber(value: chart.rulesMarks[index])) {
                    let string = NSAttributedString(string: stepString,
                                                    attributes: [NSAttributedString.Key.font: self.font,
                                                                 NSAttributedString.Key.foregroundColor: self.fontColor,
                                                                 NSAttributedString.Key.strokeColor: self.fontStrokeColor])
                    let label = UILabel()
                    label.attributedText = string
                    label.sizeToFit()
                    label.frame = CGRect(x: leftInset,
                                     y: (item.y - fontSize),
                                         width: label.bounds.width,
                                         height: label.bounds.height)
                    self.addSubview(label)
                    labelViews.append(label)
                    // Notify the draw
                    chart.flowDelegate?.drawRootRuleText(in: label.frame, text: string)
                }
        }
        return true
    }
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        setNeedsLayout()
    }
    var oldFrame: CGRect = .zero
    override func layoutSubviews() {
        super.layoutSubviews()
        if !layoutRule() { // TODO: update layout
           // Log.print("Unable to create the rule layout",.error)
        }
    }
}



// MARK: - OMScrollableChartRuleFooter -
class OMScrollableChartRuleFooter: UIStackView, ChartRuleProtocol {
    var fontStrokeColor: UIColor = .black
    var leftInset: CGFloat = 16
    var chart: OMScrollableChart!
    var type: ChartRuleType = .footer
    var ruleFooterViewSelectedSectionIndex: CGFloat = 0
    /// Border decoration.
    var borderDecorationWidth: CGFloat = 0.5
    var decorationColor: UIColor = UIColor.darkGreyBlueTwo
    var  borderViews = [UIView]()
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
        self.alignment = .top
        backgroundColor = .clear
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var ruleSize: CGSize { return CGSize(width: 0, height: self.chart.ruleManager.footerViewHeight)}
    var fontColor = UIColor.darkGreyBlueTwo {
        didSet {
            views?.forEach({($0 as? UILabel)?.textColor = fontColor})
        }
    }
    var font = UIFont.systemFont(ofSize: 14, weight: .thin) {
        didSet {
            views?.forEach({($0 as? UILabel)?.font = font})
        }
    }
    // Sections text.
    var footerSectionsText = [NSLocalizedString("Ene"), NSLocalizedString("Feb"), NSLocalizedString("Mar"),
                                                                          NSLocalizedString("Abr"),
                                                                          NSLocalizedString("May"), NSLocalizedString("Jun"), NSLocalizedString("Jul"), NSLocalizedString("Ago"), NSLocalizedString("Sep"), NSLocalizedString("Oct"), NSLocalizedString("Nov"), NSLocalizedString("Dic")] {
        didSet {
            #if DEBUG
            if footerSectionsText.count > 0 {
                assert(footerSectionsText.count == Int(chart.numberOfSections))
            }
            #endif
            setNeedsLayout()
        }
    }

    /// create rule layout
    /// - Returns: Bool
    func layoutRule() -> Bool {
        guard !self.frame.isEmpty else {
            return false
        }
        self.borderViews.forEach({ $0.removeFromSuperview()})
        self.subviews.forEach({ $0.removeFromSuperview()})
        let width  = chart.sectionWidth
        let height = ruleSize.height * 0.5
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
                label.backgroundColor = .clear
            label.textColor = fontColor
            self.addArrangedSubview(label)
            label.widthAnchor.constraint(equalToConstant: width).isActive = true
                //label.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            label.heightAnchor.constraint(equalToConstant: height).isActive = true
            borderViews.append(label.setBorder(border: .right(inset: 5),
                                            weight: borderDecorationWidth,
                                color: decorationColor.withAlphaComponent(0.24)))
        }
       // }
        borderViews.append(self.setBorder(border: .top(inset: 10),
                                      weight: borderDecorationWidth,
                       color: decorationColor.withAlphaComponent(0.24)))
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let touch = touches.first {
            
            //
            // Get the view.
            //
            
            let location = touch.preciseLocation(in: self)
            let subviewIndex = subviewIndexFromPoint(location)
            if subviewIndex != Index.bad.rawValue {
                _ = onFooterRuleSectionIndexSelected( at: CGFloat(subviewIndex))
                ruleFooterViewSelectedSectionIndex = CGFloat(subviewIndex)
            }
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let views = views else { return}
        // Move the touch
        if let touch = touches.first {
            let idx = Int(ruleFooterViewSelectedSectionIndex)
            chart.flowDelegate?.footerSectionDidTouchUpInsideMove(section: ruleFooterViewSelectedSectionIndex, selectedView: views[idx] ,
                                                                 location: touch.location(in: self))
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let views = views else { return}
        let idx = Int(ruleFooterViewSelectedSectionIndex)
        // Release the touch
        chart.flowDelegate?.footerSectionDidTouchUpInsideRelease(section: ruleFooterViewSelectedSectionIndex,
                                                                 selectedView: views[idx] )
        ruleFooterViewSelectedSectionIndex = 0
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if !layoutRule() { // TODO: update layout
           // Log.print("Unable to create the rule layout", .error)
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
//        backgroundColor = .surfaceDark
         if !layoutRule() { // TODO: update layout
            //Log.print("Unable to create the rule layout" ,.error)
        }
    }
}
