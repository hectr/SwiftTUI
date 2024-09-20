import Foundation

extension DividerControl: LayerDrawing {
    func cell(at position: Position) -> Cell? {
        switch orientation {
        case .horizontal:
            Cell(
                char: style.vertical,
                foregroundColor: color
            )

        case .vertical:
            Cell(
                char: style.horizontal,
                foregroundColor: color
            )
        }
    }
}
