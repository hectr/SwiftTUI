import Foundation

extension ColorControl: LayerDrawing {
    func cell(at position: Position) -> Cell? {
        Cell(char: " ", backgroundColor: color)
    }
}
