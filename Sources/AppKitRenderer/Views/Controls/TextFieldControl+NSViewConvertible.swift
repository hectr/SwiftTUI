import AppKit
import SwiftTUI

private var delegateViewAssociationKey: UInt8 = 0

extension TextFieldControl: NSViewConvertible {
    func attributesDiffId() -> Int {
        var hasher = Hasher()
        ObjectIdentifier(self).hash(into: &hasher)
        text.hash(into: &hasher)
        placeholderColor.hash(into: &hasher)
        placeholder.hash(into: &hasher)
        return hasher.finalize()
    }

    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        let textField = TextFieldView()
        textField.translatesAutoresizingMaskIntoConstraints = false

        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textField.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        let handler = TextFieldEventHandler(control: self)
        textFieldEventHanlder = handler
        textField.delegate = handler
        textField.target = handler
        textField.action = #selector(TextFieldEventHandler.didEndEditing)

        textField.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textField.maximumNumberOfLines = 1
        textField.cell?.wraps = false
        textField.usesSingleLineMode = true
        textField.cell?.isScrollable = true
        textField.focusRingType = .none
        textField.isBezeled = false
        textField.drawsBackground = false

        return textField
    }

    func updateView(_ view: NSView, renderer: AppKitRenderer) {
        guard let textField = view as? TextFieldView else { return }

        textField.stringValue = text
        textField.placeholderAttributedString = NSAttributedString(string: placeholder, attributes: [.foregroundColor: NSColor(placeholderColor)])
    }

    fileprivate var textFieldEventHanlder: TextFieldEventHandler? {
        set { objc_setAssociatedObject(self, &delegateViewAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
        get { objc_getAssociatedObject(self, &delegateViewAssociationKey) as? TextFieldEventHandler }
    }
}

final private class TextFieldEventHandler: NSObject, NSTextFieldDelegate {
    weak var control: TextFieldControl?

    init(control: TextFieldControl) {
           self.control = control
    }

    public func controlTextDidChange(_ obj: Notification) {
        guard let control, let textField = obj.object as? NSTextField else { return }

        control.text = textField.stringValue
    }

    @objc func didEndEditing() {
        guard let control else { return }

        control.becomeFirstResponder()
        control.handleEvent("\n")
        (control.appKitView as? TextFieldView)?.stringValue = ""
    }
}

final private class TextFieldView: NSTextField {}
