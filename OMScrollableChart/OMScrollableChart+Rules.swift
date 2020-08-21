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
    
    /// addLeadingRuleIfNeeded
    /// - Parameters:
    ///   - rule: ChartRuleProtocol
    ///   - view: UIView
    func addLeadingRuleIfNeeded(_ rule: ChartRuleProtocol?,
                                view: UIView? = nil) {
        guard let rule = rule else {
            return
        }
        assert(rule.type == .root)
        if rule.superview == nil {
            rule.translatesAutoresizingMaskIntoConstraints = false
            if let view = view  {
                view.insertSubview(rule, at: rule.type.rawValue)
            } else {
                self.insertSubview(rule, at: rule.type.rawValue)
            }
            ruleLeadingAnchor  = rule.leadingAnchor.constraint(equalTo: self.leadingAnchor)
            ruletopAnchor      = rule.topAnchor.constraint(equalTo: self.topAnchor)
            rulebottomAnchor   = rule.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            rulewidthAnchor    = rule.widthAnchor.constraint(equalToConstant: CGFloat(rule.ruleSize.width))
            ruleLeadingAnchor?.isActive  = true
            ruletopAnchor?.isActive  = true
            rulebottomAnchor?.isActive  = true
            rulewidthAnchor?.isActive  = true
        }
    }
    
    /// addFooterRuleIfNeeded
    /// - Parameters:
    ///   - rule: ruleFooter description
    ///   - view: UIView
    func addFooterRuleIfNeeded(_  rule: ChartRuleProtocol? = nil, view: UIView? = nil) {
          guard let rule = rule else {
            return
        }
        assert(rule.type == .footer)
        if rule.superview == nil {
            rule.translatesAutoresizingMaskIntoConstraints = false
              if let view = view {
                view.insertSubview(rule, at: rule.type.rawValue)
            } else {
                self.insertSubview(rule, at: rule.type.rawValue)
            }
            
            let width = rule.ruleSize.width > 0 ?
                        rule.ruleSize.width :
                        contentSize.width
            
            rule.backgroundColor = UIColor.gray
            rule.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
            rule.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
            rule.topAnchor.constraint(equalTo: self.contentView.bottomAnchor,
                                            constant: -footerViewHeight).isActive = true
            rule.heightAnchor.constraint(equalToConstant: CGFloat(rule.ruleSize.height)).isActive = true
            rule.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
    }
    
//     func addTopRuleIfNeeded(_ ruleTop: ChartRuleProtocol? = nil) {
//        guard let ruleTop = ruleTop else {
//            return
//        }
//        assert(ruleTop.type == .top)
//        //ruleTop.removeFromSuperview()
//        ruleTop.translatesAutoresizingMaskIntoConstraints = false
//        ruleTop.backgroundColor = UIColor.clear
//        self.addSubview(ruleTop)
//        //        topView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
//        //        topView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
//        ruleTop.topAnchor.constraint(equalTo:  self.topAnchor).isActive = true
//        ruleTop.heightAnchor.constraint(equalToConstant: CGFloat(topViewHeight)).isActive = true
//        ruleTop.widthAnchor.constraint(equalToConstant: contentSize.width).isActive = true
//        ruleTop.backgroundColor = .gray
//    }

    // Calculate the rules marks positions
    func internalCalcRules() {
        
        var counter  = Int(numberOfRuleMarks) + 2
        //    counter += showLimitsMarks ? 1 : 0
        //    counter += showZeroMark ? 1 : 0
        
        let roundedStep = range / Float(counter)
        
        for ruleMarkIndex in 0..<counter {
            let value = minimumValue + Float(roundedStep) * Float(ruleMarkIndex)
            internalRulesMarks.append(value.roundToNearestValue(value: roundMarkValueTo))
        }
        
        internalRulesMarks.append(maximumValue)
    }
    // Create and add
    func createSuplementaryRules() {
            
        let rootRule = OMScrollableChartRule(chart: self)
        rootRule.chart = self
        rootRule.font  = ruleFont
        rootRule.fontColor = fontRootRuleColor
        let footerRule = OMScrollableChartRuleFooter(chart: self)
        footerRule.chart = self
        footerRule.font  = ruleFont
        footerRule.fontColor = fontFooterRuleColor
        //        self.addSubview(footerRule)
        //        self.addSubview(newRule)
        self.rootRule = rootRule
        self.footerRule = footerRule
        self.rules.append(rootRule)
        self.rules.append(footerRule)
        

        
//        if let topRule = topRule {
//            addTopRuleIfNeeded(topRule)
//        }
    }
    func calcRulesPoints() -> Bool {
        guard numberOfRuleMarks > 0 && (range != 0)  else {
            return false
        }
        internalRulesMarks.removeAll()
        internalCalcRules()
        
        rulesPoints = makePoints(data: rulesMarks, size: contentSize)

        return true
    }
    
    func layoutRules() {
        // rules lines
        
        let oldRulesPoints = rulesPoints
        guard let rule = rootRule, calcRulesPoints() else {
            return
        }
        
        if rulesPoints == oldRulesPoints {
            return
        }
        
        dashLineLayers.forEach({$0.removeFromSuperlayer()})
        dashLineLayers.removeAll()
        
        //let zeroMarkIndex    = rulesMarks.firstIndex(of: 0)
        let padding: CGFloat = rule.ruleSize.width
        let width = contentView.frame.width
        rulesPoints.enumerated().forEach { (offset: Int, item: CGPoint) in
            
//            if showZeroMark == false || zeroMarkIndex != offset {
                addDashLineLayer(point: CGPoint(x: padding, y: item.y),
                                 endPoint: CGPoint(x: width, y: item.y))
//            } else {
//                if zeroMarkIndex == offset {
//                    addDashLineLayer(point: CGPoint(x: padding, y: item.y),
//                                     endPoint: CGPoint(x: width, y: item.y),
//                                     stroke: UIColor.blue.withAlphaComponent(0.3),
//                                     lineWidth: 2,
//                                     pattern: [8, 6])
//                }
//            }
        }
        // Mark for display the rule.
        rules.forEach {
            if $0.isPointsNeeded {
                $0.isPointsNeeded = $0.createLayout()
            } else {
                $0.setNeedsLayout()
            }
        }
    }
}
