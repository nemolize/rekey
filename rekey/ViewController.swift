//
//  ViewController.swift
//
//  Created by mnemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.

import Cocoa
import Foundation
import RxCocoa
import RxSwift

let configPathRelativeToHome = ".config/rekey/config.json"

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
        loadConfig()
        updateLabels()
    }

    private func subscribeHotKeys() {
        WindowMoveHotKeyService.shared.onChangeHotKey
            .subscribe({ _ in
                self.updateLabels()
                self.saveConfig()
            })
            .disposed(by: disposeBag)
    }

    private func subscribeButtons() {
        Observable.merge(
            upButton.rx.tap.map({ Direction.up }),
            downButton.rx.tap.map({ Direction.down }),
            leftButton.rx.tap.map({ Direction.left }),
            rightButton.rx.tap.map({ Direction.right })
        ).subscribe(onNext: { direction in
            self.captureKey({
                WindowMoveHotKeyService.shared.setHotKey(direction: direction, keyCode: $0, modifiers: $1)
            })
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

    private func loadConfig() {
        do {
            let data = try Data(contentsOf: configPath, options: .mappedIfSafe)
            guard let json = try JSONSerialization.jsonObject(
                with: data, options: .mutableLeaves) as? [String: Any] else {
                debugPrint("content of config is empty")
                return
            }
            if let windowMove = json["windowMove"] as? [String: Any] {
                if let up = windowMove["up"] as? [String: Any] {
                    WindowMoveHotKeyService.shared.setHotKey(direction: .up, dictionary: up)
                }
                if let down = windowMove["down"] as? [String: Any] {
                    WindowMoveHotKeyService.shared.setHotKey(direction: .down, dictionary: down)
                }
                if let left = windowMove["left"] as? [String: Any] {
                    WindowMoveHotKeyService.shared.setHotKey(direction: .left, dictionary: left)
                }
                if let right = windowMove["right"] as? [String: Any] {
                    WindowMoveHotKeyService.shared.setHotKey(direction: .right, dictionary: right)
                }
            }

        } catch {
            debugPrint(error)
        }
    }

    private func saveConfig() {
        let dict: [String: Any?] = [
            "windowMove": [
                "up": WindowMoveHotKeyService.shared.getHotKey(.up)?.keyCombo.dictionary,
                "down": WindowMoveHotKeyService.shared.getHotKey(.down)?.keyCombo.dictionary,
                "left": WindowMoveHotKeyService.shared.getHotKey(.left)?.keyCombo.dictionary,
                "right": WindowMoveHotKeyService.shared.getHotKey(.right)?.keyCombo.dictionary
            ]
        ]

        do {
            let data = try JSONSerialization.data(
                withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]
            )
            try data.write(to: configPath)
        } catch {
            debugPrint(error)
        }
    }

    var configPath: URL {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        return homeDir.appendingPathComponent(".config/rekey/config.json", isDirectory: false)
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
