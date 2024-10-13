import Foundation

public class Window: LayoutObject {
    public private(set) lazy var layer: Layer = makeLayer()

    public private(set) var controls: [Control] = []

    public var firstResponder: Control?

    func addControl(_ control: Control) {
        control.window = self
        self.controls.append(control)
        layer.addLayer(control.layer, at: 0)
    }

    private func makeLayer() -> Layer {
        let layer = Layer()
        layer.content = self
        return layer
    }
}
