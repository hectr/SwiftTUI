import AppKit
import SwiftTUI

extension PaddingControl: NSViewConvertible {
    func attributesDiffId() -> Int {
        var hasher = Hasher()
        edges.hash(into: &hasher)
        length.hash(into: &hasher)
        return hasher.finalize()
    }

    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        let containerView = PaddingView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        return containerView
    }
    
    func updateView(_ view: NSView, renderer: AppKitRenderer) {
        guard let containerView = view as? PaddingView else { return }

        // Add child view
        if let childControl = children.first, let childView = renderer.view(for: childControl), childView.superview == nil {
            containerView.subviews.forEach { subview in subview.removeFromSuperview() }
            containerView.addSubview(childView)

            // Calculate padding lengths
            let horizontalPaddingLength = CGFloat(length?.intValue ?? defaultLength.intValue) * renderer.pixelBlockSize.width
            let verticalPaddingLength = CGFloat(length?.intValue ?? defaultLength.intValue) * renderer.pixelBlockSize.height
            
            // Set padding constraints based on `edges` and `length`
            var constraints: [NSLayoutConstraint] = []
            
            if edges.contains(.left) {
                constraints.append(childView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: horizontalPaddingLength))
            } else {
                constraints.append(childView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor))
            }
            
            if edges.contains(.right) {
                constraints.append(childView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -horizontalPaddingLength))
            } else {
                constraints.append(childView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor))
            }
            
            if edges.contains(.top) {
                constraints.append(childView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: verticalPaddingLength))
            } else {
                constraints.append(childView.topAnchor.constraint(equalTo: containerView.topAnchor))
            }
            
            if edges.contains(.bottom) {
                constraints.append(childView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -verticalPaddingLength))
            } else {
                constraints.append(childView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor))
            }
            
            NSLayoutConstraint.activate(constraints)
        }
    }
}

final private class PaddingView: NSStackView {}
