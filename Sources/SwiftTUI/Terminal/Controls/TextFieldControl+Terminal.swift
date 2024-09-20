import Foundation

extension TextFieldControl: LayerDrawing {
    func cell(at position: Position) -> Cell? {
        guard position.line == 0 else { return nil }
        if text.isEmpty {
            if position.column.intValue < placeholder.count {
                let showUnderline = (position.column.intValue == 0) && isFirstResponder
                let char = placeholder[placeholder.index(placeholder.startIndex, offsetBy: position.column.intValue)]
                return Cell(
                    char: char,
                    foregroundColor: placeholderColor,
                    attributes: CellAttributes(underline: showUnderline)
                )
            }
            return .init(char: " ")
        }
        if position.column.intValue == text.count, isFirstResponder { return Cell(char: " ", attributes: CellAttributes(underline: true)) }
        guard position.column.intValue < text.count else { return .init(char: " ") }
        return Cell(char: text[text.index(text.startIndex, offsetBy: position.column.intValue)])
    }
}
