import AppKit
import SwiftTUI

extension FixedFrameControl: NSViewConvertible {
    func attributesDiffId() -> Int {
        var hasher = Hasher()
        width.hash(into: &hasher)
        height.hash(into: &hasher)
        alignment.hash(into: &hasher)
        return hasher.finalize()
    }

    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        // Create a container view
        let containerView = FixedFrameView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        return containerView
    }
    
    func updateView(_ view: NSView, renderer: AppKitRenderer) {
        guard let containerView = view as? FixedFrameView else { return }

        // Add child view
        if let childControl = children.first, let childView = renderer.view(for: childControl), childView.superview == nil {
            containerView.subviews.forEach { subview in subview.removeFromSuperview() }
            containerView.addSubview(childView)

            // Fixed width and height for containerView
            var constraints: [NSLayoutConstraint] = []
            
            if let width = width {
                constraints.append(containerView.widthAnchor.constraint(equalToConstant: CGFloat(width.intValue) * renderer.pixelBlockSize.width))
            }
            if let height = height {
                constraints.append(containerView.heightAnchor.constraint(equalToConstant: CGFloat(height.intValue) * renderer.pixelBlockSize.height))
            }
            
            // Fill containerView constraints
            let fillConstraints = [
                childView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                childView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                childView.topAnchor.constraint(equalTo: containerView.topAnchor),
                childView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            ]
            fillConstraints.forEach { constraint in
                constraint.priority = .defaultHigh
            }

            // Align within containerView
            var childConstraints: [NSLayoutConstraint] = []
            
            switch alignment.horizontalAlignment {
            case .leading:
                childConstraints.append(childView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor))
            case .center:
                childConstraints.append(childView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor))
            case .trailing:
                childConstraints.append(childView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor))
            }
            
            switch alignment.verticalAlignment {
            case .top:
                childConstraints.append(childView.topAnchor.constraint(equalTo: containerView.topAnchor))
            case .center:
                childConstraints.append(childView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor))
            case .bottom:
                childConstraints.append(childView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor))
            }
            
            NSLayoutConstraint.activate(constraints + fillConstraints + childConstraints)
        }
    }
}

final private class FixedFrameView: NSView {}
