import AppKit
import SwiftTUI

extension FlexibleFrameControl: NSViewConvertible {
    func attributesDiffId() -> Int {
        var hasher = Hasher()
        minWidth.hash(into: &hasher)
        maxWidth.hash(into: &hasher)
        minHeight.hash(into: &hasher)
        maxHeight.hash(into: &hasher)
        alignment.hash(into: &hasher)
        return hasher.finalize()
    }

    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        // Create a container view
        let containerView = FlexibleFrameView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        return containerView
    }
    
    func updateView(_ view: NSView, renderer: AppKitRenderer) {
        guard let containerView = view as? FlexibleFrameView else { return }

        // Add child view
        if let childControl = children.first, let childView = renderer.view(for: childControl), childView.superview == nil {
            containerView.subviews.forEach { subview in subview.removeFromSuperview() }
            containerView.addSubview(childView)

            // Apply min and max width and height constraints to containerView
            var constraints: [NSLayoutConstraint] = []
            
            if let minWidth = minWidth, minWidth != .infinity {
                constraints.append(containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: CGFloat(minWidth.intValue) * renderer.pixelBlockSize.width))
            }
            if let maxWidth = maxWidth, maxWidth != .infinity {
                constraints.append(containerView.widthAnchor.constraint(lessThanOrEqualToConstant: CGFloat(maxWidth.intValue) * renderer.pixelBlockSize.width))
            }
            if let minHeight = minHeight, minHeight != .infinity {
                constraints.append(containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: CGFloat(minHeight.intValue) * renderer.pixelBlockSize.height))
            }
            if let maxHeight = maxHeight, maxHeight != .infinity {
                constraints.append(containerView.heightAnchor.constraint(lessThanOrEqualToConstant: CGFloat(maxHeight.intValue) * renderer.pixelBlockSize.height))
            }
            
            // Align childView within containerView based on alignment
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
            
            NSLayoutConstraint.activate(constraints + childConstraints)
        }
    }
}

final private class FlexibleFrameView: NSView {}
