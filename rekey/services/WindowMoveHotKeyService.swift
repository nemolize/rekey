import Foundation
import Cocoa
import HotKey
import RxSwift
import RxRelay

struct DirectionHotKey {
    var up: HotKey?
    var down: HotKey?
    var left: HotKey?
    var right: HotKey?
}

struct PressedState {
    var up = false
    var down = false
    var left = false
    var right = false
}

enum Direction {
    case up
    case down
    case left
    case right
}

class WindowMoveHotKeyService {
    private var hotKey = DirectionHotKey()
    private var pressedState = PressedState()

    static let shared = WindowMoveHotKeyService()

    let onChangePressedState = PublishRelay<PressedState>()
    private let onChangeHotKeySubject = PublishRelay<DirectionHotKey>()
    var onChangeHotKey: Observable<DirectionHotKey> {
        self.onChangeHotKeySubject.asObservable()
    }

    private func updateDirection(_ targetDirection: Direction, _ value: Bool) {
        switch targetDirection {
        case .up: pressedState.up = value
        case .down: pressedState.down = value
        case .left: pressedState.left = value
        case .right: pressedState.right = value
        }
        onChangePressedState.accept(pressedState)
    }

    func setHotKey(direction: Direction, keyCode: UInt32, modifiers: NSEvent.ModifierFlags) {
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
        onChangeHotKeySubject.accept(hotKey)
    }

    func setHotKey(direction: Direction, dictionary: [String: Any]) {
        guard let keyCombo = KeyCombo(dictionary: dictionary) else {
            debugPrint("failed to instantiate keyCombo for \(dictionary)")
            return
        }
        let newHotKey = HotKey(
            keyCombo: keyCombo,
            keyDownHandler: { self.updateDirection(direction, true) },
            keyUpHandler: { self.updateDirection(direction, false) }
        )

        switch direction {
        case .up: hotKey.up = newHotKey
        case .down: hotKey.down = newHotKey
        case .left: hotKey.left = newHotKey
        case .right: hotKey.right = newHotKey
        }
        onChangeHotKeySubject.accept(hotKey)
    }

    func getHotKey(_ direction: Direction) -> HotKey? {
        switch direction {
        case .up: return hotKey.up
        case .down: return hotKey.down
        case .left: return hotKey.left
        case .right: return hotKey.right
        }
    }

    func getHotKeyLabel(_ direction: Direction) -> String {
        getHotKey(direction)?.keyCombo.description ?? "Not set"
    }
}
