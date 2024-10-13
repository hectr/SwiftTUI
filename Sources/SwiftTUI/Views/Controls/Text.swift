import Foundation

public struct Text: View, PrimitiveView {
    private var text: String?
    
    private var _attributedText: Any?
    
    @available(macOS 12, *)
    private var attributedText: AttributedString? { _attributedText as? AttributedString }
    
    @Environment(\.foregroundColor) private var foregroundColor: Color
    @Environment(\.bold) private var bold: Bool
    @Environment(\.italic) private var italic: Bool
    @Environment(\.underline) private var underline: Bool
    @Environment(\.strikethrough) private var strikethrough: Bool
    
    public init(_ text: String) {
        self.text = text
    }
    
    @available(macOS 12, *)
    public init(_ attributedText: AttributedString) {
        self._attributedText = attributedText
    }
    
    static var size: Int? { 1 }
    
    func buildNode(_ node: Node) {
        setupEnvironmentProperties(node: node)
        node.control = TextControl(
            text: text,
            attributedText: _attributedText,
            foregroundColor: foregroundColor,
            bold: bold,
            italic: italic,
            underline: underline,
            strikethrough: strikethrough
        )
    }
    
    func updateNode(_ node: Node) {
        setupEnvironmentProperties(node: node)
        node.view = self
        let control = node.control as! TextControl
        control.text = text
        control._attributedText = _attributedText
        control.foregroundColor = foregroundColor
        control.bold = bold
        control.italic = italic
        control.underline = underline
        control.strikethrough = strikethrough
        control.layer.invalidate()
    }
}

public class TextControl: Control {
    public var text: String?

    public var _attributedText: Any?

    @available(macOS 12, *)
    public  var attributedText: AttributedString? { _attributedText as? AttributedString }

    public var foregroundColor: Color
    public var bold: Bool
    public var italic: Bool
    public var underline: Bool
    public var strikethrough: Bool

    init(
        text: String?,
        attributedText: Any?,
        foregroundColor: Color,
        bold: Bool,
        italic: Bool,
        underline: Bool,
        strikethrough: Bool
    ) {
        self.text = text
        self._attributedText = attributedText
        self.foregroundColor = foregroundColor
        self.bold = bold
        self.italic = italic
        self.underline = underline
        self.strikethrough = strikethrough
    }

    public override func size(proposedSize: Size) -> Size {
        return Size(width: Extended(characterCount), height: 1)
    }

    public var characterCount: Int {
        if #available(macOS 12, *), let attributedText {
            return attributedText.characters.count
        }
        return text?.count ?? 0
    }
}
