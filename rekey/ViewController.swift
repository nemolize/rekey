import Carbon
import Cocoa
import Foundation
import RxCocoa
import RxSwift

class ViewController: NSViewController, NSTextViewDelegate {
    @IBOutlet var upButton: NSButton!
    @IBOutlet var downButton: NSButton!
    @IBOutlet var leftButton: NSButton!
    @IBOutlet var rightButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeHotKeys()
        subscribeButtons()
        updateLabels()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        setBackgroundProcessMode(false)
    }

    private let disposeBag = DisposeBag()

    private func subscribeHotKeys() {
        WindowMoveHotKeyService.shared.onChangeHotKey
            .subscribe { _ in self.updateLabels() }
            .disposed(by: disposeBag)
    }

    private func subscribeButtons() {
        Observable.merge(
            upButton.rx.tap.map { Direction.up },
            downButton.rx.tap.map { Direction.down },
            leftButton.rx.tap.map { Direction.left },
            rightButton.rx.tap.map { Direction.right }
        ).subscribe(onNext: { direction in
            let button = self.getButton(direction)
            let hotKey = WindowMoveHotKeyService.shared.getHotKey(direction)
            hotKey?.isPaused = true

            self.captureKey({
                WindowMoveHotKeyService.shared.setHotKey(direction: direction, keyCode: $0, modifiers: $1)
            }, {
                hotKey?.isPaused = false
                button.title = hotKey?.keyCombo.description ?? "Not set"
            })

            button.attributedTitle = NSAttributedString(
                string: "Press key to bind",
                attributes: [
                    NSAttributedString.Key.foregroundColor: NSColor.systemRed,
                    NSAttributedString.Key.strokeWidth: 10,
                ]
            )
        }).disposed(by: disposeBag)
    }

    private func updateLabels() {
        let getHotKeyLabel = WindowMoveHotKeyService.shared.getHotKeyLabel
        upButton.title = getHotKeyLabel(.up)
        downButton.title = getHotKeyLabel(.down)
        leftButton.title = getHotKeyLabel(.left)
        rightButton.title = getHotKeyLabel(.right)
    }

    private func getButton(_ direction: Direction) -> NSButton {
        switch direction {
        case .up: return upButton
        case .down: return downButton
        case .left: return leftButton
        case .right: return rightButton
        }
    }

    private var handlerObject: Any?
    private var onCancelHandler: (() -> Void)?

    private func captureKey(
        _ onCapture: @escaping (_ keyCode: UInt32, _ modifiers: NSEvent.ModifierFlags) -> Void,
        _ onCancel: @escaping () -> Void
    ) {
        if handlerObject != nil {
            removeCapture()
            onCancelHandler?()
        }

        onCancelHandler = { onCancel() }
        handlerObject = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            self.removeCapture()
            if $0.keyCode == kVK_Escape {
                self.onCancelHandler?()
            } else {
                onCapture(UInt32($0.keyCode), $0.modifierFlags)
            }
            return $0
        }
    }

    private func removeCapture() {
        if let handlerObject = self.handlerObject {
            NSEvent.removeMonitor(handlerObject)
            self.handlerObject = nil
        }
    }
}
