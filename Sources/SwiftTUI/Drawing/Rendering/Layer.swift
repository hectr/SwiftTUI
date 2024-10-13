import Foundation

public class Layer {
    public private(set) var children: [Layer] = []
    private(set) var parent: Layer?

    public weak var content: LayoutObject?

    public var invalidated: Rect?

    public weak var renderer: Renderer?

    public var frame: Rect = .zero {
        didSet {
            if oldValue != frame {
                parent?.invalidate(rect: oldValue)
                parent?.invalidate(rect: frame)
            }
        }
    }

    public func addLayer(_ layer: Layer, at index: Int) {
        self.children.insert(layer, at: index)
        layer.parent = self
    }

    public func removeLayer(at index: Int) {
        children[index].parent = nil
        self.children.remove(at: index)
    }

    public func invalidate() {
        invalidate(rect: Rect(position: .zero, size: frame.size))
    }

    /// This recursively invalidates the same rect in the parent, in the
    /// parent's coordinate system.
    /// If the parent is the root layer, it sets the `invalidated` rect instead.
    public func invalidate(rect: Rect) {
        if let parent = self.parent {
            parent.invalidate(rect: Rect(position: rect.position + frame.position, size: rect.size))
            return
        }
        renderer?.application?.scheduleUpdate()
        guard let invalidated = self.invalidated else {
            self.invalidated = rect
            return
        }
        self.invalidated = rect.union(invalidated)
    }
}
