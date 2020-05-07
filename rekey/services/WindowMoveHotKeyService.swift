import Foundation
import Cocoa
import HotKey

struct DirectionHotKey {
    var up: HotKey? = nil
    var down: HotKey? = nil
    var left: HotKey? = nil
    var right: HotKey? = nil
}

struct PressedDirection {
    var up = false
    var down = false
    var left = false
    var right = false
}

enum Dir {
    case up
    case down
    case left
    case right
}

class WindowMoveHotKeyService {
    private var hotKey = DirectionHotKey()
    private var direction = PressedDirection()

    static let shared = WindowMoveHotKeyService()

    private func updateDirection(_ targetDirection: Dir, _ value: Bool) {
        switch targetDirection {
        case .up: direction.up = value
        case .down: direction.down = value
        case .left: direction.left = value
        case .right: direction.right = value
        }
        setForce()
    }

    private func setForce() {
        let acceleration: CGFloat = 2.75
        let x: CGFloat = (direction.left ? -acceleration : 0.0) + (direction.right ? acceleration : 0.0)
        let y: CGFloat = (direction.up ? -acceleration : 0.0) + (direction.down ? acceleration : 0.0)
        AppService.shared.windowMovePhysics.setAcceleration(x, y)
    }

    func setHotKey(direction: Dir, keyCode: UInt32, modifiers: NSEvent.ModifierFlags) {
        let newHotKey = HotKey(
            carbonKeyCode: keyCode,
            carbonModifiers: modifiers.carbonFlags,
            keyDownHandler: { self.updateDirection(direction, true) },
            keyUpHandler: { self.updateDirection(direction, false) }
        )

        switch direction {
        case .up: hotKey.up = newHotKey
        case .down: hotKey.down = newHotKey
        case .left: hotKey.left = newHotKey
        case .right: hotKey.right = newHotKey
        }
    }
}
