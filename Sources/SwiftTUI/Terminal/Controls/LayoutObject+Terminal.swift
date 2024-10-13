import Foundation

extension LayoutObject {
    func _cell(at position: Position) -> Cell? {
        if let layerDrawing = self as? LayerDrawing {
            return layerDrawing.cell(at: position)
        } else {
            return nil
        }
    }
}
