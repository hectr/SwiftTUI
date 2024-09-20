import Foundation

public struct Position: Equatable {
    public var column: Extended
    public var line: Extended

    public static var zero: Position { Position(column: 0, line: 0) }

    public init(column: Extended, line: Extended) {
        self.column = column
        self.line = line
    }
}

extension Position: CustomStringConvertible {
    public var description: String { "(\(column), \(line))" }
}

extension Position: AdditiveArithmetic {
    public static func +(lhs: Self, rhs: Self) -> Self {
        Position(column: lhs.column + rhs.column, line: lhs.line + rhs.line)
    }

    public static func - (lhs: Position, rhs: Position) -> Position {
        Position(column: lhs.column - rhs.column, line: lhs.line - rhs.line)
    }
}
