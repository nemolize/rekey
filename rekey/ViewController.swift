//
//  ViewController.swift
//
//  Created by mnemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.

import Cocoa
import Foundation
import RxCocoa
import RxSwift

struct RekeyPath {
    static let configDirectoryRelativeToHome = ".config/rekey/"
    static let configFileName = "config.json"
}

class ViewController: NSViewController, NSTextViewDelegate {
    @IBOutlet var upButton: NSButton!
    @IBOutlet var downButton: NSButton!
    @IBOutlet var leftButton: NSButton!
    @IBOutlet var rightButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadConfig()
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
            .subscribe { _ in
                self.updateLabels()
                self.saveConfig()
            }
            .disposed(by: disposeBag)
    }

    private func subscribeButtons() {
        Observable.merge(
            upButton.rx.tap.map { Direction.up },
            downButton.rx.tap.map { Direction.down },
            leftButton.rx.tap.map { Direction.left },
            rightButton.rx.tap.map { Direction.right }
        ).subscribe(onNext: { direction in
            self.captureKey {
                WindowMoveHotKeyService.shared.setHotKey(direction: direction, keyCode: $0, modifiers: $1)
            }
        }).disposed(by: disposeBag)
    }

    private func updateLabels() {
        let getHotKeyLabel = WindowMoveHotKeyService.shared.getHotKeyLabel
        upButton.title = getHotKeyLabel(.up)
        downButton.title = getHotKeyLabel(.down)
        leftButton.title = getHotKeyLabel(.left)
        rightButton.title = getHotKeyLabel(.right)
    }

    private func loadConfig() {
        if !FileManager.default.fileExists(atPath: configFilePath.path) {
            debugPrint("config file does not exist at \(configFilePath)")
            return
        }
        do {
            let data = try Data(contentsOf: configFilePath, options: .mappedIfSafe)
            debugPrint("read from \(configFilePath.path)")
            guard let json = try JSONSerialization.jsonObject(
                with: data, options: .mutableLeaves
            ) as? [String: Any] else {
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
                "right": WindowMoveHotKeyService.shared.getHotKey(.right)?.keyCombo.dictionary,
            ],
        ]

        do {
            try FileManager.default.createDirectory(atPath: configDirectory.path, withIntermediateDirectories: true)
            let configFilePath = configDirectory.appendingPathComponent(RekeyPath.configFileName)
            let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: configFilePath)
            debugPrint("wrote to \(configFilePath.path)")
        } catch {
            debugPrint(error)
        }
    }

    private var configDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
            RekeyPath.configDirectoryRelativeToHome, isDirectory: true
        )
    }

    private var configFilePath: URL {
        configDirectory.appendingPathComponent(RekeyPath.configFileName)
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
        handlerObject = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
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
