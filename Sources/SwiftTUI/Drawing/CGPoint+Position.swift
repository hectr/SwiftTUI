import Foundation

let pixelBlockSize = (width: 4.0, height: 8.0)

extension CGPoint {
    init(_ position: Position, offset: CGFloat = 0) {
        self.init(
            x: (CGFloat(position.column.intValue) + offset) * pixelBlockSize.width,
            y: (CGFloat(position.line.intValue) + offset) * pixelBlockSize.height
        )
    }
}

extension Position {
    init(_ point: CGPoint) {
        self.init(
            column: Extended(Int(point.x / pixelBlockSize.width)),
            line: Extended(Int(point.y / pixelBlockSize.height))
        )
    }
}
