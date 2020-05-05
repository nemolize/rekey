import Cocoa

class AppService {
    // TODO: load from config
    let windowMovePhysics = PointPhysics(friction: 2) {
        WindowService.shared.moveWindow($1)
    }

    init() {
        windowMovePhysics.start()
    }

    func hasAccessibilityPermission() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeRetainedValue()
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    static let shared = AppService()
}