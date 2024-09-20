import Foundation

public struct Rect: Equatable {
    public var position: Position
    public var size: Size

    public init(position: Position, size: Size) {
        self.position = position
        self.size = size
    }

    public init(minColumn: Extended, minLine: Extended, maxColumn: Extended, maxLine: Extended) {
        self.position = Position(column: minColumn, line: minLine)
        self.size = Size(width: maxColumn - minColumn + 1, height: maxLine - minLine + 1)
    }

    public init(column: Extended, line: Extended, width: Extended, height: Extended) {
        self.position = Position(column: column, line: line)
        self.size = Size(width: width, height: height)
    }

    public static var zero: Rect { Rect(position: .zero, size: .zero) }

    public var minLine: Extended { position.line }
    public var minColumn: Extended { position.column }
    public var maxLine: Extended { position.line + size.height - 1 }
    public var maxColumn: Extended { position.column + size.width - 1 }

    /// The smallest rectangle that contains the two source rectangles.
    public func union(_ r2: Rect) -> Rect {
        Rect(minColumn: min(minColumn, r2.minColumn),
             minLine: min(minLine, r2.minLine),
             maxColumn: max(maxColumn, r2.maxColumn),
             maxLine: max(maxLine, r2.maxLine))
    }

    public func contains(_ position: Position) -> Bool {
        position.column >= minColumn &&
        position.line >= minLine &&
        position.column <= maxColumn &&
        position.line <= maxLine
    }
}

extension Rect: CustomStringConvertible {
    public var description: String { "\(position) \(size)" }
}
