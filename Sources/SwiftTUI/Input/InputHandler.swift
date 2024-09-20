import Foundation

public protocol InputHandler: AnyObject {
    var application: Application? { get set }
    func start()
    func stop()
}
