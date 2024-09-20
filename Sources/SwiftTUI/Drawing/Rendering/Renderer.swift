import Foundation

public protocol Renderer: AnyObject {
    var application: Application? { get set }

    func start(with layer: Layer)
    func update()
    func stop()
    func handleWindowSizeChange()
}
