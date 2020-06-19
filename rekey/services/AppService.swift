import Cocoa
import RxSwift

class AppService {
    let windowMovePhysics = PointPhysics(friction: 10000) {
        WindowService.shared.moveWindow($1)
    }

    private let ACCELERATION: CGFloat = 15000

    private let disposeBag = DisposeBag()

    init() {
        windowMovePhysics.start()

        WindowMoveHotKeyService.shared.onChangePressedState.subscribe(onNext: { state in
            let acceleration = CGPoint(
                x: (state.left ? -self.ACCELERATION : 0.0) + (state.right ? self.ACCELERATION : 0.0),
                y: (state.up ? -self.ACCELERATION : 0.0) + (state.down ? self.ACCELERATION : 0.0)
            )
            AppService.shared.windowMovePhysics.setAcceleration(acceleration)
        }).disposed(by: disposeBag)
    }

    func hasAccessibilityPermission() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeRetainedValue()
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    static let shared = AppService()
}
