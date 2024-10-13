import Foundation

extension BackgroundControl: LayerDrawing {
    func cell(at position: Position) -> Cell? {
        Cell(char: " ", backgroundColor: color)
    }
}
