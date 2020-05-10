import Cocoa
import RxSwift

class AppService {
    // TODO: load from config
    let windowMovePhysics = PointPhysics(friction: 2) {
        WindowService.shared.moveWindow($1)
    }

    private let disposeBag = DisposeBag()

    init() {
        windowMovePhysics.start()

        WindowMoveHotKeyService.shared.onChangePressedState.subscribe(onNext: { state in
            let acceleration: CGFloat = 2.75
            let x: CGFloat = (state.left ? -acceleration : 0.0) + (state.right ? acceleration : 0.0)
            let y: CGFloat = (state.up ? -acceleration : 0.0) + (state.down ? acceleration : 0.0)
            AppService.shared.windowMovePhysics.setAcceleration(x, y)
        }).disposed(by: disposeBag)
    }

    func hasAccessibilityPermission() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeRetainedValue()
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    static let shared = AppService()
}