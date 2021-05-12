import UIKit

// swiftlint:disable identifier_name shorthand_operator
// swiftlint:disable file_length
// swiftlint:disable type_body_length
// swiftlint:disable cyclomatic_complexity

extension Path {
    public enum Element {
        case moveToPoint(point: CGPoint)
        case addLineToPoint(point: CGPoint)
        case addQuadCurveToPoint(destination: CGPoint, control: CGPoint)
        case addCurveToPoint(destination: CGPoint, control1: CGPoint, control2: CGPoint)
        case closeSubpathWithLine
        
        // MARK: - Interface
        
        func lastPoint() -> CGPoint? {
            switch self {
            case let .moveToPoint(point):
                return point
            case let .addLineToPoint(point):
                return point
            case let .addQuadCurveToPoint(destination, _):
                return destination
            case let .addCurveToPoint(destination, _, _):
                return destination
            case .closeSubpathWithLine:
                return nil
            }
        }

        func updateSubpathStart(subpathStart: CGPoint?) -> CGPoint? {
            switch self {
            case let .moveToPoint(point):
                return point
            case .addLineToPoint: fallthrough
            case .addQuadCurveToPoint: fallthrough
            case .addCurveToPoint:
                return subpathStart
            case .closeSubpathWithLine:
                return nil
            }
        }

        func mayContainY(y: Double, ifStartedFrom from: CGPoint?, subpathStartedFrom subpathFrom: CGPoint?) -> Bool {
            switch self {
            case .moveToPoint:
                return false
            case let .addLineToPoint(point):
                if let haveFrom = from {
                    let fromY = Double(haveFrom.y)
                    let toY = Double(point.y)
                    if fromY > toY {
                        return (fromY >= y) && (y <= toY)
                    } else {
                        return (toY >= y) && (y <= fromY)
                    }
                } else {
                    return false
                }
            case .addQuadCurveToPoint: fallthrough
            case .addCurveToPoint:
                // TODO: decision should be based on extremities
                if let _ = from {
                    return true
                } else {
                    return false
                }
            case .closeSubpathWithLine:
                if let
                    haveFrom = from,
                    let haveSubpathStart = subpathFrom {

                    let fromY = Double(haveFrom.y)
                    let toY = Double(haveSubpathStart.y)
                    if fromY > toY {
                        return (fromY >= y) && (y <= toY)
                    } else {
                        return (toY >= y) && (y <= fromY)
                    }
                } else {
                    return false
                }
            }
        }
        
        func percentagesWhereYIs(y: Double, ifStartedFrom from: CGPoint?, subpathStartedFrom subpathFrom: CGPoint?, precalculatedLength: Double) -> [Double] {
            switch self {
            case .moveToPoint:
                return []
            case let .addLineToPoint(point):
                if let haveFrom = from {
                    let a = Double((point.y - haveFrom.y) / (point.x - haveFrom.x))
                    let b = Double(haveFrom.y) - a * Double(haveFrom.x)
                    let x = (y - b) / a
                    
                    let xIsInside: Bool
                    let fromX = Double(haveFrom.y)
                    let toX = Double(point.y)
                    if fromX > toX {
                        if (fromX >= x) && (x <= toX) {
                            xIsInside = true
                        } else {
                            xIsInside = false
                        }
                    } else {
                        if (toX >= x) && (x <= fromX) {
                            xIsInside = true
                        } else {
                            xIsInside = false
                        }
                    }
                    
                    if xIsInside {
                        let dx = x - Double(haveFrom.x)
                        let dy = y - Double(haveFrom.y)
                        let distance = sqrt(dx * dx + dy * dy)
                        return [distance / precalculatedLength]
                    } else {
                        return []
                    }
                } else {
                    return []
                }
            case let .addQuadCurveToPoint(destination, control):
                if let haveFrom = from {
                    let P0 = Double(haveFrom.y)
                    let P1 = Double(control.y)
                    let P2 = Double(destination.y)
                    
                    let a = P0 - 2 * P1 + P2
                    let b = -2 * P0 + 2 * P1
                    let c = P0 - y
                    
                    
                    let roots: Array<Double> = Double.solveQuadraticEquation(solveA: a,
                                                                             solveB: b,
                                                                             solveC: c)
                    let rootsCount = roots.count
                    
                    var result: [Double] = []
                    for i in stride(from: 0, to: rootsCount, by: 1) {
                        let root = roots[i]
                        if (root >= 0) && (root <= 1) {
                            result.append(root)
                        }
                    }

                    return result
                } else {
                    return []
                }
            case let .addCurveToPoint(destination, control1, control2):
                if let haveFrom = from {
                    let P0 = Double(haveFrom.y)
                    let P1 = Double(control1.y)
                    let P2 = Double(control2.y)
                    let P3 = Double(destination.y)
                    
                    let a = -P0 + 3 * P1 - 3 * P2 + P3
                    let b = 3 * P0 - 6 * P1 + 3 * P2
                    let c = -3 * P0 + 3 * P1
                    let d = P0 - y
                    
                    let roots = Double.solveCubicEquation(a: a, b: b, c: c, d: d)
                    let rootsCount = roots.count

                    var result: [Double] = []
                    for i in stride(from: 0, to: rootsCount, by: 1) {
                        let root = roots[i]
                        if (root >= 0) && (root <= 1) {
                            result.append(root)
                        }
                    }

                    return result
                } else {
                    return []
                }
            case .closeSubpathWithLine:
                if let
                    haveFrom = from,
                    let haveTo = subpathFrom {

                    let a = Double((haveTo.y - haveFrom.y) / (haveTo.x - haveFrom.x))
                    let b = Double(haveFrom.y) - a * Double(haveFrom.x)
                    let x = (y - b) / a
                    
                    let xIsInside: Bool
                    let fromX = Double(haveFrom.y)
                    let toX = Double(haveTo.y)
                    if fromX > toX {
                        if (fromX >= x) && (x <= toX) {
                            xIsInside = true
                        } else {
                            xIsInside = false
                        }
                    } else {
                        if (toX >= x) && (x <= fromX) {
                            xIsInside = true
                        } else {
                            xIsInside = false
                        }
                    }
                    
                    if xIsInside {
                        let dx = x - Double(haveFrom.x)
                        let dy = y - Double(haveFrom.y)
                        let distance = sqrt(dx * dx + dy * dy)
                        return [distance / precalculatedLength]
                    } else {
                        return []
                    }
                } else {
                    return []
                }
            }
        }
        
        func pointForPercentage(pathPercent: Double, ifStartedFrom from: CGPoint?, subpathStartedFrom subpathFrom: CGPoint?) -> CGPoint? {
            switch self {
            case .moveToPoint:
                return nil
            case let .addLineToPoint(point):
                if let haveFrom = from {
                    let startX = Double(haveFrom.x)
                    let xFullDistance = Double(point.x) - startX
                    let xCutDistance = xFullDistance * pathPercent
                    let startY = Double(haveFrom.y)
                    let yFullDistance = Double(point.y) - startY
                    let yCutDistance = yFullDistance * pathPercent
                    return CGPoint(x: CGFloat(startX + xCutDistance), y: CGFloat(startY + yCutDistance))
                } else {
                    return nil
                }
            case let .addQuadCurveToPoint(destination, control):
                if let haveFrom = from {
                    let point = Path.pointOfQuad(t: pathPercent, from: haveFrom, to: destination, c: control)
                    return point
                } else {
                    return nil
                }
            case let .addCurveToPoint(destination, control1, control2):
                if let haveFrom = from {
                    let point = Path.pointOfCubic(t: pathPercent, from: haveFrom, to: destination, c1: control1, c2: control2)
                    return point
                } else {
                    return nil
                }
            case .closeSubpathWithLine:
                if let
                    haveFrom = from,
                    let haveTo = subpathFrom {

                    let startX = Double(haveFrom.x)
                    let xFullDistance = Double(haveTo.x) - startX
                    let xCutDistance = xFullDistance * pathPercent
                    let startY = Double(haveFrom.y)
                    let yFullDistance = Double(haveTo.y) - startY
                    let yCutDistance = yFullDistance * pathPercent
                    return CGPoint(x: CGFloat(startX + xCutDistance), y: CGFloat(startY + yCutDistance))
                } else {
                    return nil
                }
            }
        }
    }
}


// swiftlint:enabled identifier_name shorthand_operator
// swiftlint:enabled file_length
// swiftlint:enabled type_body_length
// swiftlint:enabled cyclomatic_complexity
