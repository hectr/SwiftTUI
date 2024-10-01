import Foundation

extension CGRect {
    init(_ rect: Rect) {
        self.init(
            origin: CGPoint(rect.position),
            size: CGSize(rect.size)
        )
    }
}

extension Rect {
    init(_ rect: CGRect) {
        self.init(
            position: Position(rect.origin),
            size: Size(rect.size)
        )
    }
}
