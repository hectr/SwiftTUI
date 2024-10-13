import Foundation

extension Window: LayerDrawing {
    func cell(at position: Position) -> Cell? {
        Cell(char: " ")
    }
}
