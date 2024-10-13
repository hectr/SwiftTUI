import Foundation
#if os(macOS)
import AppKit
#endif

public class Application {
    private let node: Node
    
    public let window: Window
    public let control: Control
    
    public let renderer: Renderer
    private let inputHandler: InputHandler

    private let runLoopType: RunLoopType

    private var invalidatedNodes: [Node] = []
    private var updateScheduled = false

    public init<I: View>(
        rootView: I,
        renderer: Renderer = TerminalRenderer(),
        inputHandler: InputHandler = TerminalInputHandler(),
        runLoopType: RunLoopType = .dispatch
    ) {
        self.runLoopType = runLoopType

        node = Node(view: VStack(content: rootView).view)
        node.build()

        control = node.control!

        window = Window()
        window.addControl(control)
        window.firstResponder = control.firstSelectableElement
        window.firstResponder?.becomeFirstResponder()

        self.renderer = renderer
        self.inputHandler = inputHandler
        self.inputHandler.application = self

        node.application = self
        self.renderer.application = self
    }

    public enum RunLoopType {
        /// The default option, using Dispatch for the main run loop.
        case dispatch

        #if os(macOS)
        /// This creates and runs an NSApplication with an associated run loop. This allows you
        /// e.g. to open NSWindows running simultaneously to the terminal app. This requires macOS
        /// and AppKit.
        case cocoa
        #endif
    }

    public func start() {
        renderer.start(with: window.layer)
        inputHandler.start()
        control.layout(size: window.layer.frame.size)

        switch runLoopType {
        case .dispatch:
            dispatchMain()
        #if os(macOS)
        case .cocoa:
            NSApplication.shared.setActivationPolicy(.accessory)
            NSApplication.shared.run()
        #endif
        }
    }

    func invalidateNode(_ node: Node) {
        invalidatedNodes.append(node)
        scheduleUpdate()
    }

    func scheduleUpdate() {
        if !updateScheduled {
            DispatchQueue.main.async { self.update() }
            updateScheduled = true
        }
    }

    private func update() {
        updateScheduled = false

        for node in invalidatedNodes {
            node.update(using: node.view)
        }
        invalidatedNodes = []

        control.layout(size: window.layer.frame.size)
        renderer.update()
    }

    public func handleWindowSizeChange() {
        renderer.handleWindowSizeChange()
    }

    public func stop() {
        renderer.stop()
        inputHandler.stop()
        exit(0)
    }
}
