//
//  ExampleTests.swift
//  ExampleTests
//
//  Created by Jorge Ouahbi on 29/10/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import XCTest
@testable import OMScrollableChart
@testable import LibControl

class OMScrollableChartTests: XCTestCase, OMScrollableChartDataSource, OMScrollableChartRenderableProtocol {
    

    static var allTests = [
        ("testSimplification", testSimplification),
        ("testScaledPointsGenerator", testScaledPointsGenerator),
        ("testEquality", testEquality),
        ("testMidpoint", testMidpoint),
        ("testAngle", testAngle),
        ("testLength", testLength),
        ("testTranslate", testTranslate),
        ("testRotate", testRotate),
        ("testInterpolatePointAtT", testInterpolatePointAtT),
        ("testBounds", testBounds),
        ("testPointsOnLineAtDistance", testPointsOnLineAtDistance),
        ("testIntersectionPointWithLineSegment", testIntersectionPointWithLineSegment),
        ("testChartEngine", testChartEngine),
        ("testPRprovidesExpectedOutput", testPRprovidesExpectedOutput)
        // test intersection
    ]
    
    var polyregress: PolynomialRegression!
    var xValues: [Double]!
    var yValues: [Double]!
    
    override func setUpWithError() throws {
        xValues = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        yValues = [1, 6, 17, 34, 57, 86, 121, 162, 209, 262, 321]
        
        polyregress = PolynomialRegression(xValues: xValues, yValues: yValues)
    }
    
    override func tearDownWithError() throws {
        polyregress = nil
    }
    
    func dataPoints(chart: OMScrollableChart, renderIndex: Int, section: Int) -> [Float] {
        return randomFloat(25, max: 1000, min: 10)
    }
    
    func numberOfPages(chart: OMScrollableChart) -> CGFloat {
        2
    }
    
    func dataLayers(chart: OMScrollableChart, renderIndex: Int, section: Int, points: [CGPoint]) -> [OMGradientShapeClipLayer] {
        []
    }
    
    func footerSectionsText(chart: OMScrollableChart) -> [String]? {
        []
    }
    
    func dataPointTootipText(chart: OMScrollableChart, renderIndex: Int, dataIndex: Int, section: Int) -> String? {
        nil
    }
    
    func dataOfRender(chart: OMScrollableChart, renderIndex: Int) -> OMScrollableChart.RenderType {
        .discrete
    }
    
    func dataSectionForIndex(chart: OMScrollableChart, dataIndex: Int, section: Int) -> String? {
        return nil
    }
    
    func numberOfSectionsPerPage(chart: OMScrollableChart) -> Int {
        return 6
    }
    
    func layerOpacity(chart: OMScrollableChart, renderIndex: Int, layer: OMGradientShapeClipLayer) -> CGFloat {
        return 1
    }
    
    func renderOpacity(chart: OMScrollableChart, renderIndex: Int) -> CGFloat {
        return 1
    }
    
    func queryAnimation(chart: OMScrollableChart, renderIndex: Int) -> AnimationTiming {
        return .none
    }
    
    func animateLayers(chart: OMScrollableChart, renderIndex: Int, layerIndex: Int, layer: OMGradientShapeClipLayer) -> CAAnimation? {
        return nil
    }
    
    func testPRprovidesExpectedOutput() throws {
        let expectedResults: [Double] = [1, 6, 17, 34, 57, 86, 121, 162, 209, 262, 321]
        for i in 0...10 {
            if let result = polyregress.predictYValue(at: Double(i)) {
                XCTAssertEqual(result, expectedResults[i])
            } else {
                XCTFail("Result returned nil")
            }
        }
    }
    
    func testChartEngine() {
        
        let chart = OMScrollableChart(frame: CGRect(x: 0,y: 0, width: 100, height: 100))
        chart.dataSource = self
        chart.renderSource = self
        chart.layoutForFrame()
        
        guard let locator = chart as? RenderLocatorProtocol else {
            XCTAssert(false)
            return
        }

        for currentRender in 0..<self.numberOfRenders {
            
            let last  = chart.maxPoint(in: currentRender) ?? .zero
            let first = chart.minPoint(in: currentRender) ?? .zero
            
            var indexFirstPoint = locator.indexForPoint(currentRender, point: first)
            let indexLastPoint  = locator.indexForPoint(currentRender, point: last)
            
            let indexFirstPointIndex = locator.pointFromIndex(currentRender, index: indexFirstPoint!)
            let indexLastPointIndex  = locator.pointFromIndex(currentRender, index: indexLastPoint!)
            
            XCTAssertEqual(first, indexFirstPointIndex)
            XCTAssertEqual(last, indexLastPointIndex)
            
            XCTAssert(indexLastPoint != indexFirstPoint)
            
            //var dataIndexLast = chart.dataIndexFromLayers( index, point: last)
            var dataIndexFirst = locator.dataIndexFromPoint( currentRender, point: first)
            let dataIndexLast  = locator.dataIndexFromPoint( currentRender, point: last)
            
            XCTAssert(dataIndexFirst == indexFirstPoint)
            XCTAssert(indexLastPoint == dataIndexLast)
            
            var dataFromLast = locator.dataFromPoint( currentRender, point: last)
            var dataStringFromFirst = locator.dataStringFromPoint( currentRender, point: first)
            
            XCTAssert(dataIndexFirst == indexFirstPoint)
            
            for currentPoint in chart.pointsRender[currentRender] {
            
                indexFirstPoint = locator.indexForPoint(currentRender, point: currentPoint)
                let point2 = locator.pointFromIndex(currentRender, index: indexFirstPoint!)
                XCTAssertEqual(point2, currentPoint)
                dataIndexFirst = locator.dataIndexFromPoint( currentRender, point: currentPoint)
                XCTAssert(dataIndexFirst == indexFirstPoint)
                
                dataFromLast = locator.dataFromPoint( currentRender, point: currentPoint)
                dataStringFromFirst = locator.dataStringFromPoint( currentRender, point: currentPoint)
                XCTAssert(((dataStringFromFirst?.elementsEqual(String(dataFromLast!))) != nil))
            }
        }
    }
    
    func testSimplification() {
        var visvalingam = [CGPoint]()
        var radial = [CGPoint]()
        var ramer = [CGPoint]()
        var decimate = [CGPoint]()
        
        let numberOfItems = 300
        let randomPoints  = (0..<numberOfItems).map { _ in CGPoint(x: .random(min: 0, max: UIScreen.main.bounds.size.width),
                                                                y: .random(min: 0, max: UIScreen.main.bounds.size.height)) }
        print("#  ",
              "  Visva",
              "  DP Rad",
              "  Ramer DP",
              "  Decimate")
        
        for index in (0..<numberOfItems) {
            visvalingam = OMSimplify.visvalingamSimplify(randomPoints, limit: CGFloat(index) )
            radial = OMSimplify.douglasPeuckerRadialSimplify(randomPoints, tolerance: CGFloat(index), highestQuality: true)
            decimate = OMSimplify.douglasPeuckerDecimateSimplify(randomPoints, tolerance:  CGFloat(sqrt(Double(index * 2))) )
            ramer = OMSimplify.ramerDouglasPeuckerSimplify(randomPoints, epsilon: Double(index) )
            print(index,
                  "    \(visvalingam.count)",
                  "    \(radial.count)",
                  "    \(ramer.count)",
                  "    \(decimate.count)")
        }
    }
    
    func testScaledPointsGenerator() {
        let numberOfItems = 300
        let sizes = randomSize(bounded: UIScreen.main.bounds, numberOfItems: numberOfItems)
        let scaler = DiscreteScaledPointsGenerator()
        for size in sizes {
            let randomData = randomFloat(numberOfItems)
            let points  = scaler.makePoints(data: randomData, size: size)
            points.forEach { CGRect(origin: .zero, size: size).contains($0) }
            let points2 = ScaledPointsGenerator(randomData, size: size, insets: .zero).makePoints()
            points2.forEach { CGRect(origin: .zero, size: size).contains($0)}
            XCTAssert(points == points2)
        }
    }

  
    func testEquality() {
        let segment1 = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        let segment2 = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        
        XCTAssert(segment1 == segment2)
    }
    
    func testMidpoint() {
        let segment = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        let actualMidpoint = CGPoint(x: 5.0, y: 5.0)
        
        XCTAssert(segment.midpoint() == actualMidpoint)
    }
    
    func testAngle() {
        // Test vertical
        let vertical = LineSegment(CGPoint(x: 0.0, y: -10.0), CGPoint(x: 0.0, y: 10.0))
        XCTAssert(vertical.angle() == CGFloat(M_PI/2))
        
        // Test horizontal
        let horizontal = LineSegment(CGPoint(x: 0.0, y: -1.0), CGPoint(x: 10.0, y: -1.0))
        XCTAssert(horizontal.angle() == 0)
        
        // Test 45deg or PI/4
        let fortyfive = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        XCTAssert(fortyfive.angle() == CGFloat(M_PI/4.0))
    }
    
    func testLength() {
        let segment = LineSegment(CGPoint(x: 0.0, y: -10.0), CGPoint(x: 0.0, y: 10.0))
        
        XCTAssert(segment.length() == 20.0)
    }
    
    func testTranslate() {
        var segment = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        segment.translateInPlace(dX: -1.0, dY: -1.0)
        
        XCTAssert(segment.p1 == CGPoint(x: -1.0, y: -1.0) && segment.p2 == CGPoint(x: 9.0, y: 9.0))
    }
    
    func testRotate() {
        let segment = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        let rotated = segment.rotate(radians: -CGFloat(M_PI/2), aboutPoint: CGPoint(x: 0.0, y: 0.0))
        
        XCTAssert( rotated.p1 == CGPoint(x: 0, y: 0) && rotated.p2 == CGPoint(x: 10, y: -10))
    }
    
    func testInterpolatePointAtT() {
        let segment = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        let point = segment.interpolatePointAtT(t: 0.5)
        
        XCTAssert(point == CGPoint(x: 5.0, y: 5.0))
    }
    
    func testBounds() {
        let segment = LineSegment(CGPoint(x: -10.0, y: -10.0), CGPoint(x: 10.0, y: 10.0))
        
        XCTAssert(segment.bounds() == CGRect(x: -10.0, y: -10.0, width: 20.0, height: 20.0))
    }
    
    func testPointsOnLineAtDistance() {
        let segment = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 0.0))
        let pts = segment.pointsOnLineAtDistance(distance: 2.0)
        let comparePts = [
            CGPoint(x: 2.0, y: 0.0),
            CGPoint(x: 4.0, y: 0.0),
            CGPoint(x: 6.0, y: 0.0),
            CGPoint(x: 8.0, y: 0.0),
            CGPoint(x: 10.0, y: 0.0)
        ]
        
        XCTAssert(pts == comparePts)
    }
    
    func testIntersectionPointWithLineSegment() {
        // test intersection
        let segment1 = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        let segment2 = LineSegment(CGPoint(x: 0.0, y: 10.0), CGPoint(x: 10.0, y: 0.0))
        
        XCTAssert(segment1.intersectionPointWithLineSegment(segment: segment2)! == CGPoint(x: 5.0, y: 5.0), "Lines should intersection at (5.0, 5.0)")
        
        // test do not intersect
        let segment3 = LineSegment(CGPoint(x: 20.0, y: 20.0), CGPoint(x: 30.0, y: 30.0))
        
        XCTAssert(segment1.intersectionPointWithLineSegment(segment: segment3) == nil, "Lines should not intersection, expected nil")
    }
}

