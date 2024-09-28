import Foundation

/// Calculate point on quadratic Bezier curve at parameter `t`.
///
/// - Parameters:
///   - t: A `CGFloat` value between 0 and 1, representing the position on the curve.
///        t = 0 corresponds to the start point, t = 1 corresponds to the end point.
///   - start: The starting point of the curve.
///   - control: The control point that influences the shape of the curve.
///   - end: The ending point of the curve.
///
/// - Returns: A `CGPoint` representing the location on the curve at the given `t`.
///
func quadCurvePoint(t: CGFloat, start: CGPoint, control: CGPoint, end: CGPoint) -> CGPoint {
    let mt = 1 - t
    let x = mt * mt * start.x + 2 * mt * t * control.x + t * t * end.x
    let y = mt * mt * start.y + 2 * mt * t * control.y + t * t * end.y
    return CGPoint(x: x, y: y)
}

/// Calculate point on cubic Bezier curve at parameter `t`.
///
/// - Parameters:
///   - t: A `CGFloat` value between 0 and 1, representing the position on the curve.
///        t = 0 corresponds to the start point, t = 1 corresponds to the end point.
///   - start: The starting point of the curve.
///   - control1: The first control point influencing the curve.
///   - control2: The second control point influencing the curve.
///   - end: The ending point of the curve.
///
/// - Returns: A `CGPoint` representing the location on the curve at the given `t`.
///
func cubicCurvePoint(t: CGFloat, start: CGPoint, control1: CGPoint, control2: CGPoint, end: CGPoint) -> CGPoint {
    let mt = 1 - t
    let x = mt * mt * mt * start.x + 3 * mt * mt * t * control1.x + 3 * mt * t * t * control2.x + t * t * t * end.x
    let y = mt * mt * mt * start.y + 3 * mt * mt * t * control1.y + 3 * mt * t * t * control2.y + t * t * t * end.y
    return CGPoint(x: x, y: y)
}

/// Calculates the bounding box for a quadratic Bézier curve.
///
/// To find the bounds, the function first computes the extrema (i.e., the points
/// at which the curve changes direction) and then uses them along with the
/// control points to determine the overall bounds.
///
/// - Parameters:
///   - start: The start point of the curve.
///   - control: The control point of the curve.
///   - end: The end point of the curve.
///
/// - Returns: A `CGRect` representing the bounding box of the curve.
func quadraticCurveBounds(from start: CGPoint, control: CGPoint, to end: CGPoint) -> CGRect {
    // Find the extrema
    let tValues = quadraticExtrema(start: start, control: control, end: end)
    var points = [start, end, control]
    for t in tValues where t > 0 && t < 1 {
        let point = quadCurvePoint(t: t, start: start, control: control, end: end)
        points.append(point)
    }
    let xs = points.map { $0.x }
    let ys = points.map { $0.y }
    return CGRect(x: xs.min()!, y: ys.min()!, width: xs.max()! - xs.min()!, height: ys.max()! - ys.min()!)
}

/// Calculates the bounding box for a cubic Bézier curve.
///
/// To find the bounds, the function computes the extrema and uses them along
/// with the control points to determine the overall bounds.
///
/// - Parameters:
///   - start: The start point of the curve.
///   - control1: The first control point of the curve.
///   - control2: The second control point of the curve.
///   - end: The end point of the curve.
///
/// - Returns: A `CGRect` representing the bounding box of the curve.
func cubicCurveBounds(from start: CGPoint, control1: CGPoint, control2: CGPoint, to end: CGPoint) -> CGRect {
    // Find the extrema
    let tValues = cubicExtrema(start: start, control1: control1, control2: control2, end: end)
    var points = [start, end, control1, control2]
    for t in tValues where t > 0 && t < 1 {
        let point = cubicCurvePoint(t: t, start: start, control1: control1, control2: control2, end: end)
        points.append(point)
    }
    let xs = points.map { $0.x }
    let ys = points.map { $0.y }
    return CGRect(x: xs.min()!, y: ys.min()!, width: xs.max()! - xs.min()!, height: ys.max()! - ys.min()!)
}

/// Computes the extrema (i.e., points of directional change) for a quadratic Bézier curve.
///
/// - Parameters:
///   - start: The start point of the curve.
///   - control: The control point of the curve.
///   - end: The end point of the curve.
///
/// - Returns: An array of `CGFloat` values representing the `t` values of the extrema.
private func quadraticExtrema(start: CGPoint, control: CGPoint, end: CGPoint) -> [CGFloat] {
    var tValues: [CGFloat] = []
    for axis in [\CGPoint.x, \CGPoint.y] {
        let a = start[keyPath: axis] - 2 * control[keyPath: axis] + end[keyPath: axis]
        let b = 2 * (control[keyPath: axis] - start[keyPath: axis])
        if a == 0 { continue }
        let t = -b / (2 * a)
        tValues.append(t)
    }
    return tValues
}

/// Computes the extrema (i.e., points of directional change) for a cubic Bézier curve.
///
/// - Parameters:
///   - start: The start point of the curve.
///   - control1: The first control point of the curve.
///   - control2: The second control point of the curve.
///   - end: The end point of the curve.
/// - Returns: An array of `CGFloat` values representing the `t` values of the extrema.
private func cubicExtrema(start: CGPoint, control1: CGPoint, control2: CGPoint, end: CGPoint) -> [CGFloat] {
    var tValues: [CGFloat] = []
    for axis in [\CGPoint.x, \CGPoint.y] {
        let a = -start[keyPath: axis] + 3 * control1[keyPath: axis] - 3 * control2[keyPath: axis] + end[keyPath: axis]
        let b = 3 * start[keyPath: axis] - 6 * control1[keyPath: axis] + 3 * control2[keyPath: axis]
        let c = -3 * start[keyPath: axis] + 3 * control1[keyPath: axis]
        let discriminant = b * b - 4 * a * c
        if discriminant >= 0, a != 0 {
            let sqrtDiscriminant = sqrt(discriminant)
            let t1 = (-b + sqrtDiscriminant) / (2 * a)
            let t2 = (-b - sqrtDiscriminant) / (2 * a)
            tValues.append(contentsOf: [t1, t2])
        } else if a == 0 && b != 0 {
            let t = -c / b
            tValues.append(t)
        }
    }
    return tValues
}
