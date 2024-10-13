import Foundation

extension Layer: LayerDrawing {
    func cell(at position: Position) -> Cell? {
        var cell: Cell? = nil

        // Draw children
        for child in children.reversed() {
            guard child.frame.contains(position) else { continue }
            let position = position - child.frame.position
            if let childCell = child.cell(at: position) {
                if cell == nil {
                    cell = childCell
                }
                if let backgroundColor = childCell.backgroundColor {
                    cell?.backgroundColor = backgroundColor
                    break
                }
            }
        }

        // Draw layer content as background
        if let contentCell = content?._cell(at: position) {
            if cell == nil {
                cell = contentCell
            }
            if cell?.backgroundColor == nil, let backgroundColor = contentCell.backgroundColor {
                cell?.backgroundColor = backgroundColor
            }
        }

        if let buttonLayer = self as? ButtonLayer, buttonLayer.highlighted {
            cell?.attributes.inverted.toggle()
        }

        return cell
    }
}
