import Foundation

let pixelBlockSize = (width: 4.0, height: 8.0)

extension CGPoint {
    init(_ position: Position) {
        self.init(
            x: CGFloat(position.column.intValue) * pixelBlockSize.width,
            y: CGFloat(position.line.intValue) * pixelBlockSize.height
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
