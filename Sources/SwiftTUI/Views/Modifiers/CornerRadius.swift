import Foundation

public extension View {
    func cornerRadius(_ radius: CGFloat) -> some View {
        return CornerRadius(content: self, radius: radius)
    }
}

private struct CornerRadius<Content: View>: View, PrimitiveView, ModifierView {
    let content: Content
    let radius: CGFloat

    static var size: Int? { Content.size }

    func buildNode(_ node: Node) {
        setupEnvironmentProperties(node: node)
        node.controls = WeakSet<Control>()
        node.addNode(at: 0, Node(view: content.view))
    }

    func updateNode(_ node: Node) {
        setupEnvironmentProperties(node: node)
        node.view = self
        node.children[0].update(using: content.view)
    }

    func passControl(_ control: Control, node: Node) -> Control {
        if let borderControl = control.parent { return borderControl }
        let borderControl = CornerRadiusControl(radius: radius)
        borderControl.addSubview(control, at: 0)
        node.controls?.add(borderControl)
        return borderControl
    }

    private class CornerRadiusControl: Control {
        var radius: CGFloat

        weak var cornerRadiusLayer: CornerRadiusLayer?

        init(radius: CGFloat) {
            self.radius = radius
        }

        override func size(proposedSize: Size) -> Size {
            children[0].size(proposedSize: proposedSize)
        }

        override func layout(size: Size) {
            super.layout(size: size)
            children[0].layout(size: size)
        }

        override func makeLayer() -> Layer {
            let layer = CornerRadiusLayer(radius: radius)
            self.cornerRadiusLayer = layer
            return layer
        }
    }

    private class CornerRadiusLayer: Layer {
        public var radius: CGFloat

        init(radius: CGFloat) {
            self.radius = radius
        }

        override func cell(at position: Position) -> Cell? {
            // Convert Position to CGPoint
            let pixelPosition = CGPoint(position, offset: 0.5)

            // Determine the bounds of the layer
            let layerWidth = CGSize(frame.size).width
            let layerHeight = CGSize(frame.size).height

            // Identify which corners we need to check for clipping
            let topLeftCorner = CGRect(x: 0, y: 0, width: radius, height: radius)
            let topRightCorner = CGRect(x: layerWidth - radius, y: 0, width: radius, height: radius)
            let bottomLeftCorner = CGRect(x: 0, y: layerHeight - radius, width: radius, height: radius)
            let bottomRightCorner = CGRect(x: layerWidth - radius, y: layerHeight - radius, width: radius, height: radius)

            // For each corner, check if the cell is within the clipping area
            if topLeftCorner.contains(pixelPosition) {
                let cornerCenter = CGPoint(x: radius, y: radius)
                if isOutsideCornerRadius(center: cornerCenter, point: pixelPosition) {
                    return nil
                }
            }
            if topRightCorner.contains(pixelPosition) {
                let cornerCenter = CGPoint(x: layerWidth - radius, y: radius)
                if isOutsideCornerRadius(center: cornerCenter, point: pixelPosition) {
                    return nil
                }
            }
            if bottomLeftCorner.contains(pixelPosition) {
                let cornerCenter = CGPoint(x: radius, y: layerHeight - radius)
                if isOutsideCornerRadius(center: cornerCenter, point: pixelPosition) {
                    return nil
                }
            }
            if bottomRightCorner.contains(pixelPosition) {
                let cornerCenter = CGPoint(x: layerWidth - radius, y: layerHeight - radius)
                if isOutsideCornerRadius(center: cornerCenter, point: pixelPosition) {
                    return nil
                }
            }

            // If the cell is not in any clipped corner, return the cell
            return super.cell(at: position)
        }

        /// Checks if a point is outside the corner radius.
        private func isOutsideCornerRadius(center: CGPoint, point: CGPoint) -> Bool {
            // Calculate the distance between the center of the corner and the point
            let distance = sqrt(pow(point.x - center.x, 2) + pow(point.y - center.y, 2))

            // If the distance is greater than the radius, the point is outside the corner radius
            return distance > radius
        }
    }
}

