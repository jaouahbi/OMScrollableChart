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
//// https://stackoverflow.com/questions/35915853/how-to-show-tooltip-on-a-point-click-in-swift
//// https://itnext.io/swift-uiview-lovely-animation-and-transition-d34bd623391f
//// https://stackoverflow.com/questions/29674959/linear-regression-accelerate-framework-in-swift
//// https://gist.github.com/marmelroy/ed4bd675bd75c757ab7447d1b3488886
//
//import UIKit
//import Accelerate
//
///*
// [topRule]
// ---------------------
// |
// rootRule   |
// |
// |
// |       footerRule
// |______________________
// */
//
//extension OMScrollableChart {
//
//    /// addLeadingRuleIfNeeded
//    /// - Parameters:
//    ///   - rule: ChartRuleProtocol
//    ///   - view: UIView
//    func addLeadingRuleIfNeeded(_ rule: ChartRuleProtocol?,
//                                view: UIView? = nil) {
//        guard let rule = rule else {
//            return
//        }
//        //rule.backgroundColor = .red
//        assert(rule.type == .leading)
//        if rule.superview == nil {
//            rule.translatesAutoresizingMaskIntoConstraints = false
//            if let view = view  {
//                view.insertSubview(rule, at: rule.type.rawValue)
//            } else {
//                self.insertSubview(rule, at: rule.type.rawValue)
//            }
//
//            let width = rule.ruleSize.width > 0 ?
//                rule.ruleSize.width :
//                contentSize.width
//            let height = rule.ruleSize.height > 0 ?
//                rule.ruleSize.height :
//                contentSize.height
//            print(height, width)
//            ruleLeadingAnchor  = rule.leadingAnchor.constraint(equalTo: self.leadingAnchor)
//            ruletopAnchor      = rule.topAnchor.constraint(equalTo: self.contentView.topAnchor)
//            rulewidthAnchor    = rule.widthAnchor.constraint(equalToConstant: CGFloat(width))
//            ruleHeightAnchor    = rule.heightAnchor.constraint(equalToConstant: CGFloat(height))
//
//            if let footerRule = footerRule {
//                rulebottomAnchor =  rule.bottomAnchor.constraint(equalTo: footerRule.bottomAnchor,
//                                                                 constant: -footerRule.ruleSize.height)
//            }
//
//            ruleLeadingAnchor?.isActive  = true
//            ruletopAnchor?.isActive  = true
//            //rulebottomAnchor?.isActive  = true
//            rulewidthAnchor?.isActive  = true
//            ruleHeightAnchor?.isActive  = true
//        }
//    }
//
//    /// addFooterRuleIfNeeded
//    /// - Parameters:
//    ///   - rule: ruleFooter description
//    ///   - view: UIView
//    func addFooterRuleIfNeeded(_ rule: ChartRuleProtocol? = nil,
//                               view: UIView? = nil) {
//        guard let rule = rule else {
//            return
//        }
//        assert(rule.type == .footer)
//        //rule.backgroundColor = .red
//        if rule.superview == nil {
//            rule.translatesAutoresizingMaskIntoConstraints = false
//            if let view = view {
//                view.insertSubview(rule, at: rule.type.rawValue)
//            } else {
//                self.insertSubview(rule, at: rule.type.rawValue)
//            }
//
//            let width = rule.ruleSize.width > 0 ?
//                rule.ruleSize.width :
//                contentSize.width
//            let height = rule.ruleSize.height > 0 ?
//                rule.ruleSize.height :
//                contentSize.height
//
//            //rule.backgroundColor = UIColor.gray
//            rule.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
//            rule.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
//            rule.topAnchor.constraint(equalTo: self.contentView.bottomAnchor,
//                                      constant: 0).isActive = true
//            rule.heightAnchor.constraint(equalToConstant: CGFloat(height)).isActive = true
//            rule.widthAnchor.constraint(equalToConstant: width).isActive = true
//        }
//    }
//
//    //     func addTopRuleIfNeeded(_ ruleTop: ChartRuleProtocol? = nil) {
//    //        guard let ruleTop = ruleTop else {
//    //            return
//    //        }
//    //        assert(ruleTop.type == .top)
//    //        //ruleTop.removeFromSuperview()
//    //        ruleTop.translatesAutoresizingMaskIntoConstraints = false
//    //        ruleTop.backgroundColor = UIColor.clear
//    //        self.addSubview(ruleTop)
//    //        //        topView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
//    //        //        topView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
//    //        ruleTop.topAnchor.constraint(equalTo:  self.topAnchor).isActive = true
//    //        ruleTop.heightAnchor.constraint(equalToConstant: CGFloat(topViewHeight)).isActive = true
//    //        ruleTop.widthAnchor.constraint(equalToConstant: contentSize.width).isActive = true
//    //        ruleTop.backgroundColor = .gray
//    //    }
//
//
//    func appendRuleMark( _ value: Float) {
////        if value > 100000 {
////            let roundToNearest = round(value / 10000) * 10000
////            internalRulesMarks.append(roundToNearest)
////        } else if value > 10000 {
////            let roundToNearest = round(value / 1000) * 1000
////            internalRulesMarks.append(roundToNearest)
////        } else if value > 1000 {
////            let roundToNearest = round(value / 100) * 100
////            internalRulesMarks.append(roundToNearest)
////        } else if value > 100 {
////            let roundToNearest = round(value / 10) * 10
////            internalRulesMarks.append(roundToNearest)
////        } else {
////            internalRulesMarks.append(round(value))
////        }
//
//        // Dont be adaptative, only round the 1000
//        if value > 10000 {
//            let roundToNearest = round(value / 1000) * 1000
//            internalRulesMarks.append(roundToNearest)
//        }else {
//            internalRulesMarks.append(round(value))
//        }
//    }
//    // Calculate the rules marks positions
//    func internalCalcRules() {
//        // Get the polyline generator
//        if let generator  = coreGenerator {
//            // + 2 is the limit up and the limit down
//            let numberOfAllRuleMarks = Int(numberOfRuleMarks) + 2 - 1
//            let roundedStep = generator.range / Float(numberOfAllRuleMarks)
//            for ruleMarkIndex in 0..<numberOfAllRuleMarks {
//                let value = generator.minimumValue + Float(roundedStep) * Float(ruleMarkIndex)
//                appendRuleMark(value)
//            }
//            appendRuleMark(generator.maximumValue)
//        }
//    }
//    // Create and add
//    func createSuplementaryRules() {
//
//        let rootRule = OMScrollableLeadingChartRule(chart: self)
//        rootRule.chart = self
//        rootRule.font  = ruleFont
//        rootRule.fontColor = fontRootRuleColor
//        let footerRule = OMScrollableChartRuleFooter(chart: self)
//        footerRule.chart = self
//        footerRule.font  = ruleFont
//        footerRule.fontColor = fontFooterRuleColor
//        self.rootRule = rootRule
//        self.footerRule = footerRule
//        self.rules.append(rootRule)
//        self.rules.append(footerRule)
//        // self.rules.append(topRule)
//
//
//        //        if let topRule = topRule {
//        //
//        //        }
//    }
//    func makeRulesPoints() -> Bool {
//        if let generator  = coreGenerator {
//            guard numberOfRuleMarks > 0 &&
//                    (generator.range != 0)  else {
//                return false
//            }
//            internalRulesMarks.removeAll()
//            internalCalcRules()
//            rulesPoints = generator.makePoints(data: rulesMarks,
//                                            size: self.contentView.frame.size)
//            return true
//        }
//        return false
//    }
//
//    func addDashLinesToMarksToVerticalRule(_ leadingRule: ChartRuleProtocol) {
//        dashLineLayers.forEach({$0.removeFromSuperlayer()})
//        dashLineLayers.removeAll()
//
//        let leadingRuleWidth: CGFloat = leadingRule.ruleSize.width
//        let width: CGFloat = contentView.frame.width
//
//        let fontSize = ruleFont.pointSize
//        for (index, item) in rulesPoints.enumerated() {
//            var yPos = (item.y + fontSize * 0.5)
//            if index > 0 {
//                if index < rulesPoints.count - 1 {
//                    yPos = item.y
//                } else {
//                    yPos = item.y
//                }
//            }
//            let markPointLeft  = CGPoint(x: leadingRuleWidth, y: yPos)
//            let markPointRight = CGPoint(x: width, y: yPos)
//            addDashLineLayerFromRuleMark(point: markPointLeft, endPoint: markPointRight)
//        }
//    }
//
//    func layoutRules() {
//        // rules lines
//
//        let oldRulesPoints = rulesPoints
//        guard let leadingRule = rootRule else {
//            return
//        }
//
//        guard makeRulesPoints() else {
//            return
//        }
//
//        if rulesPoints == oldRulesPoints {
//            return
//        }
//
//        addDashLinesToMarksToVerticalRule(leadingRule)
//
//        // Mark for display the rule.
//        rules.forEach {
//            $0.setNeedsDisplay()
//        }
//    }
//}



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

import Accelerate
import UIKit

/*
 [topRule]
 ---------------------
 |
 rootRule   |
 |
 |
 |       footerRule
 |______________________
 */

extension OMScrollableChart {
    func appendRuleMark(_ value: Float) {
//        if value > 100000 {
//            let roundToNearest = round(value / 10000) * 10000
//            internalRulesMarks.append(roundToNearest)
//        } else if value > 10000 {
//            let roundToNearest = round(value / 1000) * 1000
//            internalRulesMarks.append(roundToNearest)
//        } else if value > 1000 {
//            let roundToNearest = round(value / 100) * 100
//            internalRulesMarks.append(roundToNearest)
//        } else if value > 100 {
//            let roundToNearest = round(value / 10) * 10
//            internalRulesMarks.append(roundToNearest)
//        } else {
//            internalRulesMarks.append(round(value))
//        }
        
        // Dont be adaptative, only round the 1000
        if value > 10000 {
            let roundToNearest = round(value / 1000) * 1000
            ruleManager.rulesMarks.append(roundToNearest)
        } else {
            ruleManager.rulesMarks.append(round(value))
        }
    }
    
    /// Calculate the rules marks positions
    
    func internalCalcRules(generator: ScaledPointsGeneratorProtocol) {
        // Get the polyline generator
        // + 2 is the limit up and the limit down
        let numberOfAllRuleMarks = Int(numberOfRuleMarks) + 2 - 1
        let roundedStep = generator.range / Float(numberOfAllRuleMarks)
        for ruleMarkIndex in 0 ..< numberOfAllRuleMarks {
            let value = generator.minimumValue + Float(roundedStep) * Float(ruleMarkIndex)
            appendRuleMark(value)
        }
        appendRuleMark(generator.maximumValue)
    }
    
    
//    func rootGenerator() -> LinearScaledPointsGeneratorProtocol? {
//        guard let rootRender = client.renders.filter({ $0.prop == RenderProperties.root }).first else {
//            return nil
//        }
//        switch rootRender.data.dataType {
//        case .discrete:
//            return rootRender.data.generator
//        case .stadistics:
//            return rootRender.data.generator
//        case .simplify:
//            return rootRender.data.generator
//        case .regress:
//            return rootRender.data.generator
//        }
//    }
    
    var drawableFrame: CGRect {
        return CGRect(origin: .zero,
                      size: contentView.frame.size)
    }
    
    func makeRulesPoints() -> Bool {
        let generator = scaledPointsGenerator[Renders.polyline.rawValue]
        guard numberOfRuleMarks > 0,generator.range != 0 else { return false }
        ruleManager.rulesMarks.removeAll()
        internalCalcRules(generator: generator)
        ruleManager.rulesPoints = generator.makePoints(data: rulesMarks,
                                                             size: drawableFrame.size)
        return true
    }
    
    ///
    /// layoutRules
    ///
    
    func layoutRules() {
        // Layout rules lines
        let oldRulesPoints = ruleManager.rulesPoints
        guard let leadingRule = ruleManager.rootRule else {
            return
        }
        guard makeRulesPoints() else { return }
        if ruleManager.rulesPoints == oldRulesPoints { return }
        // Update
        ruleManager.addToVerticalRuleMarks(leadingRule: leadingRule)
        // Mark for display the rule.
        ruleManager.rules.forEach { rule in
            _ = rule.layoutRule()
            rule.setNeedsDisplay()
        }
    }
}

