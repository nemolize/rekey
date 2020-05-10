//
//  ViewController.swift
//
//  Created by mnemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.

import Cocoa
import Foundation
import RxCocoa
import RxSwift

class ViewController: NSViewController, NSTextViewDelegate {
    @IBOutlet weak var upButton: NSButton!
    @IBOutlet weak var downButton: NSButton!
    @IBOutlet weak var leftButton: NSButton!
    @IBOutlet weak var rightButton: NSButton!

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeHotKeys()
        subscribeButtons()
        updateLabels()
    }

    private func subscribeHotKeys() {
        WindowMoveHotKeyService.shared.onChangeHotKey
            .subscribe({ _ in self.updateLabels() })
            .disposed(by: disposeBag)
    }

    private func subscribeButtons() {
        upButton.rx.tap.subscribe({ _ in
            self.captureKey({ WindowMoveHotKeyService.shared.setHotKey(direction: .up, keyCode: $0, modifiers: $1) })
        }).disposed(by: disposeBag)

        downButton.rx.tap.subscribe({ _ in
            self.captureKey({ WindowMoveHotKeyService.shared.setHotKey(direction: .down, keyCode: $0, modifiers: $1) })
        }).disposed(by: disposeBag)

        leftButton.rx.tap.subscribe({ _ in
            self.captureKey({ WindowMoveHotKeyService.shared.setHotKey(direction: .left, keyCode: $0, modifiers: $1) })
        }).disposed(by: disposeBag)

        rightButton.rx.tap.subscribe({ _ in
            self.captureKey({ WindowMoveHotKeyService.shared.setHotKey(direction: .right, keyCode: $0, modifiers: $1) })
        }).disposed(by: disposeBag)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
    }

    private func updateLabels() {
        let getHotKeyLabel = WindowMoveHotKeyService.shared.getHotKeyLabel
        self.upButton.title = getHotKeyLabel(.up)
        self.downButton.title = getHotKeyLabel(.down)
        self.leftButton.title = getHotKeyLabel(.left)
        self.rightButton.title = getHotKeyLabel(.right)
    }


    private var handlerObject: Any? = nil

    private func captureKey(_ block: @escaping (_ keyCode: UInt32, _ modifiers: NSEvent.ModifierFlags) -> Void) {
        self.handlerObject = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            self.removeCapture()
            block(UInt32($0.keyCode), $0.modifierFlags)
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
