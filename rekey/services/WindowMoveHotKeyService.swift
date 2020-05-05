import Foundation
import Cocoa
import HotKey

struct DirectionHotKey {
    var up: HotKey? = nil
    var down: HotKey? = nil
    var left: HotKey? = nil
    var right: HotKey? = nil
}

struct Direction {
    var up = false
    var down = false
    var left = false
    var right = false
}

class WindowMoveHotKeyService {
    private var hotKey = DirectionHotKey()
    private var direction = Direction()

    static let shared = WindowMoveHotKeyService()

    private func updateDirection(up: Bool? = nil, down: Bool? = nil, left: Bool? = nil, right: Bool? = nil) {
        direction.up = up ?? direction.up
        direction.down = down ?? direction.down
        direction.left = left ?? direction.left
        direction.right = right ?? direction.right
        setForce()
    }

    private func setForce() {
        let acceleration: CGFloat = 2.75
        let x: CGFloat = (direction.left ? -acceleration : 0.0) + (direction.right ? acceleration : 0.0)
        let y: CGFloat = (direction.up ? -acceleration : 0.0) + (direction.down ? acceleration : 0.0)
        AppService.shared.windowMovePhysics.setAcceleration(x, y)
    }

    func setUp(keyCode: UInt32, modifiers: NSEvent.ModifierFlags) {
        guard let key = Key(carbonKeyCode: keyCode) else {
            debugPrint("failed to instantiate Key for keyCode: \(keyCode)")
            return
        }
        hotKey.up = HotKey(key: key, modifiers: modifiers).setHandler({
            self.direction.up = $0
            self.setForce()
        })
    }

    func setDown(keyCode: UInt32, modifiers: NSEvent.ModifierFlags) {
        guard let key = Key(carbonKeyCode: keyCode) else {
            debugPrint("failed to instantiate Key for keyCode: \(keyCode)")
            return
        }
        hotKey.down = HotKey(key: key, modifiers: modifiers).setHandler({
            self.direction.down = $0
            self.setForce()
        })
    }

    func setLeft(keyCode: UInt32, modifiers: NSEvent.ModifierFlags) {
        guard let key = Key(carbonKeyCode: keyCode) else {
            debugPrint("failed to instantiate Key for keyCode: \(keyCode)")
            return
        }
        hotKey.left = HotKey(key: key, modifiers: modifiers).setHandler({
            self.direction.left = $0
            self.setForce()
        })
    }

    func setRight(keyCode: UInt32, modifiers: NSEvent.ModifierFlags) {
        guard let key = Key(carbonKeyCode: keyCode) else {
            debugPrint("failed to instantiate Key for keyCode: \(keyCode)")
            return
        }
        hotKey.right = HotKey(key: key, modifiers: modifiers).setHandler({
            self.direction.right = $0
            self.setForce()
        })
    }
}
