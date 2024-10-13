import Foundation

extension BorderControl: LayerDrawing {
    func cell(at position: Position) -> Cell? {
        var char: Character?
        if position.line == 0 {
            if position.column == 0 {
                char = style.topLeft
            } else if position.column == layer.frame.size.width - 1 {
                char = style.topRight
            } else {
                char = style.top
            }
        } else if position.line == layer.frame.size.height - 1 {
            if position.column == 0 {
                char = style.bottomLeft
            } else if position.column == layer.frame.size.width - 1 {
                char = style.bottomRight
            } else {
                char = style.bottom
            }
        } else if position.column == 0 {
            char = style.left
        } else if position.column == layer.frame.size.width - 1 {
            char = style.right
        }
        return char.map { Cell(char: $0, foregroundColor: color) }
    }
}
