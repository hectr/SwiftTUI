import AppKit
import SwiftTUI

extension ButtonControl: NSViewConvertible {
    func attributesDiffId() -> Int {
        ObjectIdentifier(self).hashValue
    }
    
    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        let button = ButtonView()
        button.translatesAutoresizingMaskIntoConstraints = false

        button.target = self
        button.action = #selector(buttonClicked)
        
        button.title = ""
        button.bezelStyle = .shadowlessSquare
        button.showsBorderOnlyWhileMouseInside = true
        
        return button
    }
    
    func updateView(_ view: NSView, renderer: AppKitRenderer) {
        guard let button = view as? ButtonView else { return }

        // Add child view
        if let childControl = children.first, let childView = renderer.view(for: childControl), childView.superview?.superview == nil {
            button.subviews.forEach { subview in subview.removeFromSuperview() }
            addLabel(view: childView, to: button)
        }
    }
    
    private func addLabel(view labelView: NSView, to button: NSButton) {
        // Create a container for custom content
        let containerView = ButtonLabelView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Add labelView to containerView
        containerView.addSubview(labelView)
        
        // Fill containerView constraints
        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            labelView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            labelView.topAnchor.constraint(equalTo: containerView.topAnchor),
            labelView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        
        // Add containerView to button
        button.addSubview(containerView)
        
        // Fill button constraints
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: button.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
        ])
    }
    
    @objc private func buttonClicked() {
        becomeFirstResponder()
        handleEvent("\n")
    }
}

final private class ButtonView: NSButton {}
final private class ButtonLabelView: NSView {}
