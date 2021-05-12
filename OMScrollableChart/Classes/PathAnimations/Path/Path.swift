import UIKit


// MARK: - subpaths -

public extension CGPath {
    var subpaths: [UIBezierPath] {
        return Path(cgPath: self).pathsFromElements()
    }
}


// TODO: calculate normals/tangents

// swiftlint:disable identifier_name shorthand_operator
// swiftlint:disable file_length
// swiftlint:disable type_body_length//
public struct Path {
    // MARK: - Interface
    public init(cgPath: CGPath) {
        let pathElements = Path.pathElements(cgPath: cgPath)
        let elementsLengths = Path.calculateLengths(pathElements: pathElements)
        let totalLength = Path.calculateSumOfLengths(lengths: elementsLengths)
        let lengthsPercentages = Path.calculatePercentages(parts: elementsLengths, whole: totalLength)

        elements = pathElements
        lengths = elementsLengths
        length = totalLength
        percentages = lengthsPercentages
    }

    public init(elements pathElements: [Path.Element]) {
        let elementsLengths = Path.calculateLengths(pathElements: pathElements)
        let totalLength = Path.calculateSumOfLengths(lengths: elementsLengths)
        let lengthsPercentages = Path.calculatePercentages(parts: elementsLengths, whole: totalLength)

        elements = pathElements
        lengths = elementsLengths
        length = totalLength
        percentages = lengthsPercentages
    }

    public init(withTimingFunction timingFunctionCA: CAMediaTimingFunction) {
        let P0x: CGFloat
        let P0y: CGFloat
        let P1x: CGFloat
        let P1y: CGFloat
        let P2x: CGFloat
        let P2y: CGFloat
        let P3x: CGFloat
        let P3y: CGFloat

        let controlValues = UnsafeMutablePointer<Float>.allocate(capacity: 2)
        timingFunctionCA.getControlPoint(at: 0, values: controlValues)
        P0x = CGFloat(controlValues[0])
        P0y = CGFloat(controlValues[1])
        timingFunctionCA.getControlPoint(at: 1, values: controlValues)
        P1x = CGFloat(controlValues[0])
        P1y = CGFloat(controlValues[1])
        timingFunctionCA.getControlPoint(at: 2, values: controlValues)
        P2x = CGFloat(controlValues[0])
        P2y = CGFloat(controlValues[1])
        timingFunctionCA.getControlPoint(at: 3, values: controlValues)
        P3x = CGFloat(controlValues[0])
        P3y = CGFloat(controlValues[1])
        controlValues.deallocate()

        let startElement = Path.Element.moveToPoint(point: CGPoint(x: P0x, y: P0y))
        let endElement = Path.Element.addCurveToPoint(
            destination: CGPoint(x: P3x, y: P3y),
            control1: CGPoint(x: P1x, y: P1y),
            control2: CGPoint(x: P2x, y: P2y))

        self.init(elements: [startElement, endElement])
    }
    
    public func destinationPoints() -> [CGPoint] {
        var lastPoint = CGPoint.zero
        var points = [CGPoint]()
        for ele in elements {
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
        
        return points
    }
    public func pathsFromElements() ->  [UIBezierPath] {
        var paths = [UIBezierPath]()
        var lastPoint = CGPoint.zero
        for ele in elements {
            switch ele {
            case .moveToPoint(point: let point):
                lastPoint = point
            case .addLineToPoint(point: let point):
                paths.append(UIBezierPath(pointsForLine: [lastPoint, point]))
                lastPoint = point
            case .addQuadCurveToPoint(destination: let destination, control: let control):
                let path = UIBezierPath()
                path.move(to: lastPoint)
                path.addQuadCurve(to: destination, controlPoint: control)
                paths.append(path)
                lastPoint = destination
            case .addCurveToPoint(destination: let destination, control1: let control1, control2: let control2):
                let path = UIBezierPath()
                path.move(to: lastPoint)
                path.addCurve(to: destination, controlPoint1: control1, controlPoint2: control2)
                paths.append(path)
                lastPoint = destination
            case .closeSubpathWithLine: break
            }
        }
        return paths
    }
    
    public func percentagesWhereYIs(y: Double) -> [Double] {
        var subpathStart: CGPoint?
        var recentPoint: CGPoint?
        var totalPercentage: Double = 0

        let elementCount = elements.count
        var answer: [Double] = []
        for i in 0..<elementCount {
            let element = elements[i]
            let elementPercentage = percentages[i]
            if element.mayContainY(y: y,
                                   ifStartedFrom: recentPoint,
                                   subpathStartedFrom: subpathStart) {
                let elementAnswer = element.percentagesWhereYIs(y: y, ifStartedFrom: recentPoint, subpathStartedFrom: subpathStart, precalculatedLength: lengths[i])
                let answerMapped = elementAnswer.map { totalPercentage + elementPercentage * $0 }
                answer.append(contentsOf: answerMapped)
            }
            recentPoint = element.lastPoint()
            subpathStart = element.updateSubpathStart(subpathStart: subpathStart)
            totalPercentage += elementPercentage
        }

        return answer
    }
    /// pointForPercentage
    /// - Parameters:
    ///   - pathPercent: Double
    ///   - startPoint: CGPoint
    /// - Returns: CGPoint
    public  func pointForPercentage(pathPercent: Double, startPoint: CGPoint? = nil) -> CGPoint? {
        var subpathStart: CGPoint?
        var recentPoint: CGPoint? = startPoint
        var totalPercentage: Double = 0

        let elementCount = elements.count
        for i in 0..<elementCount {
            let element = elements[i]

            let elementPercentage = percentages[i]
            let nextTotalPercentage = totalPercentage + elementPercentage
            if nextTotalPercentage > pathPercent {
                let percentageLeft = pathPercent-totalPercentage
                if (percentageLeft < 0) || (percentageLeft > elementPercentage) || (elementPercentage == 0) {
                    return nil
                } else {
                    let inElementPercentage = percentageLeft / elementPercentage
                    return element.pointForPercentage(pathPercent: inElementPercentage, ifStartedFrom: recentPoint, subpathStartedFrom: subpathStart)
                }
            }

            recentPoint = element.lastPoint()
            subpathStart = element.updateSubpathStart(subpathStart: subpathStart)
            totalPercentage = nextTotalPercentage
        }

        return nil
    }

    // MARK: - Internal
    public  let elements: [Path.Element]
    public  let lengths: [Double]
    public  let length: Double
    public  let percentages: [Double]
}

// MARK: - Routines

// MARK: Init

private extension Path {
    private static func pathElements(cgPath: CGPath) -> [Path.Element] {
        var pathElements: [Path.Element] = []
        withUnsafeMutablePointer(to: &pathElements) {
            (pathElementsPtr: UnsafeMutablePointer<[Path.Element]>) -> Void in

            cgPath.apply(info: pathElementsPtr) {
                (context, cgPathElementPtr: UnsafePointer<CGPathElement>) in
                let cgPathElement = cgPathElementPtr.pointee
                let element: Path.Element
                switch cgPathElement.type {
                case .moveToPoint:
                    let point = cgPathElement.points.pointee
                    element = Path.Element.moveToPoint(point: point)
                case .addLineToPoint:
                    let point = cgPathElement.points.pointee
                    element = Path.Element.addLineToPoint(point: point)
                case .addQuadCurveToPoint:
                    let points = cgPathElement.points
                    let control = points[0]
                    let point = points[1]
                    element = Path.Element.addQuadCurveToPoint(destination: point, control: control)
                case .addCurveToPoint:
                    let points = cgPathElement.points
                    let control1 = points[0]
                    let control2 = points[1]
                    let point = points[2]
                    element = Path.Element.addCurveToPoint(destination: point, control1: control1, control2: control2)
                case .closeSubpath:
                    element = Path.Element.closeSubpathWithLine
                @unknown default:
                    fatalError()
                }

                let elementsPtr = unsafeBitCast(context, to: UnsafeMutablePointer<[Path.Element]>.self)
                elementsPtr.pointee.append(element)
            }
        }

        return pathElements
    }

    // returns array with entry per element, '0' for the first element
    private static func calculateLengths(pathElements: [Path.Element]) -> [Double] {
        var result: [Double] = []
        var subpathStartPoint: CGPoint?
        var recentPoint: CGPoint?
        for element in pathElements {
            if let
                haveRecentPoint = recentPoint,
                let haveSubpathStartPoint = subpathStartPoint
            {
                switch element {
                case let .moveToPoint(point):
                    subpathStartPoint = point
                    result.append(0)
                    recentPoint = point
                case let .addLineToPoint(point):
                    let distance = distanceLinear(from: haveRecentPoint, to: point)
                    result.append(distance)
                    recentPoint = point
                case let .addQuadCurveToPoint(destination, control):
                    let distance = distanceQuad(from: haveRecentPoint, to: destination, control: control)
                    result.append(distance)
                    recentPoint = destination
                case let .addCurveToPoint(destination, control1, control2):
                    let distance = distanceCubic(from: haveRecentPoint, to: destination, control1: control1, control2: control2)
                    result.append(distance)
                    recentPoint = destination
                case .closeSubpathWithLine:
                    let distance = distanceLinear(from: haveRecentPoint, to: haveSubpathStartPoint)
                    subpathStartPoint = nil
                    result.append(distance)
                    recentPoint = nil
                }
            } else {
                switch element {
                case let .moveToPoint(point):
                    subpathStartPoint = point
                    result.append(0)
                    recentPoint = point
                case .addLineToPoint: fallthrough
                case .addQuadCurveToPoint: fallthrough
                case .addCurveToPoint: fallthrough
                case .closeSubpathWithLine:
                    result.append(0)
                }
            }
        }

        return result
    }

    private static func calculateSumOfLengths(lengths: [Double]) -> Double {
        var sum: Double = 0
        for length in lengths {
            sum += length
        }
        return sum
    }

    private static func calculatePercentages(parts: [Double], whole: Double) -> [Double] {
        if whole == 0 {
            // is there better way to do it?
            return parts.map { _ in 0 }
        } else {
            return parts.map { partLength in partLength / whole }
        }
    }
}

// MARK: Distances

extension Path {
    static let flatteningQuality: Int = 32

    static func distanceQuad(from: CGPoint, to: CGPoint, control c: CGPoint) -> Double {
        // may reuse these for optimization
        let segments = segmentsOfQuad(n: flatteningQuality, from: from, to: to, c: c)
        return sumOfSegments(points: segments)
    }

    static func distanceCubic(from: CGPoint, to: CGPoint, control1 c1: CGPoint, control2 c2: CGPoint) -> Double {
        // may reuse these for optimization
        let segments = segmentsOfCubic(n: flatteningQuality, from: from, to: to, c1: c1, c2: c2)
        return sumOfSegments(points: segments)
    }

    static func segmentsOfQuad(n: Int, from: CGPoint, to: CGPoint, c: CGPoint) -> [CGPoint] {
        let start: Double
        let step: Double
        if n < 2 {
            start = 0.5
            step = 1
        } else {
            start = 0
            step = Double(1) / (Double(n)-Double(1))
        }

        var result: [CGPoint] = []

        for i in stride(from: start, to: Double(1), by: step) {
            result.append(pointOfQuad(t: i, from: from, to: to, c: c))
        }
        return result
    }

    static func segmentsOfCubic(n: Int, from: CGPoint, to: CGPoint, c1: CGPoint, c2: CGPoint) -> [CGPoint] {
        let start: Double
        let step: Double
        if n < 2 {
            start = 0.5
            step = 1
        } else {
            start = 0
            step = Double(1) / (Double(n)-Double(1))
        }

        var result: [CGPoint] = []
        for i in stride(from: start, to: Double(1), by: step) {
            result.append(pointOfCubic(t: i, from: from, to: to, c1: c1, c2: c2))
        }
        return result
    }

    static func sumOfSegments(points: [CGPoint]) -> Double {
        let count = points.count
        if count < 2 {
            return 0
        } else {
            var sum: Double = 0.0
            var recentPoint = points[0]
            for i in 1..<count {
                let nextPoint = points[i]
                sum += distanceLinear(from: recentPoint, to: nextPoint)
                recentPoint = nextPoint
            }
            return sum
        }
    }

    static func distanceLinear(from: CGPoint, to: CGPoint) -> Double {
        let xDistance = Double(from.x-to.x)
        let yDistance = Double(from.y-to.y)
        return sqrt(xDistance * xDistance + yDistance * yDistance)
    }

    static func pointOfQuad(t: Double, from: CGPoint, to: CGPoint, c: CGPoint) -> CGPoint {
        let x = bezierValueQuad(t: t, P0: Double(from.x), P1: Double(c.x), P2: Double(to.x))
        let y = bezierValueQuad(t: t, P0: Double(from.y), P1: Double(c.y), P2: Double(to.y))
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }

    static func pointOfCubic(t: Double, from: CGPoint, to: CGPoint, c1: CGPoint, c2: CGPoint) -> CGPoint {
        let x = bezierValueCubic(t: t, P0: Double(from.x), P1: Double(c1.x), P2: Double(c2.x), P3: Double(to.x))
        let y = bezierValueCubic(t: t, P0: Double(from.y), P1: Double(c1.y), P2: Double(c2.y), P3: Double(to.y))
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }

    static func bezierValueQuad(t: Double, P0: Double, P1: Double, P2: Double) -> Double {
        return
            (1-t) * (1-t) * P0
                + 2 * (1-t) * t * P1
                + t * t * P2
    }

    static func bezierValueCubic(t: Double, P0: Double, P1: Double, P2: Double, P3: Double) -> Double {
        return
            (1-t) * (1-t) * (1-t) * P0
                + 3 * (1-t) * (1-t) * t * P1
                + 3 * (1-t) * t * t * P2
                + t * t * t * P3
    }
}

// swiftlint:enabled identifier_name shorthand_operator
// swiftlint:enabled file_length
// swiftlint:enabled type_body_length
