import AppKit
import SwiftTUI

extension OnAppearControl: NSViewConvertible {
    func attributesDiffId() -> Int {
        ObjectIdentifier(self).hashValue
    }
    
    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        let onAppearView = OnAppearView()
        onAppearView.translatesAutoresizingMaskIntoConstraints = false
        
        return onAppearView
    }
    
    func updateView(_ view: NSView, renderer: AppKitRenderer) {
        guard let onAppearView = view as? OnAppearView else { return }

        onAppearView.onAppear = action
        
        // Add child view
        if let childControl = children.first, let childView = renderer.view(for: childControl), childView.superview == nil {
            onAppearView.subviews.forEach { subview in subview.removeFromSuperview() }
            onAppearView.addSubview(childView)

            // Fill onAppearView constraints
            NSLayoutConstraint.activate([
                childView.leadingAnchor.constraint(equalTo: onAppearView.leadingAnchor),
                childView.trailingAnchor.constraint(equalTo: onAppearView.trailingAnchor),
                childView.topAnchor.constraint(equalTo: onAppearView.topAnchor),
                childView.bottomAnchor.constraint(equalTo: onAppearView.bottomAnchor),
            ])
        }
    }
}

final private class OnAppearView: NSView {
    var onAppear: (() -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            onAppear?()
        }
    }
}
