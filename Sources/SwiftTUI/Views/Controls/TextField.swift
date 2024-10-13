import Foundation

public struct TextField: View, PrimitiveView {
    public let placeholder: String?
    public let action: (String) -> Void

    @Environment(\.placeholderColor) private var placeholderColor: Color

    public init(placeholder: String? = nil, action: @escaping (String) -> Void) {
        self.placeholder = placeholder
        self.action = action
    }

    static var size: Int? { 1 }

    func buildNode(_ node: Node) {
        setupEnvironmentProperties(node: node)
        node.control = TextFieldControl(placeholder: placeholder ?? "", placeholderColor: placeholderColor, action: action)
    }

    func updateNode(_ node: Node) {
        setupEnvironmentProperties(node: node)
        node.view = self
        (node.control as! TextFieldControl).action = action
    }
}

public class TextFieldControl: Control {
    public var placeholder: String
    public var placeholderColor: Color
    public var action: (String) -> Void

    public var text: String = ""

    init(placeholder: String, placeholderColor: Color, action: @escaping (String) -> Void) {
        self.placeholder = placeholder
        self.placeholderColor = placeholderColor
        self.action = action
    }

    public override func size(proposedSize: Size) -> Size {
        return Size(width: Extended(max(text.count, placeholder.count)) + 1, height: 1)
    }

    public override func handleEvent(_ char: Character) {
        if char == "\n" {
            action(text)
            self.text = ""
            layer.invalidate()
            return
        }

        if char == ASCII.DEL {
            if !self.text.isEmpty {
                self.text.removeLast()
                layer.invalidate()
            }
            return
        }

        self.text += String(char)
        layer.invalidate()
    }

    public override var selectable: Bool { true }

    public override func becomeFirstResponder() {
        super.becomeFirstResponder()
        layer.invalidate()
    }

    public override func resignFirstResponder() {
        super.resignFirstResponder()
        layer.invalidate()
    }
}

extension EnvironmentValues {
    public var placeholderColor: Color {
        get { self[PlaceholderColorEnvironmentKey.self] }
        set { self[PlaceholderColorEnvironmentKey.self] = newValue }
    }
}

private struct PlaceholderColorEnvironmentKey: EnvironmentKey {
    static var defaultValue: Color { .default }
}
