import Foundation

extension TextControl: LayerDrawing {
    func cell(at position: Position) -> Cell? {
        guard position.line == 0 else { return nil }
        guard position.column < Extended(characterCount) else { return .init(char: " ") }
        if #available(macOS 12, *), let attributedText {
            let characters = attributedText.characters
            let i = characters.index(characters.startIndex, offsetBy: position.column.intValue)
            let char = attributedText[i ..< characters.index(after: i)]
            let cellAttributes = CellAttributes(
                bold: char.bold ?? bold,
                italic: char.italic ?? italic,
                underline: char.underline ?? underline,
                strikethrough: char.strikethrough ?? strikethrough,
                inverted: char.inverted ?? false
            )
            return Cell(
                char: char.characters[char.startIndex],
                foregroundColor: char.foregroundColor ?? foregroundColor,
                backgroundColor: char.backgroundColor,
                attributes: cellAttributes
            )
        }
        if let text {
            let cellAttributes = CellAttributes(
                bold: bold,
                italic: italic,
                underline: underline,
                strikethrough: strikethrough
            )
            return Cell(
                char: text[text.index(text.startIndex, offsetBy: position.column.intValue)],
                foregroundColor: foregroundColor,
                attributes: cellAttributes
            )
        }
        return nil
    }
}
