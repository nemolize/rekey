import Cocoa
import RxSwift

class AppService {
    private let FORCE: CGFloat = 20000
    private let FRICTION: CGFloat = 1600
    private let FRAMERATE: Double = 144
    private let windowMovePhysics: PointPhysics
    private let disposeBag = DisposeBag()

    init() {
        // NOTE: Stores after decimal point part of velocity to prevent precision error.
        var decimalPartOfPreviousVelocity = CGPoint()
        // TODO: load from config
        windowMovePhysics = PointPhysics(friction: FRICTION, frameRate: FRAMERATE) {
            // NOTE: Adds decimal part of previous velocity for precision complement.
            let precisionComplementedVelocity = $0 + decimalPartOfPreviousVelocity
            DispatchQueue.main.sync {
                // NOTE: Only integer part is applied to window position.
                WindowService.shared.moveWindow(precisionComplementedVelocity)
            }
            // NOTE: Save only decimal part of final velocity to use in the next update unless velocity is not zero
            decimalPartOfPreviousVelocity = CGPoint(
                // TODO: detect stopping correctly not only with velocity but with acceleration as well
                x: $0.x == 0 ? 0 : precisionComplementedVelocity.x.truncatingRemainder(dividingBy: 1),
                y: $0.y == 0 ? 0 : precisionComplementedVelocity.y.truncatingRemainder(dividingBy: 1)
            )
        }

        WindowMoveHotKeyService.shared.onChangePressedState.subscribe(onNext: { state in
            let force = CGPoint(
                x: (state.left ? -self.FORCE : 0.0) + (state.right ? self.FORCE : 0.0),
                y: (state.up ? -self.FORCE : 0.0) + (state.down ? self.FORCE : 0.0)
            )
            AppService.shared.windowMovePhysics.setForce(force)
        }).disposed(by: disposeBag)
    }

    func hasAccessibilityPermission() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeRetainedValue()
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    static let shared = AppService()
}
