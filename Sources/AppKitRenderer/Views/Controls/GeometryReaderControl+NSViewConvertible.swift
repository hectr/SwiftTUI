import AppKit
import SwiftTUI

extension GeometryReaderControl: NSViewConvertible {
    func attributesDiffId() -> Int { 0 }
    
    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        let containerView = GeometryReaderView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        return containerView
    }
    
    func updateView(_ view: NSView, renderer: AppKitRenderer) {
        guard let containerView = view as? GeometryReaderView else { return }
        
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

final private class GeometryReaderView: NSView {}
