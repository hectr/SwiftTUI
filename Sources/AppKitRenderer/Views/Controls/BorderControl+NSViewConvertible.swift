import AppKit
import SwiftTUI

extension BorderControl: NSViewConvertible {
    func attributesDiffId() -> Int {
        var hasher = Hasher()
        color.hash(into: &hasher)
        style.hash(into: &hasher)
        return hasher.finalize()
    }

    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        let containerView = BorderView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.wantsLayer = true
        
        containerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        containerView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        return containerView
    }
    
    func updateView(_ view: NSView, renderer: AppKitRenderer) {
        guard let containerView = view as? BorderView else { return }

        configureBorder(for: containerView)
        
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
    
    private func configureBorder(for view: NSView) {
        guard let layer = view.layer else { return }
        
        layer.borderColor = NSColor(color)?.cgColor ?? NSColor.textColor.cgColor
        layer.borderWidth = borderWidth(for: style)
        layer.cornerRadius = cornerRadius(for: style)
    }
    
    // Map the style to a border width.
    private func borderWidth(for style: BorderStyle) -> CGFloat {
        switch style {
        case .default:
            return 1.0
        case .rounded:
            return 1.0
        case .heavy:
            return 1.5
        case .double:
            return 2.0
        default:
            return 1.0
        }
    }
    
    /// Map the style to a corner radius.
    private func cornerRadius(for style: BorderStyle) -> CGFloat {
        switch style {
        case .rounded:
            return 5.0
        default:
            return 0.0
        }
    }
}

final private class BorderView: NSView {}
