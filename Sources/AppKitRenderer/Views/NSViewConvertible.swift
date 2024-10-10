import AppKit

protocol NSViewConvertible {
    /// Do not call directly. Use `Control.diffId()` instead.
    func attributesDiffId() -> Int

    /// Do not call directly. Use `AppKitRenderer.view(for:)` instead.
    func makeNSView(renderer: AppKitRenderer) -> NSView?

    /// Do not call directly. Use `AppKitRenderer.view(for:)` instead.
    func updateView(_ view: NSView, renderer: AppKitRenderer)
}
