import AppKit
import SwiftTUI

extension BackgroundControl: NSViewConvertible {
    func attributesDiffId() -> Int {
        var hasher = Hasher()
        color.hash(into: &hasher)
        return hasher.finalize()
    }

    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        let containerView = BackgroundView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.wantsLayer = true

        containerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        containerView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        return containerView
    }
    
    func updateView(_ view: NSView, renderer: AppKitRenderer) {
        guard let containerView = view as? BackgroundView else { return }

        containerView.layer?.backgroundColor = NSColor(color)?.cgColor ?? NSColor.textColor.cgColor

        // Add child view
        if let childControl = children.first, let childView = renderer.view(for: childControl), childView.superview == nil {
            containerView.subviews.forEach { subview in subview.removeFromSuperview() }
            containerView.addSubview(childView)

            // Fill containerView constraints
            NSLayoutConstraint.activate([
                childView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                childView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                childView.topAnchor.constraint(equalTo: containerView.topAnchor),
                childView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            ])
        }
    }
}

final private class BackgroundView: NSView {}
