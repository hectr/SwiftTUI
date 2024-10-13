import AppKit
import SwiftTUI

extension ScrollControl: NSViewConvertible {
    func attributesDiffId() -> Int {
        var hasher = Hasher()
        contentOffset.hash(into: &hasher)
        return hasher.finalize()
    }

    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        let scrollView = VerticalScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Configure the scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false

        return scrollView
    }

    func updateView(_ view: NSView, renderer: AppKitRenderer) {
        guard let scrollView = view as? VerticalScrollView else { return }

        // Add content view
        if let contentView = renderer.view(for: contentControl), contentView.superview == nil {
            let containerView = ScrollFlippedView()
            containerView.translatesAutoresizingMaskIntoConstraints = false

            containerView.addSubview(contentView)

            // Fill containerView constraints
            NSLayoutConstraint.activate([
                contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                contentView.topAnchor.constraint(equalTo: containerView.topAnchor),
                contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            ])

            scrollView.documentView = containerView

            // Fill scrollView constraints
            NSLayoutConstraint.activate([
                containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            ])
        }
    }
}

final private class VerticalScrollView: NSScrollView {}
final private class ScrollFlippedView: NSView {
    override var isFlipped: Bool { true }
}
