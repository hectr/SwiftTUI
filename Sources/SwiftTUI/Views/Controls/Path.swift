import Foundation

public struct Path: View, PrimitiveView {
    private enum PathElement {
        case move(to: CGPoint)
        case line(to: CGPoint)
        case quadCurve(to: CGPoint, control: CGPoint)
        case curve(to: CGPoint, control1: CGPoint, control2: CGPoint)
    }

    private var elements: [PathElement] = []

    public init() {}

    public init(_ callback: (inout Path) -> ()) {
        var path = Path()
        callback(&path)
        self = path
    }

    public mutating func move(to point: CGPoint) {
        elements.append(.move(to: point))
    }

    public mutating func move(to position: Position) {
        elements.append(.move(to: CGPoint(position)))
    }

    public mutating func addLine(to point: CGPoint) {
        elements.append(.line(to: point))
    }

    public mutating func addLine(to position: Position) {
        elements.append(.line(to: CGPoint(position)))
    }

    public mutating func addQuadCurve(to point: CGPoint, control: CGPoint) {
        elements.append(.quadCurve(to: point, control: control))
    }

    public mutating func addQuadCurve(to position: Position, control: Position) {
        elements.append(.quadCurve(to: CGPoint(position), control: CGPoint(control)))
    }

    public mutating func addCurve(to point: CGPoint, control1: CGPoint, control2: CGPoint) {
        elements.append(.curve(to: point, control1: control1, control2: control2))
    }

    public mutating func addCurve(to position: Position, control1: Position, control2: Position) {
        elements.append(.curve(to: CGPoint(position), control1: CGPoint(control1), control2: CGPoint(control2)))
    }

    static var size: Int? { 1 }

    func buildNode(_ node: Node) {
        node.control = PathControl(elements: elements)
    }

    func updateNode(_ node: Node) {
        let control = node.control as! PathControl
        control.elements = elements
        control.layer.invalidate()
        node.view = self
    }

    private class PathControl: Control {
        var elements: [PathElement]

        private var brailleCells: [Position: UInt8] = [:]

        init(elements: [PathElement]) {
            self.elements = elements
        }

        override func size(proposedSize: Size) -> Size {
            var minX: CGFloat = CGFloat.infinity
            var minY: CGFloat = CGFloat.infinity
            var maxX: CGFloat = -CGFloat.infinity
            var maxY: CGFloat = -CGFloat.infinity

            var currentPoint = CGPoint.zero

            for element in elements {
                switch element {
                case .move(to: let point):
                    currentPoint = point
                    minX = min(minX, point.x)
                    minY = min(minY, point.y)
                    maxX = max(maxX, point.x)
                    maxY = max(maxY, point.y)
                case .line(to: let point):
                    minX = min(minX, currentPoint.x, point.x)
                    minY = min(minY, currentPoint.y, point.y)
                    maxX = max(maxX, currentPoint.x, point.x)
                    maxY = max(maxY, currentPoint.y, point.y)
                    currentPoint = point
                case .quadCurve(to: let point, control: let controlPoint):
                    // Compute the extrema of the quadratic curve
                    let curveBounds = quadraticCurveBounds(from: currentPoint, control: controlPoint, to: point)
                    minX = min(minX, curveBounds.minX)
                    minY = min(minY, curveBounds.minY)
                    maxX = max(maxX, curveBounds.maxX)
                    maxY = max(maxY, curveBounds.maxY)
                    currentPoint = point
                case .curve(to: let point, control1: let cp1, control2: let cp2):
                    // Compute the extrema of the cubic curve
                    let curveBounds = cubicCurveBounds(from: currentPoint, control1: cp1, control2: cp2, to: point)
                    minX = min(minX, curveBounds.minX)
                    minY = min(minY, curveBounds.minY)
                    maxX = max(maxX, curveBounds.maxX)
                    maxY = max(maxY, curveBounds.maxY)
                    currentPoint = point
                }
            }

            let bounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

            // Adjusted to cell size
            return Size(
                width: Extended(Int(ceil(bounds.maxX / pixelBlockSize.width))),
                height: Extended(Int(ceil(bounds.maxY / pixelBlockSize.height)))
            )
        }

        override func layout(size: Size) {
            super.layout(size: size)
            rasterizePath()
        }

        func rasterizePath() {
            brailleCells.removeAll()
            var currentPoint = CGPoint.zero
            for element in elements {
                switch element {
                case .move(to: let point):
                    currentPoint = point
                case .line(to: let point):
                    rasterizeLine(from: currentPoint, to: point)
                    currentPoint = point
                case .quadCurve(to: let point, control: let controlPoint):
                    let points = approximateQuadCurve(from: currentPoint, to: point, control: controlPoint)
                    rasterizePoints(points)
                    currentPoint = point
                case .curve(to: let point, control1: let control1, control2: let control2):
                    let points = approximateCubicCurve(from: currentPoint, to: point, control1: control1, control2: control2)
                    rasterizePoints(points)
                    currentPoint = point
                }
            }
        }

        func rasterizePoints(_ points: [CGPoint]) {
            guard points.count > 1 else { return }
            for i in 0..<(points.count - 1) {
                rasterizeLine(from: points[i], to: points[i+1])
            }
        }

        func rasterizeLine(from start: CGPoint, to end: CGPoint) {
            // We'll sample points along the line at a higher resolution
            let distance = hypot(end.x - start.x, end.y - start.y)
            let steps = Int(distance / min(pixelBlockSize.width, pixelBlockSize.height)) * 4
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let x = start.x + t * (end.x - start.x)
                let y = start.y + t * (end.y - start.y)
                setBrailleDot(at: CGPoint(x: x, y: y))
            }
        }

        func setBrailleDot(at point: CGPoint) {
            // Map point to cell position
            let cellPosition = Position(point)

            // Compute position within cell
            let xInCell = point.x.truncatingRemainder(dividingBy: pixelBlockSize.width)
            let yInCell = point.y.truncatingRemainder(dividingBy: pixelBlockSize.height)

            // Map to Braille dot position
            let braileCharacterDimensions = (width: 2.0, height: 4.0)
            let conversionFactor = (
                width: pixelBlockSize.width/braileCharacterDimensions.width,
                height: pixelBlockSize.height / braileCharacterDimensions.height
            )
            let brailleX = Int(xInCell / conversionFactor.width) // 0 or 1
            let brailleY = Int(yInCell / conversionFactor.height) // 0 to 3

            // Compute dot number
            let dotNumber = brailleDotNumber(x: brailleX, y: brailleY)

            // Update the brailleCells dictionary
            brailleCells[cellPosition, default: 0] |= dotNumber
        }

        func brailleDotNumber(x: Int, y: Int) -> UInt8 {
            // Mapping from (x, y) to dot number
            switch (x, y) {
            case (0, 0): return 0b00000001 // Dot 1
            case (0, 1): return 0b00000010 // Dot 2
            case (0, 2): return 0b00000100 // Dot 3
            case (0, 3): return 0b01000000 // Dot 7
            case (1, 0): return 0b00001000 // Dot 4
            case (1, 1): return 0b00010000 // Dot 5
            case (1, 2): return 0b00100000 // Dot 6
            case (1, 3): return 0b10000000 // Dot 8
            default: return 0
            }
        }

        override func cell(at position: Position) -> Cell? {
            if let dots = brailleCells[position], dots != 0 {
                // Compute the Unicode scalar value for the Braille character
                let braillePatternBlank: UInt32 = 0x2800
                let value = braillePatternBlank + UInt32(dots)
                guard let unicodeScalar = UnicodeScalar(value) else {
                    assertionFailure("Invalid Unicode scalar value: \(value)")
                    return nil
                }
                let brailleChar = Character(unicodeScalar)
                return Cell(char: brailleChar)
            } else {
                return nil
            }
        }

        private func approximateQuadCurve(from start: CGPoint, to end: CGPoint, control: CGPoint, steps: Int = 20) -> [CGPoint] {
            var points: [CGPoint] = []
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let point = quadCurvePoint(t: t, start: start, control: control, end: end)
                points.append(point)
            }
            return points
        }

        private func approximateCubicCurve(from start: CGPoint, to end: CGPoint, control1: CGPoint, control2: CGPoint, steps: Int = 20) -> [CGPoint] {
            var points: [CGPoint] = []
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let point = cubicCurvePoint(t: t, start: start, control1: control1, control2: control2, end: end)
                points.append(point)
            }
            return points
        }
    }
}
