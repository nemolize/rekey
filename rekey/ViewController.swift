//
//  ViewController.swift
//
//  Created by mnemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.

import Cocoa
import Foundation

class ViewController: NSViewController, NSTextViewDelegate {
    @IBOutlet weak var upSetButton: NSButton!
    @IBOutlet weak var downSetButton: NSButton!
    @IBOutlet weak var leftSetButton: NSButton!
    @IBOutlet weak var rightSetButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        NSRunningApplication().activate(options: .activateIgnoringOtherApps)
    }

    @IBAction func setUp(_ sender: Any) {
        captureKey({ WindowMoveHotKeyService.shared.setHotKey(direction: .up, keyCode: $0, modifiers: $1) })
    }

    @IBAction func setDown(_ sender: Any) {
        captureKey({ WindowMoveHotKeyService.shared.setHotKey(direction: .down, keyCode: $0, modifiers: $1) })
    }

    @IBAction func setLeft(_ sender: Any) {
        captureKey({ WindowMoveHotKeyService.shared.setHotKey(direction: .left, keyCode: $0, modifiers: $1) })
    }

    @IBAction func setRight(_ sender: Any) {
        captureKey({ WindowMoveHotKeyService.shared.setHotKey(direction: .right, keyCode: $0, modifiers: $1) })
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
