import AppKit
import SwiftTUI

public class AppKitRenderer: NSObject, Renderer {
    public static let defaultWindowSize = NSSize(width: 800, height: 600)
    public static let defaultPixelBlockSize = NSSize(width: 8, height: 12)

    public let pixelBlockSize: NSSize

    public weak var application: Application?

    private var rootControl: (Control & NSViewConvertible)?
    private var window: NSWindow?

    private let initialWindowSize: NSSize

    public init(windowSize: NSSize = AppKitRenderer.defaultWindowSize, pixelBlockSize: NSSize = AppKitRenderer.defaultPixelBlockSize) {
        self.initialWindowSize = windowSize
        self.pixelBlockSize = pixelBlockSize
    }

    public func start(with layer: Layer) {
        setupWindow()
        layer.renderer = self
        if let control = layer.content as? Control ?? (layer.content as? Window)?.controls.first, let rootControlView = view(for: control) {
            rootControl = control as? Control & NSViewConvertible
            window?.contentView = rootControlView
            window?.makeKeyAndOrderFront(nil)
        }
    }

    public func update() {
        if let rootControl, let view = rootControl.appKitView, rootControl.appKitView?.controlDiffId != rootControl.diffId() {
            rootControl.updateView(view, renderer: self)
            rootControl.appKitView?.controlDiffId = rootControl.diffId()
        }
    }

    public func stop() {
        window?.close()
        window = nil
    }

    public func handleWindowSizeChange() {
        // AppKit handles window resizing
    }

    func view(for control: Control) -> NSView? {
        guard let control = control as? Control & NSViewConvertible else {
            return nil
        }

        guard let view = control.appKitView ?? control.makeNSView(renderer: self) else {
            return nil
        }
        
        view.vNodeId = control.vNodeId
        control.appKitView = view
        
        if view.controlDiffId != control.diffId() {
            control.updateView(view, renderer: self)
            control.appKitView?.controlDiffId = control.diffId()
        }
        return view
    }

    private func setupWindow() {
        if window == nil {
            window = NSWindow(
                contentRect: NSRect(origin: .zero, size: initialWindowSize),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window?.title = Process().arguments?[0] ?? ""
            window?.delegate = self
        }
    }
}

extension AppKitRenderer: NSWindowDelegate {
    public func windowDidResize(_ notification: Notification) {
        handleWindowSizeChange()
    }

    public func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async {
            self.application?.stop()
        }
    }
}
