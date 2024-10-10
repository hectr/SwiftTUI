import AppKit
import SwiftTUI

extension TextControl: NSViewConvertible {
    func attributesDiffId() -> Int {
        var hasher = Hasher()
        text.hash(into: &hasher)
        if #available(macOS 12, *) {
            attributedText.hash(into: &hasher)
        }
        foregroundColor.hash(into: &hasher)
        bold.hash(into: &hasher)
        italic.hash(into: &hasher)
        underline.hash(into: &hasher)
        strikethrough.hash(into: &hasher)
        return hasher.finalize()
    }
    
    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        let textField = TextView()
        textField.translatesAutoresizingMaskIntoConstraints = false

        textField.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textField.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        textField.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textField.maximumNumberOfLines = 1
        textField.usesSingleLineMode = true
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.isEditable = false
        textField.isBordered = false
        textField.drawsBackground = false
        
        return textField
    }
    
    func updateView(_ view: NSView, renderer: AppKitRenderer) {
        guard let textField = view as? TextView else { return }

        textField.stringValue = text ?? ""
        applyStyles(to: textField)
    }
    
    private func applyStyles(to textField: NSTextField) {
        var attributes: [NSAttributedString.Key: Any] = [:]
        if bold || italic {
            var fontDescriptor = NSFont.systemFont(ofSize: NSFont.systemFontSize).fontDescriptor
            if bold {
                fontDescriptor = fontDescriptor.withSymbolicTraits(.bold)
            }
            if italic {
                fontDescriptor = fontDescriptor.withSymbolicTraits(.italic)
            }
            textField.font = NSFont(descriptor: fontDescriptor, size: NSFont.systemFontSize)
        }
        if underline {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        if strikethrough {
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
        attributes[.foregroundColor] = NSColor(foregroundColor)
        if let text = text {
            textField.attributedStringValue = NSAttributedString(string: text, attributes: attributes)
        }
    }
}

final private class TextView: NSTextField {}
